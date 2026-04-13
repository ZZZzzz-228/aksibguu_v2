<?php
/** @var string $title */
/** @var array|null $user */
$layoutAuth = !empty($layoutAuth);
$currentPath = (string)(parse_url($_SERVER['REQUEST_URI'] ?? '', PHP_URL_PATH) ?? '');
$isAdmin = function_exists('hasRole') && hasRole('admin');
$isContent = function_exists('canManageContent') && canManageContent();
$isAdmissions = function_exists('canManageAdmissions') && canManageAdmissions();
$isAcademic = function_exists('canManageAcademic') && canManageAcademic();
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

      <?php if ($isAdmissions): ?>
        <a class="navLink <?= navActive($currentPath, '/admin/applications.php') ? 'isActive' : '' ?>" href="/admin/applications.php">
          <span class="navIcon">✉</span> Заявки
          <span id="ccNewAppsDot" class="badgeDot" title="Новые заявки" style="<?= $newApps > 0 ? '' : 'display:none;' ?>"></span>
        </a>
      <?php endif; ?>

      <?php if ($isAdmissions): ?>
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

      <?php if ($isAcademic): ?>
        <div class="navSection">
          <div class="navSectionTitle">Учебная часть</div>
          <a class="navLink <?= navActive($currentPath, '/admin/groups.php') ? 'isActive' : '' ?>" href="/admin/groups.php">
            <span class="navIcon">🎓</span> Группы
          </a>
          <a class="navLink <?= navActive($currentPath, '/admin/disciplines.php') ? 'isActive' : '' ?>" href="/admin/disciplines.php">
            <span class="navIcon">📚</span> Дисциплины
          </a>
          <a class="navLink <?= navActive($currentPath, '/admin/curriculum.php') ? 'isActive' : '' ?>" href="/admin/curriculum.php">
            <span class="navIcon">🗂</span> Учебные планы
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

<script>
(() => {
  const dot = document.getElementById('ccNewAppsDot');
  if (!dot) return;

  const currentPath = <?= json_encode($currentPath, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) ?>;
  const pollUrl = '/admin/poll.php';
  const intervalMs = 10000;

  function getMaxApplicationIdFromPage() {
    if (!currentPath.startsWith('/admin/applications.php')) return 0;
    const rows = Array.from(document.querySelectorAll('tr.clickRow[data-href]'));
    let maxId = 0;
    for (const tr of rows) {
      const href = tr.getAttribute('data-href') || '';
      const m = href.match(/[?&]id=(\d+)/);
      if (m) {
        const id = Number(m[1]);
        if (Number.isFinite(id) && id > maxId) maxId = id;
      }
    }
    return maxId;
  }

  async function tick() {
    try {
      const res = await fetch(pollUrl, { cache: 'no-store', credentials: 'same-origin' });
      if (!res.ok) return;
      const data = await res.json();
      const count = Number(data && data.new_applications_count || 0);
      dot.style.display = count > 0 ? '' : 'none';

      if (currentPath.startsWith('/admin/applications.php')) {
        const latestId = Number(data && data.latest_application_id || 0);
        const maxId = getMaxApplicationIdFromPage();
        if (latestId > 0 && latestId > maxId) {
          window.location.reload();
        }
      }
    } catch (e) {
      // ignore
    }
  }

  setInterval(tick, intervalMs);
})();
</script>

<?php endif; ?>
