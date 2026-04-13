<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageContent()) {
    flash('Недостаточно прав для раздела контента.');
    redirectTo('/admin/index.php');
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        requireCsrf();
        $id = (int)($_POST['id'] ?? 0);
        $code = trim((string)($_POST['code'] ?? ''));
        $titleValue = trim((string)($_POST['title'] ?? ''));
        $description = trim((string)($_POST['description'] ?? ''));
        $iconName = trim((string)($_POST['icon_name'] ?? ''));
        $imageUrl = trim((string)($_POST['image_url'] ?? ''));
        $sortOrder = (int)($_POST['sort_order'] ?? 0);
        $isPublished = isset($_POST['is_published']) ? 1 : 0;
        $publishFrom = trim((string)($_POST['publish_from'] ?? ''));
        $publishTo = trim((string)($_POST['publish_to'] ?? ''));
        $publishFromSql = $publishFrom !== '' ? str_replace('T', ' ', $publishFrom) . ':00' : null;
        $publishToSql = $publishTo !== '' ? str_replace('T', ' ', $publishTo) . ':00' : null;
        $croppedImageData = (string)($_POST['cropped_image_data'] ?? '');
        if ($croppedImageData !== '') {
            $saved = saveBase64Image($croppedImageData);
            if ($saved !== null) {
                $imageUrl = $saved;
            }
        } else {
            $uploaded = saveUploadedImage('image_file');
            if ($uploaded !== null) {
                $imageUrl = $uploaded;
            }
        }

        if ($code === '' || $titleValue === '') {
            flash('Заполните code и title.');
            redirectTo('/admin/specialties.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE specialties
                 SET code=:code, title=:title, description=:description, icon_name=:icon_name, image_url=:image_url, sort_order=:sort_order, is_published=:is_published,
                     publish_from=:publish_from, publish_to=:publish_to
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'code' => $code,
                'title' => $titleValue,
                'description' => $description !== '' ? $description : null,
                'icon_name' => $iconName !== '' ? $iconName : null,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
                'publish_from' => $publishFromSql,
                'publish_to' => $publishToSql,
            ]);
            auditLog($pdo, 'update', 'specialty', (string)$id, ['code' => $code, 'title' => $titleValue]);
            flash('Специальность обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO specialties(code, title, description, icon_name, image_url, sort_order, is_published)
                 VALUES (:code, :title, :description, :icon_name, :image_url, :sort_order, :is_published)'
            );
            $stmt->execute([
                'code' => $code,
                'title' => $titleValue,
                'description' => $description !== '' ? $description : null,
                'icon_name' => $iconName !== '' ? $iconName : null,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            $newId = (int)$pdo->lastInsertId();
            $pdo->prepare('UPDATE specialties SET publish_from=:pf, publish_to=:pt WHERE id=:id')->execute([
                'pf' => $publishFromSql,
                'pt' => $publishToSql,
                'id' => $newId,
            ]);
            auditLog($pdo, 'create', 'specialty', (string)$newId, ['code' => $code, 'title' => $titleValue]);
            flash('Специальность добавлена.');
        }
    }
    if ($action === 'delete') {
        requireCsrf();
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/specialties.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM specialties WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'specialty', (string)$id);
            flash('Специальность удалена.');
        }
    }
    redirectTo('/admin/specialties.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM specialties WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$rows = $pdo->query('SELECT * FROM specialties ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);
$title = 'Специальности';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать специальность' : 'Добавить специальность' ?></h2>
  <?php
    $publishFromValue = !empty($editItem['publish_from']) ? str_replace(' ', 'T', substr((string)$editItem['publish_from'], 0, 16)) : '';
    $publishToValue = !empty($editItem['publish_to']) ? str_replace(' ', 'T', substr((string)$editItem['publish_to'], 0, 16)) : '';
  ?>
  <form method="post" enctype="multipart/form-data">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Код</label>
    <input name="code" value="<?= h((string)($editItem['code'] ?? '')) ?>" required>
    <label>Название</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>
    <label>Описание</label>
    <textarea name="description"><?= h((string)($editItem['description'] ?? '')) ?></textarea>
    <label>Имя иконки (опционально)</label>
    <input name="icon_name" value="<?= h((string)($editItem['icon_name'] ?? '')) ?>">
    <label>Image URL</label>
    <input name="image_url" value="<?= h((string)($editItem['image_url'] ?? '')) ?>">
    <label>Или загрузить изображение</label>
    <input id="specialty_image_file" name="image_file" type="file" accept="image/jpeg,image/png,image/webp">
    <input id="specialty_cropped_image_data" name="cropped_image_data" type="hidden">
    <div style="max-width:480px;margin-top:8px;">
      <img id="specialty_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
    <label>Порядок</label>
    <input type="number" name="sort_order" value="<?= (int)($editItem['sort_order'] ?? 0) ?>">
    <label><input type="checkbox" name="is_published" <?= ($editItem === null || !empty($editItem['is_published'])) ? 'checked' : '' ?>> Опубликовано</label>
    <div class="grid2">
      <div>
        <label>Публиковать с (планировщик)</label>
        <input type="datetime-local" name="publish_from" value="<?= h($publishFromValue) ?>">
      </div>
      <div>
        <label>Публиковать по (опционально)</label>
        <input type="datetime-local" name="publish_to" value="<?= h($publishToValue) ?>">
      </div>
    </div>
    <br><br>
    <button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список специальностей</h2>
  <table>
    <thead><tr><th>ID</th><th>Код</th><th>Название</th><th>Изображение</th><th>Порядок</th><th>Статус</th><th>Действия</th></tr></thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['code']) ?></td>
        <td><?= h((string)$row['title']) ?></td>
        <td><?php if (!empty($row['image_url'])): ?><img src="<?= h((string)$row['image_url']) ?>" alt="" style="width:90px;height:60px;object-fit:cover;border-radius:6px;"><?php endif; ?></td>
        <td><?= (int)$row['sort_order'] ?></td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликовано' : 'Скрыто' ?></td>
        <td>
          <a href="/admin/specialties.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <?= csrfField() ?>
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить специальность?')">Удалить</button>
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
  const input = document.getElementById('specialty_image_file');
  const preview = document.getElementById('specialty_crop_preview');
  const hidden = document.getElementById('specialty_cropped_image_data');
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
      cropper = new Cropper(preview, { aspectRatio: 16 / 9, viewMode: 1, autoCropArea: 1, cropend: updateCrop, ready: updateCrop });
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

<?php require __DIR__ . '/_layout_bottom.php'; ?>
