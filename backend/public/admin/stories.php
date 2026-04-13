<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $title = trim((string)($_POST['title'] ?? ''));
        $content = trim((string)($_POST['content'] ?? ''));
        $imageUrl = trim((string)($_POST['image_url'] ?? ''));
        $sortOrder = (int)($_POST['sort_order'] ?? 0);
        $isPublished = isset($_POST['is_published']) ? 1 : 0;

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

        if ($title === '' || $content === '') {
            flash('Заполните title и content.');
            redirectTo('/admin/stories.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE stories
                 SET title=:title, content=:content, image_url=:image_url, sort_order=:sort_order, is_published=:is_published
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'title' => $title,
                'content' => $content,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            auditLog($pdo, 'update', 'story', (string)$id, [
                'title' => $title,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            flash('История обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO stories(title, content, image_url, sort_order, is_published)
                 VALUES (:title, :content, :image_url, :sort_order, :is_published)'
            );
            $stmt->execute([
                'title' => $title,
                'content' => $content,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'story', (string)$newId, [
                'title' => $title,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            flash('История добавлена.');
        }
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/stories.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM stories WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'story', (string)$id, null);
            flash('История удалена.');
        }
    }

    if ($action === 'toggle_publish') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE stories SET is_published = 1 - is_published WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'toggle_publish', 'story', (string)$id, null);
            flash('Статус истории переключен.');
        }
    }

    if ($action === 'move_up' || $action === 'move_down') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $delta = $action === 'move_up' ? -1 : 1;
            $stmt = $pdo->prepare('UPDATE stories SET sort_order = GREATEST(0, sort_order + :delta) WHERE id=:id');
            $stmt->bindValue(':delta', $delta, PDO::PARAM_INT);
            $stmt->bindValue(':id', $id, PDO::PARAM_INT);
            $stmt->execute();
            auditLog($pdo, $action, 'story', (string)$id, null);
            flash('Порядок истории изменен.');
        }
    }

    if ($action === 'reorder') {
        $orderJson = (string)($_POST['order_json'] ?? '');
        $ids = json_decode($orderJson, true);
        if (is_array($ids)) {
            $sort = 0;
            $stmt = $pdo->prepare('UPDATE stories SET sort_order = :sort_order WHERE id = :id');
            foreach ($ids as $storyId) {
                $storyId = (int)$storyId;
                if ($storyId <= 0) {
                    continue;
                }
                $stmt->execute([
                    'id' => $storyId,
                    'sort_order' => $sort,
                ]);
                $sort++;
            }
            auditLog($pdo, 'reorder', 'story', 'bulk', ['ids' => $ids]);
            flash('Порядок историй сохранен.');
        }
    }
    redirectTo('/admin/stories.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM stories WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$stories = $pdo->query('SELECT id, title, image_url, sort_order, is_published FROM stories ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);

