<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $name = trim((string)($_POST['name'] ?? ''));
        $description = trim((string)($_POST['description'] ?? ''));
        $websiteUrl = trim((string)($_POST['website_url'] ?? ''));
        $logoUrl = trim((string)($_POST['logo_url'] ?? ''));
        $sortOrder = (int)($_POST['sort_order'] ?? 0);
        $isPublished = isset($_POST['is_published']) ? 1 : 0;
        $croppedImageData = (string)($_POST['cropped_logo_data'] ?? '');
        if ($croppedImageData !== '') {
            $saved = saveBase64Image($croppedImageData);
            if ($saved !== null) {
                $logoUrl = $saved;
            }
        } else {
            $uploaded = saveUploadedImage('logo_file');
            if ($uploaded !== null) {
                $logoUrl = $uploaded;
            }
        }
        if ($name === '') {
            flash('Заполните название партнера.');
            redirectTo('/admin/partners.php');
        }
        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE partners
                 SET name=:name, description=:description, website_url=:website_url, logo_url=:logo_url, sort_order=:sort_order, is_published=:is_published
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'name' => $name,
                'description' => $description !== '' ? $description : null,
                'website_url' => $websiteUrl !== '' ? $websiteUrl : null,
                'logo_url' => $logoUrl !== '' ? $logoUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            auditLog($pdo, 'update', 'partner', (string)$id, ['name' => $name]);
            flash('Партнер обновлен.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO partners(name, description, website_url, logo_url, sort_order, is_published)
                 VALUES (:name, :description, :website_url, :logo_url, :sort_order, :is_published)'
            );
            $stmt->execute([
                'name' => $name,
                'description' => $description !== '' ? $description : null,
                'website_url' => $websiteUrl !== '' ? $websiteUrl : null,
                'logo_url' => $logoUrl !== '' ? $logoUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'partner', (string)$newId, ['name' => $name]);
            flash('Партнер добавлен.');
        }
    }
    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/partners.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM partners WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'partner', (string)$id);
            flash('Партнер удален.');
        }
    }
    redirectTo('/admin/partners.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM partners WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}
$rows = $pdo->query('SELECT * FROM partners ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);
$title = 'Партнеры';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать партнера' : 'Добавить партнера' ?></h2>
  <form method="post" enctype="multipart/form-data">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Название</label>
    <input name="name" value="<?= h((string)($editItem['name'] ?? '')) ?>" required>
    <label>Описание</label>
    <textarea name="description"><?= h((string)($editItem['description'] ?? '')) ?></textarea>
    <label>Сайт</label>
    <input name="website_url" value="<?= h((string)($editItem['website_url'] ?? '')) ?>">
    <label>Logo URL</label>
    <input name="logo_url" value="<?= h((string)($editItem['logo_url'] ?? '')) ?>">
    <label>Или загрузить логотип</label>
    <input id="partner_logo_file" name="logo_file" type="file" accept="image/jpeg,image/png,image/webp">
    <input id="partner_cropped_logo_data" name="cropped_logo_data" type="hidden">
    <div style="max-width:360px;margin-top:8px;">
      <img id="partner_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
    <label>Порядок</label>
    <input type="number" name="sort_order" value="<?= (int)($editItem['sort_order'] ?? 0) ?>">
    <label><input type="checkbox" name="is_published" <?= ($editItem === null || !empty($editItem['is_published'])) ? 'checked' : '' ?>> Опубликовано</label>
    <br><br><button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список партнеров</h2>
  <table>
    <thead><tr><th>ID</th><th>Логотип</th><th>Название</th><th>Сайт</th><th>Порядок</th><th>Статус</th><th>Действия</th></tr></thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?php if (!empty($row['logo_url'])): ?><img src="<?= h((string)$row['logo_url']) ?>" alt="" style="width:90px;height:60px;object-fit:contain;background:#fff;"><?php endif; ?></td>
        <td><?= h((string)$row['name']) ?></td>
        <td><?= h((string)($row['website_url'] ?? '')) ?></td>
        <td><?= (int)$row['sort_order'] ?></td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликовано' : 'Скрыто' ?></td>
        <td>
          <a href="/admin/partners.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить партнера?')">Удалить</button>
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
  const input = document.getElementById('partner_logo_file');
  const preview = document.getElementById('partner_crop_preview');
  const hidden = document.getElementById('partner_cropped_logo_data');
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
      cropper = new Cropper(preview, { aspectRatio: 1, viewMode: 1, autoCropArea: 1, cropend: updateCrop, ready: updateCrop });
    };
    reader.readAsDataURL(file);
  });
  function updateCrop() {
    if (!cropper) return;
    const canvas = cropper.getCroppedCanvas({ width: 600, height: 600 });
    hidden.value = canvas.toDataURL('image/jpeg', 0.9);
  }
})();
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
