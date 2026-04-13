<?php
require __DIR__ . '/_bootstrap.php';
$user = requireLogin();
requireAnyRole(['admin', 'staff']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $title = trim((string)($_POST['title'] ?? ''));
        $content = trim((string)($_POST['content'] ?? ''));
        $imageUrl = trim((string)($_POST['image_url'] ?? ''));
        $croppedImageData = (string)($_POST['cropped_image_data'] ?? '');
        $savedFromCrop = null;
        if ($croppedImageData !== '') {
            $savedFromCrop = saveBase64Image($croppedImageData);
        }
        if ($savedFromCrop !== null) {
            $imageUrl = $savedFromCrop;
        }
        $uploadedImageUrl = saveUploadedImage('image_file');
        if ($savedFromCrop === null && $uploadedImageUrl !== null) {
            $imageUrl = $uploadedImageUrl;
        }
        $isPublished = isset($_POST['is_published']) ? 1 : 0;
        $isPinned = isset($_POST['is_pinned']) ? 1 : 0;

        if ($title === '' || $content === '') {
            flash('Заполните title и content.');
            redirectTo('/admin/news.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE news_items SET title=:title, content=:content, image_url=:image_url, is_published=:is_published, is_pinned=:is_pinned WHERE id=:id');
            $stmt->execute([
                'id' => $id,
                'title' => $title,
                'content' => $content,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'is_published' => $isPublished,
                'is_pinned' => $isPinned,
            ]);
            auditLog($pdo, 'update', 'news_item', (string)$id, [
                'title' => $title,
                'is_published' => $isPublished,
            ]);
            flash('Новость обновлена.');
        } else {
            $stmt = $pdo->prepare('INSERT INTO news_items(title, content, image_url, published_at, is_published, is_pinned, author_user_id) VALUES (:title, :content, :image_url, NOW(), :is_published, :is_pinned, :author_user_id)');
            $stmt->execute([
                'title' => $title,
                'content' => $content,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'is_published' => $isPublished,
                'is_pinned' => $isPinned,
                'author_user_id' => (int)$user['id'],
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'news_item', (string)$newId, [
                'title' => $title,
                'is_published' => $isPublished,
            ]);
            flash('Новость добавлена.');
        }
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/news.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM news_items WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'news_item', (string)$id, null);
            flash('Новость удалена.');
        }
    }

    if ($action === 'toggle_publish') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE news_items SET is_published = 1 - is_published WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'toggle_publish', 'news_item', (string)$id, null);
            flash('Статус новости переключен.');
        }
    }

    if ($action === 'toggle_pin') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE news_items SET is_pinned = 1 - is_pinned WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'toggle_pin', 'news_item', (string)$id, null);
            flash('Закрепление переключено.');
        }
    }
    redirectTo('/admin/news.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM news_items WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$news = $pdo->query('SELECT id, title, image_url, is_published, is_pinned, published_at FROM news_items ORDER BY is_pinned DESC, id DESC')->fetchAll(PDO::FETCH_ASSOC);

$title = 'Управление новостями';
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?>
  <div class="flash"><?= h($msg) ?></div>
<?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать новость' : 'Добавить новость' ?></h2>
  <form method="post" enctype="multipart/form-data">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Заголовок</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>
    <label>Текст</label>
    <textarea name="content" required><?= h((string)($editItem['content'] ?? '')) ?></textarea>
    <label>Image URL (опционально)</label>
    <input name="image_url" value="<?= h((string)($editItem['image_url'] ?? '')) ?>">
    <label>Или загрузить изображение</label>
    <input id="news_image_file" name="image_file" type="file" accept="image/jpeg,image/png,image/webp">
    <input id="news_cropped_image_data" name="cropped_image_data" type="hidden">
    <div class="muted">После выбора файла можно подвигать кадр. Формат: 16:9.</div>
    <div style="max-width:480px;margin-top:8px;">
      <img id="news_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
    <label><input type="checkbox" name="is_published" <?= ($editItem === null || !empty($editItem['is_published'])) ? 'checked' : '' ?>> Опубликовано</label>
    <label><input type="checkbox" name="is_pinned" <?= !empty($editItem['is_pinned']) ? 'checked' : '' ?>> Закрепить вверху списка</label>
    <?php if (!empty($editItem['image_url'])): ?>
      <div class="muted">Текущее изображение: <a href="<?= h((string)$editItem['image_url']) ?>" target="_blank"><?= h((string)$editItem['image_url']) ?></a></div>
      <img src="<?= h((string)$editItem['image_url']) ?>" alt="" style="max-width:220px;border-radius:8px;margin-top:8px;">
    <?php endif; ?>
    <br><br>
    <button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список новостей</h2>
  <div style="display:flex;gap:10px;align-items:center;margin-bottom:10px;">
    <input id="newsSearchInput" placeholder="Поиск по заголовку..." style="max-width:340px;margin:0;">
    <select id="newsStatusFilter" style="max-width:180px;padding:10px;border:1px solid #d1d5db;border-radius:8px;">
      <option value="all">Все статусы</option>
      <option value="published">Опубликовано</option>
      <option value="draft">Черновик</option>
    </select>
  </div>
  <table>
    <thead>
    <tr><th>ID</th><th>Заголовок</th><th>Изображение</th><th>Статус</th><th>Закреп</th><th>Дата</th><th>Действия</th></tr>
    </thead>
    <tbody id="newsTableBody">
    <?php foreach ($news as $row): ?>
      <tr data-title="<?= h(mb_strtolower((string)$row['title'])) ?>" data-status="<?= (int)$row['is_published'] === 1 ? 'published' : 'draft' ?>">
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['title']) ?></td>
        <td>
          <?php if (!empty($row['image_url'])): ?>
            <a href="<?= h((string)$row['image_url']) ?>" target="_blank">Открыть</a>
            <div><img src="<?= h((string)$row['image_url']) ?>" alt="" style="margin-top:6px;width:110px;height:62px;object-fit:cover;border-radius:6px;"></div>
          <?php else: ?>
            <span class="muted">Нет</span>
          <?php endif; ?>
        </td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликовано' : 'Черновик' ?></td>
        <td><?= !empty($row['is_pinned']) ? '📌 Да' : '—' ?></td>
        <td><?= h((string)($row['published_at'] ?? '')) ?></td>
        <td>
          <a href="/admin/news.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="toggle_publish">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit"><?= (int)$row['is_published'] === 1 ? 'Скрыть' : 'Показать' ?></button>
          </form>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="toggle_pin">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit"><?= !empty($row['is_pinned']) ? 'Открепить' : 'Закрепить' ?></button>
          </form>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить новость?')">Удалить</button>
            </form>
          <?php endif; ?>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
