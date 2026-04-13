<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

$pagesCount = (int)$pdo->query("SELECT COUNT(*) FROM pages WHERE audience IN ('applicant','common')")->fetchColumn();
$specialtiesCount = (int)$pdo->query('SELECT COUNT(*) FROM specialties')->fetchColumn();
$partnersCount = (int)$pdo->query('SELECT COUNT(*) FROM partners')->fetchColumn();

$title = 'Раздел: Абитуриентам';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
?>

<div class="card">
  <h2 style="margin-top:0;">Управление разделом «Абитуриентам»</h2>
  <p class="muted">Здесь собраны все блоки, которые видят незарегистрированные пользователи и абитуриенты.</p>
  <ul>
    <li>Страниц для абитуриентов: <strong><?= $pagesCount ?></strong> (<a href="/admin/pages.php">редактировать</a>)</li>
    <li>Специальностей: <strong><?= $specialtiesCount ?></strong> (<a href="/admin/specialties.php">редактировать</a>)</li>
    <li>Партнеров: <strong><?= $partnersCount ?></strong> (<a href="/admin/partners.php">редактировать</a>)</li>
  </ul>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
