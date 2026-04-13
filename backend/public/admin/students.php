<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

if ($_SERVER['REQUEST_METHOD'] === 'POST' && hasRole('admin')) {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');
    if ($action === 'create_student') {
        $fullName = trim((string)($_POST['full_name'] ?? ''));
        $email = mb_strtolower(trim((string)($_POST['email'] ?? '')));
        $password = (string)($_POST['password'] ?? '');
        $phone = trim((string)($_POST['phone'] ?? ''));
        if ($fullName === '' || $email === '' || $password === '') {
            flash('Заполните ФИО, email и пароль.');
            redirectTo('/admin/students.php');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            flash('Некорректный email.');
            redirectTo('/admin/students.php');
        }
        $exists = $pdo->prepare('SELECT id FROM users WHERE email = :e LIMIT 1');
        $exists->execute(['e' => $email]);
        if ($exists->fetch()) {
            flash('Пользователь с таким email уже существует.');
            redirectTo('/admin/students.php');
        }
        if ($phone !== '') {
            $ph = $pdo->prepare('SELECT id FROM users WHERE phone = :p LIMIT 1');
            $ph->execute(['p' => $phone]);
            if ($ph->fetch()) {
                $phone = '';
            }
        }
        $hash = password_hash($password, PASSWORD_BCRYPT);
        $pdo->prepare(
            'INSERT INTO users(full_name, email, phone, password_hash, is_active) VALUES (:fn, :em, :ph, :pw, 1)'
        )->execute([
            'fn' => $fullName,
            'em' => $email,
            'ph' => $phone !== '' ? $phone : null,
            'pw' => $hash,
        ]);
        $uid = (int)$pdo->lastInsertId();
        $rid = adminGetRoleIdByCode($pdo, 'student');
        $pdo->prepare('INSERT INTO user_roles(user_id, role_id) VALUES (:u, :r)')->execute(['u' => $uid, 'r' => $rid]);
        $code = 'ZK-' . strtoupper(bin2hex(random_bytes(4)));
        $pdo->prepare('INSERT INTO student_profiles(user_id, student_code, portfolio_public) VALUES (:u, :c, 1)')
            ->execute(['u' => $uid, 'c' => $code]);
        auditLog($pdo, 'create', 'student_user', (string)$uid, ['email' => $email]);
        flash('Студент создан.');
        redirectTo('/admin/student_view.php?id=' . $uid);
    }

    if ($action === 'toggle_active' && hasRole('admin')) {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('UPDATE users SET is_active = 1 - is_active WHERE id = :id')->execute(['id' => $id]);
            auditLog($pdo, 'toggle_active', 'user', (string)$id, null);
            flash('Статус активности изменён.');
        }
        redirectTo('/admin/students.php');
    }

    if ($action === 'delete' && hasRole('admin')) {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('DELETE FROM users WHERE id = :id')->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'user', (string)$id, null);
            flash('Пользователь удалён.');
        }
        redirectTo('/admin/students.php');
    }
}

$q = trim((string)($_GET['q'] ?? ''));
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = 25;
$offset = ($page - 1) * $perPage;

$where = ['r.code = "student"'];
$params = [];
if ($q !== '') {
    $where[] = '(u.full_name LIKE :q OR u.email LIKE :q OR u.phone LIKE :q OR sp.student_code LIKE :q)';
    $params['q'] = '%' . $q . '%';
}
$whereSql = implode(' AND ', $where);

$cnt = $pdo->prepare(
    "SELECT COUNT(DISTINCT u.id) FROM users u
     JOIN user_roles ur ON ur.user_id = u.id
     JOIN roles r ON r.id = ur.role_id
     LEFT JOIN student_profiles sp ON sp.user_id = u.id
     WHERE $whereSql"
);
$cnt->execute($params);
$total = (int)$cnt->fetchColumn();
$pages = max(1, (int)ceil($total / $perPage));

$sql = "SELECT u.id, u.full_name, u.email, u.phone, u.created_at, u.is_active,
        sp.student_code, g.title AS group_title, s.title AS specialty_title
        FROM users u
        JOIN user_roles ur ON ur.user_id = u.id
        JOIN roles r ON r.id = ur.role_id
        LEFT JOIN student_profiles sp ON sp.user_id = u.id
        LEFT JOIN groups_ref g ON g.id = sp.group_id
        LEFT JOIN specialties s ON s.id = g.specialty_id
        WHERE $whereSql
        ORDER BY u.id DESC
        LIMIT :lim OFFSET :off";
