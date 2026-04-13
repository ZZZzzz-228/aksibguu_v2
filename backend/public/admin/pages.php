<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
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
                 WHERE id = :rid AND entity_type = "page" AND entity_id = :eid
                 LIMIT 1'
            );
            $revStmt->execute(['rid' => $revisionId, 'eid' => $id]);
            $rev = $revStmt->fetch(PDO::FETCH_ASSOC);
            if ($rev) {
                $currentUser = getCurrentUser();
                $currentUserId = (int)($currentUser['id'] ?? 0);
                $upd = $pdo->prepare(
                    'UPDATE pages
                     SET title = :title, content_json = :content_json, updated_by = :updated_by
                     WHERE id = :id'
                );
                $upd->execute([
                    'title' => (string)$rev['title'],
                    'content_json' => (string)$rev['content_json'],
                    'updated_by' => $currentUserId > 0 ? $currentUserId : null,
                    'id' => $id,
                ]);
                auditLog($pdo, 'restore_revision', 'page', (string)$id, ['revision_id' => $revisionId]);
                flash('Версия страницы восстановлена.');
            }
        }
        redirectTo('/admin/pages.php?edit=' . $id);
    }
    if ($action === 'save') {
        requireCsrf();
        $id = (int)($_POST['id'] ?? 0);
        $slug = trim((string)($_POST['slug'] ?? ''));
        $titleValue = trim((string)($_POST['title'] ?? ''));
        $audience = trim((string)($_POST['audience'] ?? 'common'));
        $lead = trim((string)($_POST['lead'] ?? ''));
        $body = trim((string)($_POST['body'] ?? ''));
        $coverImageUrl = trim((string)($_POST['cover_image_url'] ?? ''));
        $isPublished = isset($_POST['is_published']) ? 1 : 0;
        $publishFrom = trim((string)($_POST['publish_from'] ?? ''));
        $publishTo = trim((string)($_POST['publish_to'] ?? ''));
        $publishFromSql = $publishFrom !== '' ? str_replace('T', ' ', $publishFrom) . ':00' : null;
        $publishToSql = $publishTo !== '' ? str_replace('T', ' ', $publishTo) . ':00' : null;
        $croppedImageData = (string)($_POST['cropped_cover_data'] ?? '');
        if ($croppedImageData !== '') {
            $saved = saveBase64Image($croppedImageData);
            if ($saved !== null) {
                $coverImageUrl = $saved;
            }
        } else {
            $uploaded = saveUploadedImage('cover_file');
            if ($uploaded !== null) {
                $coverImageUrl = $uploaded;
            }
        }
        if ($slug === '' || $titleValue === '') {
            flash('Заполните slug и title.');
            redirectTo('/admin/pages.php');
        }
        if (!preg_match('/^[a-z0-9\-]+$/', $slug)) {
            flash('Slug должен содержать только a-z, 0-9 и дефис.');
            redirectTo('/admin/pages.php');
        }
        if (!in_array($audience, ['guest', 'applicant', 'student', 'teacher', 'common'], true)) {
            $audience = 'common';
        }
        $contentJson = json_encode([
            'lead' => $lead,
            'body' => $body,
        ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

        $currentUser = getCurrentUser();
        $currentUserId = (int)($currentUser['id'] ?? 0);

        if ($id > 0) {
            $beforeStmt = $pdo->prepare('SELECT title, content_json FROM pages WHERE id=:id LIMIT 1');
            $beforeStmt->execute(['id' => $id]);
            $before = $beforeStmt->fetch(PDO::FETCH_ASSOC);
            if ($before) {
                $revStmt = $pdo->prepare(
                    'INSERT INTO content_revisions(entity_type, entity_id, title, content_json, created_by)
                     VALUES ("page", :eid, :title, :content_json, :uid)'
                );
                $revStmt->execute([
                    'eid' => $id,
                    'title' => (string)$before['title'],
                    'content_json' => (string)$before['content_json'],
                    'uid' => $currentUserId > 0 ? $currentUserId : null,
                ]);
            }
            $stmt = $pdo->prepare(
                'UPDATE pages
                 SET slug=:slug, title=:title, audience=:audience, content_json=:content_json, cover_image_url=:cover_image_url, is_published=:is_published,
                     publish_from=:publish_from, publish_to=:publish_to, updated_by=:updated_by
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'slug' => $slug,
                'title' => $titleValue,
                'audience' => $audience,
                'content_json' => $contentJson,
                'cover_image_url' => $coverImageUrl !== '' ? $coverImageUrl : null,
                'is_published' => $isPublished,
                'publish_from' => $publishFromSql,
                'publish_to' => $publishToSql,
                'updated_by' => $currentUserId > 0 ? $currentUserId : null,
            ]);
            auditLog($pdo, 'update', 'page', (string)$id, ['slug' => $slug, 'audience' => $audience]);
            flash('Страница обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO pages(slug, title, audience, content_json, cover_image_url, is_published, created_by, updated_by)
                 VALUES (:slug, :title, :audience, :content_json, :cover_image_url, :is_published, :created_by, :updated_by)'
            );
            $stmt->execute([
                'slug' => $slug,
                'title' => $titleValue,
                'audience' => $audience,
                'content_json' => $contentJson,
                'cover_image_url' => $coverImageUrl !== '' ? $coverImageUrl : null,
                'is_published' => $isPublished,
                'created_by' => $currentUserId > 0 ? $currentUserId : null,
                'updated_by' => $currentUserId > 0 ? $currentUserId : null,
            ]);
            $newId = (int)$pdo->lastInsertId();
            $pdo->prepare('UPDATE pages SET publish_from=:pf, publish_to=:pt WHERE id=:id')->execute([
                'pf' => $publishFromSql,
                'pt' => $publishToSql,
                'id' => $newId,
            ]);
            auditLog($pdo, 'create', 'page', (string)$newId, ['slug' => $slug, 'audience' => $audience]);
            flash('Страница добавлена.');
        }
    }
    if ($action === 'delete') {
        requireCsrf();
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/pages.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM pages WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'page', (string)$id);
            flash('Страница удалена.');
        }
    }
    redirectTo('/admin/pages.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
$revisions = [];
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM pages WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    $revStmt = $pdo->prepare(
        'SELECT id, title, created_at
         FROM content_revisions
         WHERE entity_type = "page" AND entity_id = :id
         ORDER BY id DESC
         LIMIT 10'
    );
    $revStmt->execute(['id' => $editId]);
    $revisions = $revStmt->fetchAll(PDO::FETCH_ASSOC);
}

