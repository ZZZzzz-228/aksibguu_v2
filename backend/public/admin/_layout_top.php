<?php
/** @var string $title */
/** @var array|null $user */
$layoutAuth = !empty($layoutAuth);
$currentPath = (string)(parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '');
$isAdmin = function_exists('hasRole') && hasRole('admin');
$isContent = function_exists('canManageContent') && canManageContent();
$newApps = 0;
if (!$layoutAuth && function_exists('adminCountNewApplications') && isset($pdo)) {
    $newApps = adminCountNewApplications($pdo);
}

function navActive(string $currentPath, string $href): bool
{
    if ($href === '/admin/index.php') {
        return $currentPath === '/admin/index.php' || $currentPath === '/admin/' || $currentPath === '/admin';
    }
    return str_starts_with($currentPath, $href);
}
?>
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title><?= h(($title ?? 'Admin') . ' — Админка АКСИБГУ') ?></title>
  <link rel="stylesheet" href="/admin/assets/admin.css">
</head>
<body<?= $layoutAuth ? ' class="layoutAuth"' : '' ?>>

<?php if ($layoutAuth): ?>
  <?php /* только контент страницы (вход) */ ?>
<?php else: ?>

<div class="appShell">
  <aside class="sidebar">
    <div class="brand">
      <div class="brandTitle">Панель управления колледжем</div>
      <div class="brandSub">Админка АКСИБГУ</div>
    </div>

    <nav>
      <a class="navLink <?= navActive($currentPath, '/admin/index.php') ? 'isActive' : '' ?>" href="/admin/index.php">
        <span class="navIcon">▣</span> Дашборд
      </a>

      <?php if ($isAdmin || $isContent): ?>
        <a class="navLink <?= navActive($currentPath, '/admin/applications.php') ? 'isActive' : '' ?>" href="/admin/applications.php">
          <span class="navIcon">✉</span> Заявки
          <?php if ($newApps > 0): ?><span class="badgeDot" title="Новые заявки"></span><?php endif; ?>
        </a>
      <?php endif; ?>

      <?php if ($isAdmin || $isContent): ?>
        <a class="navLink <?= navActive($currentPath, '/admin/students.php') ? 'isActive' : '' ?>" href="/admin/students.php">
          <span class="navIcon">👤</span> Студенты
        </a>
      <?php endif; ?>

      <?php if ($isContent): ?>
        <div class="navSection">
          <div class="navSectionTitle">Контент и данные</div>
          <a class="navLink <?= navActive($currentPath, '/admin/content.php') ? 'isActive' : '' ?>" href="/admin/content.php">
            <span class="navIcon">📰</span> Контент
          </a>
          <a class="navLink <?= navActive($currentPath, '/admin/people.php') ? 'isActive' : '' ?>" href="/admin/people.php">
            <span class="navIcon">👥</span> Люди
          </a>
          <a class="navLink <?= navActive($currentPath, '/admin/vacancies.php') ? 'isActive' : '' ?>" href="/admin/vacancies.php">
            <span class="navIcon">💼</span> Вакансии
          </a>
        </div>
      <?php endif; ?>

      <?php if ($isAdmin): ?>
        <div class="navSection">
          <div class="navSectionTitle">Система</div>
          <a class="navLink <?= navActive($currentPath, '/admin/settings.php') ? 'isActive' : '' ?>" href="/admin/settings.php">
            <span class="navIcon">⚙</span> Настройки
          </a>
        </div>
      <?php endif; ?>
    </nav>
  </aside>

  <div class="mainArea">
    <header class="topHeader">
      <h1 class="pageHeading"><?= h($title ?? 'Раздел') ?></h1>
      <div class="headerMeta">
        <?php if (!empty($user)): ?>
          <?= h($user['full_name'] ?? '') ?>
          <span class="muted"> · </span>
          <a href="/admin/logout.php">Выйти</a>
        <?php endif; ?>
      </div>
    </header>
    <div class="contentArea">

<?php endif; ?>