$title = 'Управление историями';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать историю' : 'Добавить историю' ?></h2>
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
    <input id="story_image_file" name="image_file" type="file" accept="image/jpeg,image/png,image/webp">
    <input id="story_cropped_image_data" name="cropped_image_data" type="hidden">
    <div class="muted">Формат сторис: 9:16</div>
    <div style="max-width:280px;margin-top:8px;">
      <img id="story_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
    <label>Порядок</label>
    <input name="sort_order" type="number" value="<?= (int)($editItem['sort_order'] ?? 0) ?>">
    <label><input type="checkbox" name="is_published" <?= ($editItem === null || !empty($editItem['is_published'])) ? 'checked' : '' ?>> Опубликовано</label>
    <br><br>
    <button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список историй</h2>
  <div style="display:flex;gap:10px;align-items:center;margin-bottom:10px;">
    <input id="storiesSearchInput" placeholder="Поиск по заголовку..." style="max-width:340px;margin:0;">
    <select id="storiesStatusFilter" style="max-width:180px;padding:10px;border:1px solid #d1d5db;border-radius:8px;">
      <option value="all">Все статусы</option>
      <option value="published">Опубликовано</option>
      <option value="draft">Черновик</option>
    </select>
  </div>
  <div class="muted" style="margin-bottom:8px;">Можно перетаскивать строки мышкой.</div>
  <form method="post" id="storiesReorderForm" style="margin-bottom:12px;">
    <input type="hidden" name="action" value="reorder">
    <input type="hidden" name="order_json" id="storiesOrderJson">
    <button type="submit">Сохранить порядок</button>
  </form>
  <table>
    <thead>
    <tr><th>ID</th><th>Заголовок</th><th>Изображение</th><th>Порядок</th><th>Статус</th><th>Действия</th></tr>
    </thead>
    <tbody id="storiesSortableBody">
    <?php foreach ($stories as $row): ?>
      <tr draggable="true" data-id="<?= (int)$row['id'] ?>" data-title="<?= h(mb_strtolower((string)$row['title'])) ?>" data-status="<?= (int)$row['is_published'] === 1 ? 'published' : 'draft' ?>">
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['title']) ?></td>
        <td>
          <?php if (!empty($row['image_url'])): ?>
            <a href="<?= h((string)$row['image_url']) ?>" target="_blank">Открыть</a>
            <div><img src="<?= h((string)$row['image_url']) ?>" alt="" style="margin-top:6px;width:62px;height:110px;object-fit:cover;border-radius:6px;"></div>
          <?php else: ?>
            <span class="muted">Нет</span>
          <?php endif; ?>
        </td>
        <td><?= (int)$row['sort_order'] ?></td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликовано' : 'Черновик' ?></td>
        <td>
          <a href="/admin/stories.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="move_up">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit">Вверх</button>
          </form>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="move_down">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit">Вниз</button>
          </form>
          <form method="post" style="display:inline;">
            <input type="hidden" name="action" value="toggle_publish">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit"><?= (int)$row['is_published'] === 1 ? 'Скрыть' : 'Показать' ?></button>
          </form>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить историю?')">Удалить</button>
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
  const input = document.getElementById('story_image_file');
  const preview = document.getElementById('story_crop_preview');
  const hidden = document.getElementById('story_cropped_image_data');
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
        aspectRatio: 9 / 16,
        viewMode: 1,
        autoCropArea: 1,
        cropend: updateCrop,
        ready: updateCrop
      });
    };
    reader.readAsDataURL(file);
  });
  function updateCrop() {
    if (!cropper) return;
    const canvas = cropper.getCroppedCanvas({ width: 540, height: 960 });
    hidden.value = canvas.toDataURL('image/jpeg', 0.9);
  }
})();
</script>
<script>
(() => {
  const tbody = document.getElementById('storiesSortableBody');
  const form = document.getElementById('storiesReorderForm');
  const orderInput = document.getElementById('storiesOrderJson');
  if (!tbody || !form || !orderInput) return;
  let dragRow = null;

  tbody.querySelectorAll('tr[draggable="true"]').forEach((row) => {
    row.addEventListener('dragstart', () => {
      dragRow = row;
      row.style.opacity = '0.5';
    });
    row.addEventListener('dragend', () => {
      row.style.opacity = '';
      dragRow = null;
    });
    row.addEventListener('dragover', (e) => e.preventDefault());
    row.addEventListener('drop', (e) => {
      e.preventDefault();
      if (!dragRow || dragRow === row) return;
      const rows = Array.from(tbody.querySelectorAll('tr[draggable="true"]'));
      const dragIndex = rows.indexOf(dragRow);
      const dropIndex = rows.indexOf(row);
      if (dragIndex < dropIndex) {
        row.after(dragRow);
      } else {
        row.before(dragRow);
      }
    });
  });

  form.addEventListener('submit', () => {
    const order = Array.from(tbody.querySelectorAll('tr[draggable="true"]'))
      .map((r) => Number(r.dataset.id || 0))
      .filter((id) => id > 0);
    orderInput.value = JSON.stringify(order);
  });
})();
</script>
<script>
(() => {
  const search = document.getElementById('storiesSearchInput');
  const status = document.getElementById('storiesStatusFilter');
  const tbody = document.getElementById('storiesSortableBody');
  if (!search || !status || !tbody) return;

  function applyFilters() {
    const q = search.value.trim().toLowerCase();
    const st = status.value;
    Array.from(tbody.querySelectorAll('tr')).forEach((row) => {
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
