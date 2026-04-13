<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireRole('admin');
$currentUser = getCurrentUser();
$currentUserId = (int)($currentUser['id'] ?? 0);
$adminRoleCodes = ['staff', 'admin', 'admissions', 'academic', 'content_manager'];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'create') {
        $fullName = trim((string)($_POST['full_name'] ?? ''));
        $email = mb_strtolower(trim((string)($_POST['email'] ?? '')));
        $phone = trim((string)($_POST['phone'] ?? ''));
        $password = (string)($_POST['password'] ?? '');
        $roleCode = (string)($_POST['role_code'] ?? 'staff');

        if ($fullName === '' || $email === '' || $password === '') {
            flash('Заполните full_name, email и password.');
            redirectTo('/admin/users.php');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            flash('Некорректный email.');
            redirectTo('/admin/users.php');
        }
        if (!in_array($roleCode, $adminRoleCodes, true)) {
            flash('Недопустимая роль.');
            redirectTo('/admin/users.php');
        }

        $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
        $stmt->execute(['email' => $email]);
        if ($stmt->fetch(PDO::FETCH_ASSOC)) {
            flash('Пользователь с таким email уже существует.');
            redirectTo('/admin/users.php');
        }

        $hash = password_hash($password, PASSWORD_BCRYPT);
        $insertUser = $pdo->prepare(
            'INSERT INTO users(full_name, email, phone, password_hash, is_active)
             VALUES (:full_name, :email, :phone, :password_hash, 1)'
        );
        $insertUser->execute([
            'full_name' => $fullName,
            'email' => $email,
            'phone' => $phone !== '' ? $phone : null,
            'password_hash' => $hash,
        ]);
        $userId = (int)$pdo->lastInsertId();

        $roleId = getRoleId($pdo, $roleCode);
        $attachRole = $pdo->prepare('INSERT INTO user_roles(user_id, role_id) VALUES (:user_id, :role_id)');
        $attachRole->execute([
            'user_id' => $userId,
            'role_id' => $roleId,
        ]);
        auditLog($pdo, 'create', 'user', (string)$userId, [
            'email' => $email,
            'role' => $roleCode,
        ]);

        flash('Пользователь создан.');
        redirectTo('/admin/users.php');
    }

    if ($action === 'toggle_active') {
        $userId = (int)($_POST['user_id'] ?? 0);
        if ($userId > 0) {
            if ($userId === $currentUserId) {
                flash('Нельзя отключить самого себя.');
                redirectTo('/admin/users.php');
            }
            if (userHasRole($pdo, $userId, 'admin') && countActiveAdmins($pdo) <= 1) {
                flash('Нельзя отключить последнего активного администратора.');
                redirectTo('/admin/users.php');
            }
            $stmt = $pdo->prepare('UPDATE users SET is_active = 1 - is_active WHERE id = :id');
            $stmt->execute(['id' => $userId]);
            auditLog($pdo, 'toggle_active', 'user', (string)$userId, null);
            flash('Статус активности обновлен.');
        }
        redirectTo('/admin/users.php');
    }

    if ($action === 'set_role') {
        $userId = (int)($_POST['user_id'] ?? 0);
        $roleCode = (string)($_POST['role_code'] ?? '');
        if ($userId > 0 && in_array($roleCode, $adminRoleCodes, true)) {
            if ($userId === $currentUserId && $roleCode !== 'admin') {
                flash('Нельзя снять у себя роль admin.');
                redirectTo('/admin/users.php');
            }
            if (userHasRole($pdo, $userId, 'admin') && $roleCode !== 'admin' && countActiveAdmins($pdo) <= 1) {
                flash('Нельзя снять роль у последнего активного администратора.');
                redirectTo('/admin/users.php');
            }
            $newRoleId = getRoleId($pdo, $roleCode);
            $stmt = $pdo->prepare(
                'DELETE ur FROM user_roles ur
                 JOIN roles r ON r.id = ur.role_id
                 WHERE ur.user_id = :user_id AND r.code IN (\'staff\', \'admin\', \'admissions\', \'academic\', \'content_manager\')'
            );
            $stmt->execute(['user_id' => $userId]);

            $attach = $pdo->prepare('INSERT INTO user_roles(user_id, role_id) VALUES (:user_id, :role_id)');
            $attach->execute(['user_id' => $userId, 'role_id' => $newRoleId]);
            auditLog($pdo, 'set_role', 'user', (string)$userId, [
                'role' => $roleCode,
            ]);
            flash('Роль пользователя обновлена.');
        }
        redirectTo('/admin/users.php');
    }

    if ($action === 'reset_password') {
        $userId = (int)($_POST['user_id'] ?? 0);
        $newPassword = (string)($_POST['new_password'] ?? '');
        if ($userId > 0 && strlen($newPassword) >= 6) {
            $hash = password_hash($newPassword, PASSWORD_BCRYPT);
            $stmt = $pdo->prepare('UPDATE users SET password_hash = :hash WHERE id = :id');
            $stmt->execute(['hash' => $hash, 'id' => $userId]);
            auditLog($pdo, 'reset_password', 'user', (string)$userId, null);
            flash('Пароль обновлен.');
        } else {
            flash('Пароль должен быть не короче 6 символов.');
        }
        redirectTo('/admin/users.php');
    }

    if ($action === 'delete') {
        $userId = (int)($_POST['user_id'] ?? 0);
        if ($userId > 0) {
            if ($userId === $currentUserId) {
                flash('Нельзя удалить самого себя.');
                redirectTo('/admin/users.php');
            }
            if (userHasRole($pdo, $userId, 'admin') && countActiveAdmins($pdo) <= 1) {
                flash('Нельзя удалить последнего активного администратора.');
                redirectTo('/admin/users.php');
            }

            $stmt = $pdo->prepare('DELETE FROM users WHERE id = :id');
            $stmt->execute(['id' => $userId]);
            auditLog($pdo, 'delete', 'user', (string)$userId, null);
            flash('Пользователь удален.');
        }
        redirectTo('/admin/users.php');
    }
}

