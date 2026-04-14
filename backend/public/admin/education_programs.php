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
        $type = trim((string)($_POST['type'] ?? 'additional'));
        $titleValue = trim((string)($_POST['title'] ?? ''));
        $description = trim((string)($_POST['description'] ?? ''));
        $durationLabel = trim((string)($_POST['duration_label'] ?? ''));
        $details = trim((string)($_POST['details'] ?? ''));
        $targetAudience = trim((string)($_POST['target_audience'] ?? ''));
        $outcomeText = trim((string)($_POST['outcome_text'] ?? ''));
        $formatText = trim((string)($_POST['format_text'] ?? ''));
        $iconName = trim((string)($_POST['icon_name'] ?? ''));
        $colorHex = adminNormalizeHexColor((string)($_POST['color_hex'] ?? ''));
        $imageUrl = trim((string)($_POST['image_url'] ?? ''));
        $sortOrder = (int)($_POST['sort_order'] ?? 0);
        $isPublished = isset($_POST['is_published']) ? 1 : 0;
        $publishFrom = trim((string)($_POST['publish_from'] ?? ''));
        $publishTo = trim((string)($_POST['publish_to'] ?? ''));
        $publishFromSql = $publishFrom !== '' ? str_replace('T', ' ', $publishFrom) . ':00' : null;
        $publishToSql = $publishTo !== '' ? str_replace('T', ' ', $publishTo) . ':00' : null;

        if (!in_array($type, ['additional', 'courses'], true)) {
            $type = 'additional';
        }

        $croppedImageData = (string)($_POST['cropped_image_data'] ?? '');
        if (!empty($_POST['remove_image'])) {
            $imageUrl = '';
        }
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

        if ($titleValue === '') {
            flash('Заполните название программы.');
            redirectTo('/admin/education_programs.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE education_programs
                 SET type=:type, title=:title, description=:description, duration_label=:duration_label, details=:details,
                     target_audience=:target_audience, outcome_text=:outcome_text, format_text=:format_text,
                     icon_name=:icon_name, color_hex=:color_hex, image_url=:image_url, sort_order=:sort_order,
                     is_published=:is_published, publish_from=:publish_from, publish_to=:publish_to
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'type' => $type,
                'title' => $titleValue,
                'description' => $description !== '' ? $description : null,
                'duration_label' => $durationLabel !== '' ? $durationLabel : null,
                'details' => $details !== '' ? $details : null,
                'target_audience' => $targetAudience !== '' ? $targetAudience : null,
                'outcome_text' => $outcomeText !== '' ? $outcomeText : null,
                'format_text' => $formatText !== '' ? $formatText : null,
                'icon_name' => $iconName !== '' ? $iconName : null,
                'color_hex' => $colorHex !== '' ? $colorHex : null,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
                'publish_from' => $publishFromSql,
                'publish_to' => $publishToSql,
            ]);
            auditLog($pdo, 'update', 'education_program', (string)$id, ['type' => $type, 'title' => $titleValue]);
            flash('Программа обучения обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO education_programs(type, title, description, duration_label, details, target_audience, outcome_text, format_text, icon_name, color_hex, image_url, sort_order, is_published, publish_from, publish_to)
                 VALUES (:type, :title, :description, :duration_label, :details, :target_audience, :outcome_text, :format_text, :icon_name, :color_hex, :image_url, :sort_order, :is_published, :publish_from, :publish_to)'
            );
            $stmt->execute([
                'type' => $type,
                'title' => $titleValue,
                'description' => $description !== '' ? $description : null,
                'duration_label' => $durationLabel !== '' ? $durationLabel : null,
                'details' => $details !== '' ? $details : null,
                'target_audience' => $targetAudience !== '' ? $targetAudience : null,
                'outcome_text' => $outcomeText !== '' ? $outcomeText : null,
                'format_text' => $formatText !== '' ? $formatText : null,
                'icon_name' => $iconName !== '' ? $iconName : null,
                'color_hex' => $colorHex !== '' ? $colorHex : null,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
                'publish_from' => $publishFromSql,
                'publish_to' => $publishToSql,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'education_program', (string)$newId, ['type' => $type, 'title' => $titleValue]);
            flash('Программа обучения добавлена.');
        }
    }
    if ($action === 'delete') {
        requireCsrf();
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/education_programs.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM education_programs WHERE id = :id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'education_program', (string)$id);
            flash('Программа обучения удалена.');
        }
    }
    redirectTo('/admin/education_programs.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM education_programs WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$rows = $pdo->query('SELECT * FROM education_programs ORDER BY type ASC, sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);
