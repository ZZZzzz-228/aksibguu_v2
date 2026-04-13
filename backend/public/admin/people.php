<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

$title = 'Люди';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
?>

<div class="card">
  <h2>Сотрудники и организации</h2>
  <p class="muted">Преподаватели, администрация и партнёры.</p>
  <div class="grid2">
    <div class="card" style="box-shadow:none;border:1px dashed #cbd5e1;">
      <h2 style="font-size:16px;">Сотрудники</h2>
      <p class="muted">Карточки для страницы контактов и блоков «Преподаватели».</p>
      <a class="btn btnAccent" href="/admin/staff.php">Открыть</a>
    </div>
    <div class="card" style="box-shadow:none;border:1px dashed #cbd5e1;">
      <h2 style="font-size:16px;">Партнёры</h2>
      <p class="muted">Логотипы и ссылки компаний.</p>
      <a class="btn btnAccent" href="/admin/partners.php">Открыть</a>
    </div>
  </div>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
