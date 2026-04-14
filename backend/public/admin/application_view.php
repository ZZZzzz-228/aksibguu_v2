<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAdmissions()) {
    flash('Недостаточно прав для раздела заявок.');
    redirectTo('/admin/index.php');
}

try {
    $pdo->query('SELECT 1 FROM applications LIMIT 1');
} catch (Throwable $e) {
    flash('Таблица заявок не найдена. Выполните миграцию БД.');
    redirectTo('/admin/index.php');
}

function appStatusRu(string $s): string
{
    return match ($s) {
        'new' => 'Новая',
        'processing' => 'В работе',
        'approved' => 'Принята',
        'rejected' => 'Отклонена',
        'archived' => 'Архив',
        default => $s,
    };
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    flash('Не указана заявка.');
    redirectTo('/admin/applications.php');
}

$stmt = $pdo->prepare('SELECT * FROM applications WHERE id = :id LIMIT 1');
$stmt->execute(['id' => $id]);
$app = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$app) {
    flash('Заявка не найдена.');
    redirectTo('/admin/applications.php');
}

$fileStmt = $pdo->prepare('SELECT * FROM application_files WHERE application_id = :id ORDER BY id ASC');
$fileStmt->execute(['id' => $id]);
$files = $fileStmt->fetchAll(PDO::FETCH_ASSOC);