$title = 'Обучение';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать программу' : 'Добавить программу обучения' ?></h2>
  <?php
    $publishFromValue = !empty($editItem['publish_from']) ? str_replace(' ', 'T', substr((string)$editItem['publish_from'], 0, 16)) : '';
    $publishToValue = !empty($editItem['publish_to']) ? str_replace(' ', 'T', substr((string)$editItem['publish_to'], 0, 16)) : '';
  ?>
  <form method="post" enctype="multipart/form-data">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Тип</label>
    <select name="type">
      <?php $typeValue = (string)($editItem['type'] ?? 'additional'); ?>
      <option value="additional" <?= $typeValue === 'additional' ? 'selected' : '' ?>>Доп. образование</option>
      <option value="courses" <?= $typeValue === 'courses' ? 'selected' : '' ?>>Подготовительные курсы</option>
    </select>
    <label>Название</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>
    <label>Краткое описание</label>
    <textarea name="description"><?= h((string)($editItem['description'] ?? '')) ?></textarea>
    <label>Длительность</label>
    <input name="duration_label" value="<?= h((string)($editItem['duration_label'] ?? '')) ?>">
    <label>Полное описание (в карточке)</label>
    <textarea name="details"><?= h((string)($editItem['details'] ?? '')) ?></textarea>
    <label>Для кого</label>
    <textarea name="target_audience"><?= h((string)($editItem['target_audience'] ?? '')) ?></textarea>
    <label>Что вы получите</label>
    <textarea name="outcome_text"><?= h((string)($editItem['outcome_text'] ?? '')) ?></textarea>
    <label>Формат занятий</label>
    <textarea name="format_text"><?= h((string)($editItem['format_text'] ?? '')) ?></textarea>
    <label>Имя иконки (Icons.* без префикса, напр. web)</label>
    <input name="icon_name" value="<?= h((string)($editItem['icon_name'] ?? '')) ?>">
    <label>Цвет карточки</label>
    <input type="color" name="color_hex" value="<?= h(adminColorForPicker((string)($editItem['color_hex'] ?? ''), '#1565C0')) ?>">
    <input type="hidden" name="image_url" value="<?= h((string)($editItem['image_url'] ?? '')) ?>">
    <label>Или загрузить изображение</label>
    <input id="education_image_file" name="image_file" type="file" accept="image/jpeg,image/png,image/webp">
    <label><input type="checkbox" name="remove_image" value="1"> Удалить текущее изображение</label>
    <input id="education_cropped_image_data" name="cropped_image_data" type="hidden">
    <div style="max-width:480px;margin-top:8px;">
      <img id="education_crop_preview" src="" alt="" style="display:none;max-width:100%;">
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
  <h2 style="margin-top:0;">Список программ</h2>
  <table>
    <thead><tr><th>ID</th><th>Тип</th><th>Название</th><th>Порядок</th><th>Статус</th><th>Действия</th></tr></thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['type']) ?></td>
        <td><?= h((string)$row['title']) ?></td>
        <td><?= (int)$row['sort_order'] ?></td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликовано' : 'Скрыто' ?></td>
        <td>
          <a href="/admin/education_programs.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <?= csrfField() ?>
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить программу?')">Удалить</button>
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
  const input = document.getElementById('education_image_file');
  const preview = document.getElementById('education_crop_preview');
  const hidden = document.getElementById('education_cropped_image_data');
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
