<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

$title = 'Контент';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
?>

<div class="card">
  <h2>Контент сайта и приложения</h2>
  <p class="muted">Выберите раздел для редактирования материалов.</p>
  <div class="tabs">
    <a class="tab isActive" href="/admin/content.php">Обзор</a>
    <a class="tab" href="/admin/news.php">Новости</a>
    <a class="tab" href="/admin/stories.php">Истории / мероприятия</a>
    <a class="tab" href="/admin/specialties.php">Специальности</a>
    <a class="tab" href="/admin/pages.php">Страницы (CMS)</a>
    <a class="tab" href="/admin/contacts.php">Контакты (строки)</a>
  </div>
</div>

<div class="grid2">
  <div class="card">
    <h2>Новости</h2>
    <p class="muted">Публикация, снятие с публикации, закрепление.</p>
    <a class="btn btnAccent" href="/admin/news.php">Открыть</a>
  </div>
  <div class="card">
    <h2>Специальности</h2>
    <p class="muted">Список, порядок показа, изображения.</p>
    <a class="btn btnAccent" href="/admin/specialties.php">Открыть</a>
  </div>
  <div class="card">
    <h2>Страницы</h2>
    <p class="muted">О колледже, поступление и др. (slug + текст).</p>
    <a class="btn btnAccent" href="/admin/pages.php">Открыть</a>
  </div>
  <div class="card">
    <h2>Истории</h2>
    <p class="muted">Лента событий для абитуриентов.</p>
    <a class="btn btnAccent" href="/admin/stories.php">Открыть</a>
  </div>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
