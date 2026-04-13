<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireRole('admin');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');
    if ($action === 'save_college') {
        siteSettingSet($pdo, 'college_name', trim((string)($_POST['college_name'] ?? '')));
        siteSettingSet($pdo, 'college_address', trim((string)($_POST['college_address'] ?? '')));
        siteSettingSet($pdo, 'college_phone', trim((string)($_POST['college_phone'] ?? '')));
        siteSettingSet($pdo, 'college_email', trim((string)($_POST['college_email'] ?? '')));
        flash('Настройки колледжа сохранены.');
        redirectTo('/admin/settings.php');
    }
    if ($action === 'change_password') {
        $cur = (string)($_POST['current_password'] ?? '');
        $n1 = (string)($_POST['new_password'] ?? '');
        $n2 = (string)($_POST['new_password2'] ?? '');
        if ($n1 === '' || $n1 !== $n2) {
            flash('Новый пароль и подтверждение не совпадают.');
            redirectTo('/admin/settings.php');
        }
        $u = getCurrentUser();
        $stmt = $pdo->prepare('SELECT password_hash FROM users WHERE id = :id LIMIT 1');
        $stmt->execute(['id' => (int)$u['id']]);
        $hash = (string)$stmt->fetchColumn();
        if (!password_verify($cur, $hash)) {
            flash('Текущий пароль неверный.');
            redirectTo('/admin/settings.php');
        }
        $newHash = password_hash($n1, PASSWORD_BCRYPT);
        $pdo->prepare('UPDATE users SET password_hash = :h WHERE id = :id')->execute(['h' => $newHash, 'id' => (int)$u['id']]);
        auditLog($pdo, 'password_change', 'user', (string)$u['id'], null);
        flash('Пароль изменён.');
        redirectTo('/admin/settings.php');
    }
}

$logs = [];
try {
    $logs = $pdo->query(
        'SELECT l.id, l.created_at, l.ip, u.full_name, u.email
         FROM admin_login_log l
         JOIN users u ON u.id = l.user_id
         ORDER BY l.id DESC
         LIMIT 80'
    )->fetchAll(PDO::FETCH_ASSOC);
} catch (Throwable $e) {
    $logs = [];
}

$title = 'Настройки';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2>Данные колледжа</h2>
  <p class="muted">Используются в письмах и могут подставляться в шаблоны (ключи в БД: college_name, …).</p>
  <form method="post">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save_college">
    <label>Название</label>
    <input name="college_name" value="<?= h(siteSetting($pdo, 'college_name', '') ?? '') ?>">
    <label>Адрес</label>
    <textarea name="college_address"><?= h(siteSetting($pdo, 'college_address', '') ?? '') ?></textarea>
    <label>Телефон</label>
    <input name="college_phone" value="<?= h(siteSetting($pdo, 'college_phone', '') ?? '') ?>">
    <label>Email</label>
    <input name="college_email" type="email" value="<?= h(siteSetting($pdo, 'college_email', '') ?? '') ?>">
    <button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2>Администраторы</h2>
  <p class="muted">Управление учётными записями с доступом в эту панель (роли admin / staff).</p>
  <a class="btn btnAccent" href="/admin/users.php">Управление пользователями</a>
</div>

<div class="card">
  <h2>Смена пароля</h2>
  <form method="post">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="change_password">
    <label>Текущий пароль</label>
    <input name="current_password" type="password" required autocomplete="current-password">
    <label>Новый пароль</label>
    <input name="new_password" type="password" required minlength="6" autocomplete="new-password">
    <label>Повтор нового пароля</label>
    <input name="new_password2" type="password" required minlength="6" autocomplete="new-password">
    <button type="submit">Обновить пароль</button>
  </form>
</div>

<div class="card">
  <h2>Входы в админку</h2>
  <?php if (!$logs): ?>
    <p class="muted">Нет записей или таблица <code>admin_login_log</code> не создана (см. миграцию).</p>
  <?php else: ?>
    <div class="tableWrap">
      <table>
        <thead>
        <tr><th>Когда</th><th>Пользователь</th><th>Email</th><th>IP</th></tr>
        </thead>
        <tbody>
        <?php foreach ($logs as $l): ?>
          <tr>
            <td><?= h((string)$l['created_at']) ?></td>
            <td><?= h((string)$l['full_name']) ?></td>
            <td><?= h((string)$l['email']) ?></td>
            <td><?= h((string)($l['ip'] ?? '')) ?></td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>
  <p class="muted" style="margin-top:12px;">Полный журнал действий: <a href="/admin/audit.php">Аудит</a> · <a href="/admin/backup.php">Бэкап БД</a></p>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
