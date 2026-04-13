<?php
require __DIR__ . '/_bootstrap.php';

if (getCurrentUser()) {
    redirectTo('/admin/index.php');
}

$error = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $rateKey = 'admin-login:' . ($_SERVER['REMOTE_ADDR'] ?? 'unknown');
    if (isRateLimited($rateKey, 8, 300)) {
        $error = 'Слишком много попыток входа. Попробуйте позже.';
    } else {
    $email = trim((string)($_POST['email'] ?? ''));
    $password = (string)($_POST['password'] ?? '');
    if (loginByEmail($pdo, $email, $password)) {
        $u = getCurrentUser();
        if ($u) {
            adminLogLogin($pdo, (int)$u['id']);
        }
        redirectTo('/admin/index.php');
    }
    $error = 'Неверный логин/пароль или нет доступа.';
    }
}

$title = 'Вход';
$user = null;
$layoutAuth = true;
require __DIR__ . '/_layout_top.php';
?>

<div class="authCard card">
  <h2 style="margin-top: 0;">Вход в админ-панель</h2>
  <?php if ($error): ?><div class="error"><?= h($error) ?></div><?php endif; ?>
  <form method="post">
    <?= csrfField() ?>
    <label>Email</label>
    <input name="email" type="email" required placeholder="admin@aksibgu.local">
    <label>Пароль</label>
    <input name="password" type="password" required>
    <button type="submit">Войти</button>
  </form>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