$users = $pdo->query(
    'SELECT u.id, u.full_name, u.email, u.phone, u.is_active,
            GROUP_CONCAT(r.code ORDER BY r.code SEPARATOR ", ") AS roles
     FROM users u
     LEFT JOIN user_roles ur ON ur.user_id = u.id
     LEFT JOIN roles r ON r.id = ur.role_id
     GROUP BY u.id, u.full_name, u.email, u.phone, u.is_active
     ORDER BY u.id DESC'
)->fetchAll(PDO::FETCH_ASSOC);

$title = 'Пользователи и роли';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;">Создать пользователя</h2>
  <form method="post">
    <input type="hidden" name="action" value="create">
    <label>ФИО</label>
    <input name="full_name" required>
    <label>Email</label>
    <input type="email" name="email" required>
    <label>Телефон (опционально)</label>
    <input name="phone">
    <label>Пароль</label>
    <input type="password" name="password" required>
    <label>Роль</label>
    <select name="role_code" style="width:100%;padding:10px;border:1px solid #d1d5db;border-radius:8px;margin-top:6px;margin-bottom:10px;">
      <option value="staff">staff</option>
      <option value="admin">admin</option>
      <option value="admissions">admissions</option>
      <option value="academic">academic</option>
      <option value="content_manager">content_manager</option>
    </select>
    <button type="submit">Создать</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список пользователей</h2>
  <table>
    <thead>
      <tr><th>ID</th><th>ФИО</th><th>Email</th><th>Телефон</th><th>Роли</th><th>Активность</th><th>Действия</th></tr>
    </thead>
    <tbody>
    <?php foreach ($users as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['full_name']) ?></td>
        <td><?= h((string)$row['email']) ?></td>
        <td><?= h((string)($row['phone'] ?? '')) ?></td>
        <td><?= h((string)($row['roles'] ?? '')) ?></td>
        <td><?= (int)$row['is_active'] === 1 ? 'Активен' : 'Отключен' ?></td>
        <td>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="toggle_active">
            <input type="hidden" name="user_id" value="<?= (int)$row['id'] ?>">
            <button type="submit"><?= (int)$row['is_active'] === 1 ? 'Отключить' : 'Включить' ?></button>
          </form>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="set_role">
            <input type="hidden" name="user_id" value="<?= (int)$row['id'] ?>">
            <select name="role_code" style="padding:6px;border:1px solid #d1d5db;border-radius:6px;">
              <option value="staff" <?= str_contains((string)($row['roles'] ?? ''), 'staff') ? 'selected' : '' ?>>staff</option>
              <option value="admin" <?= str_contains((string)($row['roles'] ?? ''), 'admin') ? 'selected' : '' ?>>admin</option>
              <option value="admissions" <?= str_contains((string)($row['roles'] ?? ''), 'admissions') ? 'selected' : '' ?>>admissions</option>
              <option value="academic" <?= str_contains((string)($row['roles'] ?? ''), 'academic') ? 'selected' : '' ?>>academic</option>
              <option value="content_manager" <?= str_contains((string)($row['roles'] ?? ''), 'content_manager') ? 'selected' : '' ?>>content_manager</option>
            </select>
            <button type="submit">Роль</button>
          </form>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="reset_password">
            <input type="hidden" name="user_id" value="<?= (int)$row['id'] ?>">
            <input type="password" name="new_password" placeholder="Новый пароль" style="width:130px;padding:6px;margin:0 4px;">
            <button type="submit">Сменить пароль</button>
          </form>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="user_id" value="<?= (int)$row['id'] ?>">
            <button class="danger" type="submit" onclick="return confirm('Удалить пользователя?')">Удалить</button>
          </form>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>

<?php
function getRoleId(PDO $pdo, string $roleCode): int
{
    $stmt = $pdo->prepare('SELECT id FROM roles WHERE code = :code LIMIT 1');
    $stmt->execute(['code' => $roleCode]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        throw new RuntimeException('Role not found: ' . $roleCode);
    }
    return (int)$row['id'];
}

function userHasRole(PDO $pdo, int $userId, string $roleCode): bool
{
    $stmt = $pdo->prepare(
        'SELECT 1
         FROM user_roles ur
         JOIN roles r ON r.id = ur.role_id
         WHERE ur.user_id = :user_id AND r.code = :code
         LIMIT 1'
    );
    $stmt->execute([
        'user_id' => $userId,
        'code' => $roleCode,
    ]);
    return (bool)$stmt->fetchColumn();
}

function countActiveAdmins(PDO $pdo): int
{
    $stmt = $pdo->query(
        'SELECT COUNT(*)
         FROM users u
         JOIN user_roles ur ON ur.user_id = u.id
         JOIN roles r ON r.id = ur.role_id
         WHERE u.is_active = 1 AND r.code = "admin"'
    );
    return (int)$stmt->fetchColumn();
}