$stmt = $pdo->prepare($sql);
foreach ($params as $k => $v) {
    $stmt->bindValue(':' . $k, $v);
}
$stmt->bindValue(':lim', $perPage, PDO::PARAM_INT);
$stmt->bindValue(':off', $offset, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$title = 'Студенты';
$user = getCurrentUser();
$showCreate = hasRole('admin') && isset($_GET['create']);
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<?php if (hasRole('admin')): ?>
<div class="card">
  <h2><?= $showCreate ? 'Новый студент' : 'Создать студента' ?></h2>
  <?php if (!$showCreate): ?>
    <a class="btn" href="/admin/students.php?create=1">Открыть форму</a>
  <?php else: ?>
    <form method="post">
      <?= csrfField() ?>
      <input type="hidden" name="action" value="create_student">
      <label>ФИО</label>
      <input name="full_name" required>
      <label>Email (логин)</label>
      <input name="email" type="email" required>
      <label>Пароль</label>
      <input name="password" type="password" required minlength="6">
      <label>Телефон</label>
      <input name="phone" type="tel">
      <button type="submit">Создать</button>
    </form>
  <?php endif; ?>
</div>
<?php endif; ?>

<div class="card">
  <h2>Список студентов</h2>
  <form method="get" class="filters" style="margin-bottom:12px;">
    <div class="field" style="min-width:260px;">
      <label>Поиск (ФИО, зачётка, телефон, email)</label>
      <input type="search" name="q" value="<?= h($q) ?>" placeholder="Начните вводить...">
    </div>
    <div class="field">
      <label>&nbsp;</label>
      <button type="submit">Найти</button>
    </div>
    <?php if ($q !== ''): ?>
      <div class="field">
        <label>&nbsp;</label>
        <a class="btn btnGhost" href="/admin/students.php">Сбросить</a>
      </div>
    <?php endif; ?>
    <?php if (hasRole('admin')): ?>
      <div class="field">
        <label>&nbsp;</label>
        <a class="btn btnAccent" href="/admin/students_export.php?<?= h(http_build_query(['q' => $q])) ?>">Экспорт CSV</a>
      </div>
    <?php endif; ?>
  </form>
  <p class="muted">Найдено: <?= $total ?>. Страница <?= $page ?> из <?= $pages ?>.</p>
  <div class="tableWrap">
    <table>
      <thead>
      <tr>
        <th>ФИО</th>
        <th>Зачётка</th>
        <th>Группа</th>
        <th>Специальность</th>
        <th>Email</th>
        <th>Телефон</th>
        <th>Регистрация</th>
        <th>Статус</th>
        <th>Действия</th>
      </tr>
      </thead>
      <tbody>
      <?php foreach ($rows as $row): ?>
        <tr>
          <td><?= h((string)$row['full_name']) ?></td>
          <td><?= h((string)($row['student_code'] ?? '')) ?></td>
          <td><?= h((string)($row['group_title'] ?? '')) ?></td>
          <td><?= h((string)($row['specialty_title'] ?? '')) ?></td>
          <td><?= h((string)$row['email']) ?></td>
          <td><?= h((string)($row['phone'] ?? '')) ?></td>
          <td><?= h((string)$row['created_at']) ?></td>
          <td><?= (int)$row['is_active'] === 1 ? 'Активен' : 'Отключён' ?></td>
          <td>
            <a href="/admin/student_view.php?id=<?= (int)$row['id'] ?>">Профиль</a>
            <?php if (hasRole('admin')): ?>
              <form method="post" style="display:inline;">
                <?= csrfField() ?>
                <input type="hidden" name="action" value="toggle_active">
                <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
                <button type="submit" class="btn btnGhost"><?= (int)$row['is_active'] === 1 ? 'Деактивировать' : 'Включить' ?></button>
              </form>
              <form method="post" style="display:inline;" onsubmit="return confirm('Удалить пользователя полностью?');">
                <?= csrfField() ?>
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
                <button type="submit" class="danger">Удалить</button>
              </form>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</div>

<?php if ($pages > 1): ?>
  <?php
  $qs = $_GET;
  $qs['page'] = max(1, $page - 1);
  $prev = '/admin/students.php?' . http_build_query($qs);
  $qs['page'] = min($pages, $page + 1);
  $next = '/admin/students.php?' . http_build_query($qs);
  ?>
  <div class="card muted" style="display:flex;gap:12px;">
    <?php if ($page > 1): ?><a class="btn btnGhost" href="<?= h($prev) ?>">← Назад</a><?php endif; ?>
    <?php if ($page < $pages): ?><a class="btn btnGhost" href="<?= h($next) ?>">Вперёд →</a><?php endif; ?>
  </div>
<?php endif; ?>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
