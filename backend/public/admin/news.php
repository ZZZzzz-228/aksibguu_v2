<?php
require __DIR__ . '/_bootstrap.php';
$user = requireLogin();
if (!canManageContent()) {
    flash('Недостаточно прав для раздела контента.');
    redirectTo('/admin/index.php');
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'restore_revision') {
        requireCsrf();
        $id = (int)($_POST['id'] ?? 0);
        $revisionId = (int)($_POST['revision_id'] ?? 0);
        if ($id > 0 && $revisionId > 0) {
            $revStmt = $pdo->prepare(
                'SELECT title, content_json
                 FROM content_revisions
                 WHERE id=:rid AND entity_type="news" AND entity_id=:eid
                 LIMIT 1'
            );
            $revStmt->execute(['rid' => $revisionId, 'eid' => $id]);
            $rev = $revStmt->fetch(PDO::FETCH_ASSOC);
            if ($rev) {
                $decoded = json_decode((string)$rev['content_json'], true);
                $content = is_array($decoded) ? (string)($decoded['content'] ?? '') : '';
                $imageUrl = is_array($decoded) ? (string)($decoded['image_url'] ?? '') : '';
                $upd = $pdo->prepare(
                    'UPDATE news_items
                     SET title=:title, content=:content, image_url=:image_url
                     WHERE id=:id'
                );
                $upd->execute([
                    'title' => (string)$rev['title'],
                    'content' => $content,
                    'image_url' => $imageUrl !== '' ? $imageUrl : null,
                    'id' => $id,
                ]);
                auditLog($pdo, 'restore_revision', 'news_item', (string)$id, ['revision_id' => $revisionId]);
                flash('Версия новости восстановлена.');
            }
        }
        redirectTo('/admin/news.php?edit=' . $id);
    }
    if ($action === 'save') {
        requireCsrf();
        $id = (int)($_POST['id'] ?? 0);
        $title = trim((string)($_POST['title'] ?? ''));
        $content = trim((string)($_POST['content'] ?? ''));
        $imageUrl = trim((string)($_POST['image_url'] ?? ''));
        $croppedImageData = (string)($_POST['cropped_image_data'] ?? '');
        $savedFromCrop = null;
        if (!empty($_POST['remove_image'])) {
            $imageUrl = '';
        }
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
        $publishFrom = trim((string)($_POST['publish_from'] ?? ''));
        $publishTo = trim((string)($_POST['publish_to'] ?? ''));
        $publishFromSql = $publishFrom !== '' ? str_replace('T', ' ', $publishFrom) . ':00' : null;
        $publishToSql = $publishTo !== '' ? str_replace('T', ' ', $publishTo) . ':00' : null;

        if ($title === '' || $content === '') {
            flash('Заполните title и content.');
            redirectTo('/admin/news.php');
        }

        if ($id > 0) {
            $beforeStmt = $pdo->prepare('SELECT title, content, image_url FROM news_items WHERE id=:id LIMIT 1');
            $beforeStmt->execute(['id' => $id]);
            $before = $beforeStmt->fetch(PDO::FETCH_ASSOC);
            if ($before) {
                $revStmt = $pdo->prepare(
                    'INSERT INTO content_revisions(entity_type, entity_id, title, content_json, created_by)
                     VALUES ("news", :eid, :title, :content_json, :uid)'
                );
                $revStmt->execute([
                    'eid' => $id,
                    'title' => (string)$before['title'],
                    'content_json' => json_encode([
                        'content' => (string)$before['content'],
                        'image_url' => (string)($before['image_url'] ?? ''),
                    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
                    'uid' => (int)$user['id'],
                ]);
            }

            $stmt = $pdo->prepare(
                'UPDATE news_items
                 SET title=:title, content=:content, image_url=:image_url, is_published=:is_published, is_pinned=:is_pinned,
                     publish_from=:publish_from, publish_to=:publish_to
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'title' => $title,
                'content' => $content,
                'image_url' => $imageUrl !== '' ? $imageUrl : null,
                'is_published' => $isPublished,
                'is_pinned' => $isPinned,
                'publish_from' => $publishFromSql,
                'publish_to' => $publishToSql,
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
            $pdo->prepare('UPDATE news_items SET publish_from=:pf, publish_to=:pt WHERE id=:id')->execute([
                'pf' => $publishFromSql,
                'pt' => $publishToSql,
                'id' => $newId,
            ]);
            auditLog($pdo, 'create', 'news_item', (string)$newId, [
                'title' => $title,
                'is_published' => $isPublished,
            ]);
            flash('Новость добавлена.');
        }
    }

    if ($action === 'delete') {
        requireCsrf();
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
        requireCsrf();
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE news_items SET is_published = 1 - is_published WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'toggle_publish', 'news_item', (string)$id, null);
            flash('Статус новости переключен.');
        }
    }

    if ($action === 'toggle_pin') {
        requireCsrf();
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
$revisions = [];
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM news_items WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    $revStmt = $pdo->prepare(
        'SELECT id, title, created_at
         FROM content_revisions
         WHERE entity_type = "news" AND entity_id = :id
         ORDER BY id DESC
         LIMIT 10'
    );
    $revStmt->execute(['id' => $editId]);
    $revisions = $revStmt->fetchAll(PDO::FETCH_ASSOC);
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
  <?php
    $publishFromValue = !empty($editItem['publish_from']) ? str_replace(' ', 'T', substr((string)$editItem['publish_from'], 0, 16)) : '';
    $publishToValue = !empty($editItem['publish_to']) ? str_replace(' ', 'T', substr((string)$editItem['publish_to'], 0, 16)) : '';
  ?>
  <form method="post" enctype="multipart/form-data">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Заголовок</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>
    <label>Текст</label>
    <textarea name="content" required><?= h((string)($editItem['content'] ?? '')) ?></textarea>
    <input type="hidden" name="image_url" value="<?= h((string)($editItem['image_url'] ?? '')) ?>">
    <label>Или загрузить изображение</label>
    <input id="news_image_file" name="image_file" type="file" accept="image/jpeg,image/png,image/webp">
    <label><input type="checkbox" name="remove_image" value="1"> Удалить текущее изображение</label>
    <input id="news_cropped_image_data" name="cropped_image_data" type="hidden">
    <div class="muted">После выбора файла можно подвигать кадр. Формат: 16:9.</div>
    <div style="max-width:480px;margin-top:8px;">
      <img id="news_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
    <label><input type="checkbox" name="is_published" <?= ($editItem === null || !empty($editItem['is_published'])) ? 'checked' : '' ?>> Опубликовано</label>
    <label><input type="checkbox" name="is_pinned" <?= !empty($editItem['is_pinned']) ? 'checked' : '' ?>> Закрепить вверху списка</label>
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
    <button type="button" class="btn btnGhost" id="previewNewsBtn">Предпросмотр на мобильном</button>
    <div id="newsPreviewWrap" style="display:none;margin-top:12px;">
      <div style="max-width:320px;border:10px solid #0f172a;border-radius:24px;padding:10px;background:#fff;">
        <img id="newsPreviewImage" src="" alt="" style="width:100%;height:140px;object-fit:cover;border-radius:12px;display:none;">
        <h3 id="newsPreviewTitle" style="font-size:17px;margin:10px 0 6px;"></h3>
        <div id="newsPreviewContent" style="font-size:14px;white-space:pre-wrap;"></div>
      </div>
    </div>
    <?php if (!empty($editItem['image_url'])): ?>
      <div class="muted">Текущее изображение: <a href="<?= h((string)$editItem['image_url']) ?>" target="_blank"><?= h((string)$editItem['image_url']) ?></a></div>
      <img src="<?= h((string)$editItem['image_url']) ?>" alt="" style="max-width:220px;border-radius:8px;margin-top:8px;">
    <?php endif; ?>
    <br><br>
    <button type="submit">Сохранить</button>
  </form>
</div>

<?php if ($editItem): ?>
<div class="card">
  <h2 style="margin-top:0;">История версий (последние 10)</h2>
  <?php if (!$revisions): ?>
    <p class="muted">Версий пока нет.</p>
  <?php else: ?>
    <table>
      <thead><tr><th>ID версии</th><th>Заголовок</th><th>Дата</th><th>Действие</th></tr></thead>
      <tbody>
      <?php foreach ($revisions as $rev): ?>
        <tr>
          <td><?= (int)$rev['id'] ?></td>
          <td><?= h((string)$rev['title']) ?></td>
          <td><?= h((string)$rev['created_at']) ?></td>
          <td>
            <form method="post" onsubmit="return confirm('Восстановить эту версию?');">
              <?= csrfField() ?>
              <input type="hidden" name="action" value="restore_revision">
              <input type="hidden" name="id" value="<?= (int)$editItem['id'] ?>">
              <input type="hidden" name="revision_id" value="<?= (int)$rev['id'] ?>">
              <button type="submit" class="btn btnGhost">Восстановить</button>
            </form>
          </td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  <?php endif; ?>
</div>
<?php endif; ?>

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
            <?= csrfField() ?>
            <input type="hidden" name="action" value="toggle_publish">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit"><?= (int)$row['is_published'] === 1 ? 'Скрыть' : 'Показать' ?></button>
          </form>
          <form method="post" style="display:inline;">
            <?= csrfField() ?>
            <input type="hidden" name="action" value="toggle_pin">
            <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
            <button type="submit"><?= !empty($row['is_pinned']) ? 'Открепить' : 'Закрепить' ?></button>
          </form>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <?= csrfField() ?>
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
<script>
(() => {
  const btn = document.getElementById('previewNewsBtn');
  if (!btn) return;
  const wrap = document.getElementById('newsPreviewWrap');
  const titleEl = document.getElementById('newsPreviewTitle');
  const contentEl = document.getElementById('newsPreviewContent');
  const imageEl = document.getElementById('newsPreviewImage');
  const titleInput = document.querySelector('input[name="title"]');
  const contentInput = document.querySelector('textarea[name="content"]');
  const imageInput = document.querySelector('input[name="image_url"]');
  btn.addEventListener('click', () => {
    if (!wrap || !titleEl || !contentEl) return;
    titleEl.textContent = (titleInput && titleInput.value.trim()) || 'Без заголовка';
    contentEl.textContent = (contentInput && contentInput.value.trim()) || '';
    const image = (imageInput && imageInput.value.trim()) || '';
    if (image && imageEl) {
      imageEl.src = image;
      imageEl.style.display = '';
    } else if (imageEl) {
      imageEl.style.display = 'none';
    }
    wrap.style.display = '';
  });
})();
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