$rows = $pdo->query('SELECT id, slug, title, audience, cover_image_url, is_published, updated_at FROM pages ORDER BY updated_at DESC, id DESC')->fetchAll(PDO::FETCH_ASSOC);
$title = 'Страницы (CMS)';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать страницу' : 'Добавить страницу' ?></h2>
  <?php
    $decoded = null;
    if (!empty($editItem['content_json'])) {
        $decoded = json_decode((string)$editItem['content_json'], true);
    }
    $leadValue = is_array($decoded) ? (string)($decoded['lead'] ?? '') : '';
    $bodyValue = is_array($decoded) ? (string)($decoded['body'] ?? '') : '';
    $selectedAudience = (string)($editItem['audience'] ?? 'common');
    $publishFromValue = !empty($editItem['publish_from']) ? str_replace(' ', 'T', substr((string)$editItem['publish_from'], 0, 16)) : '';
    $publishToValue = !empty($editItem['publish_to']) ? str_replace(' ', 'T', substr((string)$editItem['publish_to'], 0, 16)) : '';
  ?>
  <form method="post" enctype="multipart/form-data">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Slug (пример: about-college)</label>
    <input name="slug" value="<?= h((string)($editItem['slug'] ?? '')) ?>" required>
    <label>Заголовок</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>
    <label>Аудитория</label>
    <select name="audience" style="width:100%;padding:10px;border:1px solid #d1d5db;border-radius:8px;margin-top:6px;margin-bottom:10px;">
      <option value="common" <?= $selectedAudience === 'common' ? 'selected' : '' ?>>common</option>
      <option value="guest" <?= $selectedAudience === 'guest' ? 'selected' : '' ?>>guest</option>
      <option value="applicant" <?= $selectedAudience === 'applicant' ? 'selected' : '' ?>>applicant</option>
      <option value="student" <?= $selectedAudience === 'student' ? 'selected' : '' ?>>student</option>
      <option value="teacher" <?= $selectedAudience === 'teacher' ? 'selected' : '' ?>>teacher</option>
    </select>
    <label>Лид-абзац</label>
    <textarea name="lead"><?= h($leadValue) ?></textarea>
    <label>Основной текст</label>
    <textarea name="body"><?= h($bodyValue) ?></textarea>
    <label>Cover image URL</label>
    <input name="cover_image_url" value="<?= h((string)($editItem['cover_image_url'] ?? '')) ?>">
    <label>Или загрузить cover</label>
    <input id="page_cover_file" name="cover_file" type="file" accept="image/jpeg,image/png,image/webp">
    <input id="page_cropped_cover_data" name="cropped_cover_data" type="hidden">
    <div style="max-width:480px;margin-top:8px;">
      <img id="page_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
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
    <button type="button" class="btn btnGhost" id="previewPageBtn">Предпросмотр на мобильном</button>
    <div id="pagePreviewWrap" style="display:none;margin-top:12px;">
      <div style="max-width:320px;border:10px solid #0f172a;border-radius:24px;padding:10px;background:#fff;">
        <img id="previewCover" src="" alt="" style="width:100%;height:140px;object-fit:cover;border-radius:12px;display:none;">
        <h3 id="previewTitle" style="font-size:17px;margin:10px 0 6px;"></h3>
        <p id="previewLead" class="muted" style="margin:0 0 8px;"></p>
        <div id="previewBody" style="font-size:14px;white-space:pre-wrap;"></div>
      </div>
    </div>
    <br><br><button type="submit">Сохранить</button>
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
  <h2 style="margin-top:0;">Список страниц</h2>
  <table>
    <thead><tr><th>ID</th><th>Slug</th><th>Заголовок</th><th>Аудитория</th><th>Cover</th><th>Статус</th><th>Обновлено</th><th>Действия</th></tr></thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['slug']) ?></td>
        <td><?= h((string)$row['title']) ?></td>
        <td><?= h((string)$row['audience']) ?></td>
        <td><?php if (!empty($row['cover_image_url'])): ?><img src="<?= h((string)$row['cover_image_url']) ?>" alt="" style="width:90px;height:60px;object-fit:cover;border-radius:6px;"><?php endif; ?></td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликовано' : 'Скрыто' ?></td>
        <td><?= h((string)$row['updated_at']) ?></td>
        <td>
          <a href="/admin/pages.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <?= csrfField() ?>
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить страницу?')">Удалить</button>
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
  const input = document.getElementById('page_cover_file');
  const preview = document.getElementById('page_crop_preview');
  const hidden = document.getElementById('page_cropped_cover_data');
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
<script>
(() => {
  const btn = document.getElementById('previewPageBtn');
  if (!btn) return;
  const wrap = document.getElementById('pagePreviewWrap');
  const titleEl = document.getElementById('previewTitle');
  const leadEl = document.getElementById('previewLead');
  const bodyEl = document.getElementById('previewBody');
  const coverEl = document.getElementById('previewCover');
  const titleInput = document.querySelector('input[name="title"]');
  const leadInput = document.querySelector('textarea[name="lead"]');
  const bodyInput = document.querySelector('textarea[name="body"]');
  const coverInput = document.querySelector('input[name="cover_image_url"]');
  btn.addEventListener('click', () => {
    if (!wrap || !titleEl || !leadEl || !bodyEl) return;
    titleEl.textContent = (titleInput && titleInput.value.trim()) || 'Без заголовка';
    leadEl.textContent = (leadInput && leadInput.value.trim()) || '';
    bodyEl.textContent = (bodyInput && bodyInput.value.trim()) || '';
    const cover = (coverInput && coverInput.value.trim()) || '';
    if (cover && coverEl) {
      coverEl.src = cover;
      coverEl.style.display = '';
    } else if (coverEl) {
      coverEl.style.display = 'none';
    }
    wrap.style.display = '';
  });
})();
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