</div>

<link rel="stylesheet" href="https://unpkg.com/cropperjs@1.6.2/dist/cropper.min.css">
<script src="https://unpkg.com/cropperjs@1.6.2/dist/cropper.min.js"></script>
<script>
(() => {
  const input = document.getElementById('news_image_file');
  const preview = document.getElementById('news_crop_preview');
  const hidden = document.getElementById('news_cropped_image_data');
  if (!input || !preview || !hidden) return;
  let cropper = null;

  input.addEventListener('change', (e) => {
    const file = e.target.files && e.target.files[0];
    hidden.value = '';
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      preview.src = reader.result;
      preview.style.display = 'block';
      if (cropper) cropper.destroy();
      cropper = new Cropper(preview, {
        aspectRatio: 16 / 9,
        viewMode: 1,
        autoCropArea: 1,
        responsive: true,
        cropend: updateCrop,
        ready: updateCrop
      });
    };
    reader.readAsDataURL(file);
  });

  function updateCrop() {
    if (!cropper) return;
    const canvas = cropper.getCroppedCanvas({ width: 1280, height: 720 });
    hidden.value = canvas.toDataURL('image/jpeg', 0.9);
  }
})();
</script>
<script>
(() => {
  const search = document.getElementById('newsSearchInput');
  const status = document.getElementById('newsStatusFilter');
  const tbody = document.getElementById('newsTableBody');
  if (!search || !status || !tbody) return;
  const rows = Array.from(tbody.querySelectorAll('tr'));

  function applyFilters() {
    const q = search.value.trim().toLowerCase();
    const st = status.value;
    rows.forEach((row) => {
      const title = row.dataset.title || '';
      const rowStatus = row.dataset.status || '';
      const matchesQ = q === '' || title.includes(q);
      const matchesStatus = st === 'all' || st === rowStatus;
      row.style.display = matchesQ && matchesStatus ? '' : 'none';
    });
  }

  search.addEventListener('input', applyFilters);
  status.addEventListener('change', applyFilters);
})();
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