$payload = [];
if (!empty($app['payload_json'])) {
    $decoded = json_decode((string)$app['payload_json'], true);
    $payload = is_array($decoded) ? $decoded : [];
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');
    $isAdminUser = hasRole('admin');

    if ($action === 'processing') {
        if (applicationsHasColumn($pdo, 'rejection_reason')) {
            $pdo->prepare('UPDATE applications SET status = "processing", rejection_reason = NULL WHERE id = :id')->execute(['id' => $id]);
        } else {
            $pdo->prepare('UPDATE applications SET status = "processing" WHERE id = :id')->execute(['id' => $id]);
        }
        auditLog($pdo, 'set_status', 'application', (string)$id, ['status' => 'processing']);
        flash('Статус: в работе.');
        redirectTo('/admin/application_view.php?id=' . $id);
    }

    if ($action === 'reject') {
        if (!applicationsHasColumn($pdo, 'rejection_reason')) {
            flash('В таблице нет колонки rejection_reason. Выполните backend/database/migration_applications_columns_only.sql в phpMyAdmin.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        $reason = trim((string)($_POST['rejection_reason'] ?? ''));
        if ($reason === '') {
            flash('Укажите причину отклонения.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        $pdo->prepare('UPDATE applications SET status = "rejected", rejection_reason = :r WHERE id = :id')->execute(['id' => $id, 'r' => $reason]);
        auditLog($pdo, 'reject', 'application', (string)$id, ['reason' => $reason]);
        flash('Заявка отклонена.');
        redirectTo('/admin/application_view.php?id=' . $id);
    }

    if ($action === 'accept_student') {
        if (!$isAdminUser) {
            flash('Принять заявку и создать аккаунт студента может только администратор.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        if (!applicationsHasColumn($pdo, 'accepted_user_id')) {
            flash('В таблице нет колонки accepted_user_id. Выполните backend/database/migration_applications_columns_only.sql в phpMyAdmin.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        if ((string)$app['status'] === 'approved') {
            flash('Заявка уже принята.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        $email = mb_strtolower(trim((string)$app['email'] ?? ''));
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            flash('Для создания аккаунта нужен корректный email в заявке.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        $check = $pdo->prepare('SELECT id FROM users WHERE email = :e LIMIT 1');
        $check->execute(['e' => $email]);
        if ($check->fetch()) {
            flash('Пользователь с таким email уже есть. Откройте раздел «Студенты» или используйте другой сценарий.');
            redirectTo('/admin/application_view.php?id=' . $id);
        }

        $plainPass = substr(bin2hex(random_bytes(8)), 0, 12);
        $hash = password_hash($plainPass, PASSWORD_BCRYPT);
        $fullName = (string)$app['full_name'];
        $phone = trim((string)($app['phone'] ?? ''));
        if ($phone !== '') {
            $phChk = $pdo->prepare('SELECT id FROM users WHERE phone = :p LIMIT 1');
            $phChk->execute(['p' => $phone]);
            if ($phChk->fetch()) {
                $phone = '';
            }
        }

        try {
            $pdo->prepare(
                'INSERT INTO users(full_name, email, phone, password_hash, is_active) VALUES (:fn, :em, :ph, :pw, 1)'
            )->execute([
                'fn' => $fullName,
                'em' => $email,
                'ph' => $phone !== '' ? $phone : null,
                'pw' => $hash,
            ]);
        } catch (Throwable $e) {
            flash('Не удалось создать пользователя (возможно, дубликат телефона или email).');
            redirectTo('/admin/application_view.php?id=' . $id);
        }
        $newUserId = (int)$pdo->lastInsertId();

        $roleId = adminGetRoleIdByCode($pdo, 'student');
        $pdo->prepare('INSERT INTO user_roles(user_id, role_id) VALUES (:u, :r)')->execute(['u' => $newUserId, 'r' => $roleId]);

        $studentCode = 'ZK-' . strtoupper(bin2hex(random_bytes(4)));
        $pdo->prepare(
            'INSERT INTO student_profiles(user_id, student_code, portfolio_public) VALUES (:u, :sc, 1)'
        )->execute(['u' => $newUserId, 'sc' => $studentCode]);

        if (applicationsHasColumn($pdo, 'rejection_reason')) {
            $pdo->prepare(
                'UPDATE applications SET status = "approved", accepted_user_id = :uid, rejection_reason = NULL WHERE id = :id'
            )->execute(['uid' => $newUserId, 'id' => $id]);
        } else {
            $pdo->prepare(
                'UPDATE applications SET status = "approved", accepted_user_id = :uid WHERE id = :id'
            )->execute(['uid' => $newUserId, 'id' => $id]);
        }

        auditLog($pdo, 'accept_create_student', 'application', (string)$id, ['new_user_id' => $newUserId]);

        $smtp = $config['smtp'] ?? null;
        $mailOk = false;
        $mailErr = '';
        if (is_array($smtp) && !empty($smtp['host'])) {
            try {
                $subj = 'Доступ в приложение колледжа (АКСИБГУ)';

                // Загружаем HTML-шаблон
                $templatePath = __DIR__ . '/../../templates/email_template.html';
                if (!file_exists($templatePath)) {
                    throw new RuntimeException('Email template not found: ' . $templatePath);
                }
                $htmlBody = file_get_contents($templatePath);

                // Заменяем плейсхолдеры
                $htmlBody = str_replace('{FULL_NAME}', htmlspecialchars($fullName), $htmlBody);
                $htmlBody = str_replace('{EMAIL}', htmlspecialchars($email), $htmlBody);
                $htmlBody = str_replace('{PASSWORD}', htmlspecialchars($plainPass), $htmlBody);

                SmtpMailer::send($smtp, $email, $subj, $htmlBody, true);
                $mailOk = true;
            } catch (Throwable $e) {
                $mailOk = false;
                $mailErr = $e->getMessage();
                // Запасной вариант - PHP mail()
                try {
                    $headers = [
                        'MIME-Version: 1.0',
                        'Content-type: text/html; charset=UTF-8',
                        'From: ' . ($smtp['from_name'] ?? 'АКСИБГУ') . ' <' . ($smtp['from_email'] ?? 'noreply@example.com') . '>',
                        'Reply-To: ' . ($smtp['from_email'] ?? 'noreply@example.com'),
                    ];
                    $mailSent = mail($email, $subj, $htmlBody, implode("\r\n", $headers));
                    if ($mailSent) {
                        $mailOk = true;
                        $mailErr = '';
                    }
                } catch (Throwable $mailE) {
                    // Оставляем оригинальную ошибку
                }
            }
        } elseif (!is_array($smtp) || empty($smtp['host'])) {
            $mailErr = 'В config.php не задан smtp.host.';
        }

        if ($mailOk) {
            flash('Студент создан. Временный пароль отправлен на email заявителя.');
        } else {
            $hint = 'Студент создан. Сохраните пароль: ' . $plainPass . ' (письмо не отправлено).';
            if ($mailErr !== '') {
                $hint .= ' SMTP: ' . $mailErr;
            } else {
                $hint .= ' Проверьте SMTP в config.php.';
            }
            flash($hint);
        }
        redirectTo('/admin/application_view.php?id=' . $id);
    }
}

$title = 'Заявка #' . $id;
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <p><a href="/admin/applications.php" class="btn btnGhost">← К списку заявок</a></p>
  <h2>Заявка #<?= $id ?></h2>
  <p class="muted">Создана: <?= h((string)$app['created_at']) ?> · Тип: <?= $app['type'] === 'courses' ? 'Запись на курсы' : 'Подача документов' ?></p>
  <p><strong>Статус:</strong>
    <span class="<?= $app['status'] === 'new' ? 'stNew' : ($app['status'] === 'processing' ? 'stProc' : ($app['status'] === 'approved' ? 'stOk' : 'stNo')) ?>">
      <?= h(appStatusRu((string)$app['status'])) ?>
    </span>
  </p>
  <?php if (!empty($app['rejection_reason'])): ?>
    <p><strong>Причина отклонения:</strong> <?= h((string)$app['rejection_reason']) ?></p>
  <?php endif; ?>
  <?php if (!empty($app['accepted_user_id'])): ?>
    <p class="muted">Связанный аккаунт студента: user_id <?= (int)$app['accepted_user_id'] ?> — <a href="/admin/student_view.php?id=<?= (int)$app['accepted_user_id'] ?>">Профиль</a></p>
  <?php endif; ?>
</div>

<div class="card">
  <h2>Данные заявителя</h2>
  <p><strong>ФИО:</strong> <?= h((string)$app['full_name']) ?></p>
  <p><strong>Телефон:</strong> <?= h((string)($app['phone'] ?? '')) ?></p>
  <p><strong>Email:</strong> <?= h((string)($app['email'] ?? '')) ?></p>
  <p><strong>Специальность (строка):</strong> <?= h((string)($app['specialty_text'] ?? '')) ?></p>
  <p>
    <button type="button" class="btn btnGhost" id="btnCopyContacts">Связаться (копировать email и телефон)</button>
  </p>
  <textarea id="copyBuf" style="position:absolute;left:-9999px;"><?= h(trim((string)($app['email'] ?? '') . ' ' . (string)($app['phone'] ?? ''))) ?></textarea>
</div>

<?php if ($payload): ?>
<div class="card">
  <h2>Дополнительные поля (JSON)</h2>
  <pre style="white-space:pre-wrap;font-size:13px;background:#f8fafc;padding:12px;border-radius:8px;border:1px solid #e2e8f0;"><?= h(json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)) ?></pre>
</div>
<?php endif; ?>

<div class="card">
  <h2>Загруженные файлы</h2>
  <?php if (!$files): ?>
    <p class="muted">Файлов нет (или заявка подана только с перечнем имён без загрузки).</p>
  <?php else: ?>
    <div class="thumbs">
      <?php foreach ($files as $f): ?>
        <?php
          $url = (string)$f['file_url'];
          $mime = (string)($f['mime'] ?? '');
          $isImg = str_starts_with($mime, 'image/');
        ?>
        <a class="thumb" href="<?= h($url) ?>" target="_blank" rel="noopener" title="<?= h((string)$f['original_name']) ?>">
          <?php if ($isImg): ?>
            <img src="<?= h($url) ?>" alt="">
          <?php else: ?>
            <span>PDF / файл<br><?= h((string)$f['original_name']) ?></span>
          <?php endif; ?>
        </a>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
</div>

<div class="card">
  <h2>Действия</h2>
  <form method="post" style="display:inline-block;margin-right:8px;">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="processing">
    <button type="submit" class="btn btnAccent">В работу</button>
  </form>

  <?php if (hasRole('admin')): ?>
  <form method="post" style="display:inline-block;margin-right:8px;" onsubmit="return confirm('Создать аккаунт студента и принять заявку?');">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="accept_student">
    <button type="submit" class="btn" <?= (string)$app['status'] === 'approved' ? 'disabled' : '' ?>>Принять (создать студента)</button>
  </form>
  <?php endif; ?>

  <form method="post" style="margin-top:16px;">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="reject">
    <label>Причина отклонения (обязательно)</label>
    <textarea name="rejection_reason" required placeholder="Укажите причину для абитуриента"></textarea>
    <button type="submit" class="btn btnDanger" <?= (string)$app['status'] === 'approved' ? 'disabled' : '' ?>>Отклонить</button>
  </form>
</div>

<script>
document.getElementById('btnCopyContacts').addEventListener('click', function() {
  var t = document.getElementById('copyBuf');
  t.style.position = 'fixed';
  t.style.left = '0';
  t.style.top = '0';
  t.select();
  document.execCommand('copy');
  t.style.position = 'absolute';
  t.style.left = '-9999px';
  alert('Скопировано в буфер обмена');
});
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
