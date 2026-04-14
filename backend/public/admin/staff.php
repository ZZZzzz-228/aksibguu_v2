<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

$isAjax = !empty($_SERVER['HTTP_X_REQUESTED_WITH']) && $_SERVER['HTTP_X_REQUESTED_WITH'] === 'XMLHttpRequest';
$ajaxResponse = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $fullName = trim((string)($_POST['full_name'] ?? ''));
        $positionTitle = trim((string)($_POST['position_title'] ?? ''));
        $email = trim((string)($_POST['email'] ?? ''));
        $phone = trim((string)($_POST['phone'] ?? ''));
        $officeHours = trim((string)($_POST['office_hours'] ?? ''));
        $photoUrl = trim((string)($_POST['photo_url'] ?? ''));
        $colorHex = adminNormalizeHexColor((string)($_POST['color_hex'] ?? ''));
        $croppedPhotoData = (string)($_POST['cropped_photo_data'] ?? '');
        $savedFromCrop = null;
        if ($croppedPhotoData !== '') {
            $savedFromCrop = saveBase64Image($croppedPhotoData);
        }
        if ($savedFromCrop !== null) {
            $photoUrl = $savedFromCrop;
        }
        $uploadedPhotoUrl = saveUploadedImage('photo_file');
        if ($savedFromCrop === null && $uploadedPhotoUrl !== null) {
            $photoUrl = $uploadedPhotoUrl;
        }
        $sortOrder = (int)($_POST['sort_order'] ?? 0);
        $isPublished = isset($_POST['is_published']) ? 1 : 0;

        if ($fullName === '' || $positionTitle === '') {
            flash('Заполните full_name и position_title.');
            redirectTo('/admin/staff.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE staff_members
                 SET full_name=:full_name, position_title=:position_title, email=:email, phone=:phone,
                     office_hours=:office_hours, photo_url=:photo_url, color_hex=:color_hex, sort_order=:sort_order, is_published=:is_published
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'full_name' => $fullName,
                'position_title' => $positionTitle,
                'email' => $email !== '' ? $email : null,
                'phone' => $phone !== '' ? $phone : null,
                'office_hours' => $officeHours !== '' ? $officeHours : null,
                'photo_url' => $photoUrl !== '' ? $photoUrl : null,
                'color_hex' => $colorHex !== '' ? $colorHex : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            auditLog($pdo, 'update', 'staff_member', (string)$id, [
                'full_name' => $fullName,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            flash('Сотрудник обновлен.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO staff_members(full_name, position_title, email, phone, office_hours, photo_url, color_hex, sort_order, is_published)
                 VALUES (:full_name, :position_title, :email, :phone, :office_hours, :photo_url, :color_hex, :sort_order, :is_published)'
            );
            $stmt->execute([
                'full_name' => $fullName,
                'position_title' => $positionTitle,
                'email' => $email !== '' ? $email : null,
                'phone' => $phone !== '' ? $phone : null,
                'office_hours' => $officeHours !== '' ? $officeHours : null,
                'photo_url' => $photoUrl !== '' ? $photoUrl : null,
                'color_hex' => $colorHex !== '' ? $colorHex : null,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'staff_member', (string)$newId, [
                'full_name' => $fullName,
                'sort_order' => $sortOrder,
                'is_published' => $isPublished,
            ]);
            flash('Сотрудник добавлен.');
        }
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/staff.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM staff_members WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'staff_member', (string)$id, null);
            flash('Сотрудник удален.');
        }
    }

    if ($action === 'toggle_publish') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE staff_members SET is_published = 1 - is_published WHERE id=:id');
            $stmt->execute(['id' => $id]);
            
            // Получаем новый статус
            $stmt = $pdo->prepare('SELECT is_published FROM staff_members WHERE id=:id');
            $stmt->execute(['id' => $id]);
            $newStatus = (int)($stmt->fetch(PDO::FETCH_ASSOC)['is_published'] ?? 0);
            
            auditLog($pdo, 'toggle_publish', 'staff_member', (string)$id, null);
            
            if ($isAjax) {
                $ajaxResponse = ['success' => true, 'is_published' => (bool)$newStatus];
            } else {
                flash('Статус сотрудника переключен.');
            }
        } else {
            if ($isAjax) {
                $ajaxResponse = ['success' => false, 'message' => 'ID не найден'];
            }
        }
    }

    if ($action === 'move_up' || $action === 'move_down') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $delta = $action === 'move_up' ? -1 : 1;
            $stmt = $pdo->prepare('UPDATE staff_members SET sort_order = GREATEST(0, sort_order + :delta) WHERE id=:id');
            $stmt->bindValue(':delta', $delta, PDO::PARAM_INT);
            $stmt->bindValue(':id', $id, PDO::PARAM_INT);
            $stmt->execute();
            auditLog($pdo, $action, 'staff_member', (string)$id, null);
            
            if ($isAjax) {
                $ajaxResponse = ['success' => true];
            } else {
                flash('Порядок сотрудника изменен.');
            }
        } else {
            if ($isAjax) {
                $ajaxResponse = ['success' => false, 'message' => 'ID не найден'];
            }
        }
    }

    if ($action === 'reorder') {
        $orderJson = (string)($_POST['order_json'] ?? '');
        $ids = json_decode($orderJson, true);
        if (is_array($ids)) {
            $sort = 0;
            $stmt = $pdo->prepare('UPDATE staff_members SET sort_order = :sort_order WHERE id = :id');
            foreach ($ids as $staffId) {
                $staffId = (int)$staffId;
                if ($staffId <= 0) {
                    continue;
                }
                $stmt->execute([
                    'id' => $staffId,
                    'sort_order' => $sort,
                ]);
                $sort++;
            }
            auditLog($pdo, 'reorder', 'staff_member', 'bulk', ['ids' => $ids]);
            flash('Порядок сотрудников сохранен.');
        }
    }
    
    // Если это AJAX запрос, возвращаем JSON
    if ($isAjax) {
        if ($ajaxResponse === null) {
            $ajaxResponse = ['success' => false, 'message' => 'Неизвестное действие'];
        }
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($ajaxResponse, JSON_UNESCAPED_UNICODE);
        exit;
    }
    
    redirectTo('/admin/staff.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM staff_members WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$staffRows = $pdo->query('SELECT id, full_name, position_title, photo_url, color_hex, is_published, sort_order FROM staff_members ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);

$title = 'Управление сотрудниками';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?>
  <div class="flash"><?= h($msg) ?></div>
<?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать сотрудника' : 'Добавить сотрудника' ?></h2>
  <form method="post" enctype="multipart/form-data">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>ФИО</label>
    <input name="full_name" value="<?= h((string)($editItem['full_name'] ?? '')) ?>" required>
    <label>Должность</label>
    <input name="position_title" value="<?= h((string)($editItem['position_title'] ?? '')) ?>" required>
    <label>Email</label>
    <input name="email" value="<?= h((string)($editItem['email'] ?? '')) ?>">
    <label>Телефон</label>
    <input name="phone" value="<?= h((string)($editItem['phone'] ?? '')) ?>">
    <label>Часы приема</label>
    <input name="office_hours" value="<?= h((string)($editItem['office_hours'] ?? '')) ?>">
    <label>Цвет карточки</label>
    <input type="color" name="color_hex" value="<?= h(adminColorForPicker((string)($editItem['color_hex'] ?? ''), '#4A90E2')) ?>">
    <label>Фото URL</label>
    <input name="photo_url" value="<?= h((string)($editItem['photo_url'] ?? '')) ?>">
    <label>Или загрузить фото</label>
    <input id="staff_photo_file" name="photo_file" type="file" accept="image/jpeg,image/png,image/webp">
    <input id="staff_cropped_photo_data" name="cropped_photo_data" type="hidden">
    <div class="muted">После выбора файла можно подвигать кадр. Формат: 1:1.</div>
    <div style="max-width:320px;margin-top:8px;">
      <img id="staff_crop_preview" src="" alt="" style="display:none;max-width:100%;">
    </div>
    <label>Порядок сортировки</label>
    <input name="sort_order" type="number" value="<?= (int)($editItem['sort_order'] ?? 0) ?>">
    <label><input type="checkbox" name="is_published" <?= !empty($editItem['is_published']) ? 'checked' : '' ?>> Опубликован</label>
    <br><br>
    <button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список сотрудников</h2>
  <div style="display:flex;gap:10px;align-items:center;margin-bottom:10px;">
    <input id="staffSearchInput" placeholder="Поиск по ФИО/должности..." style="max-width:340px;margin:0;">
    <select id="staffStatusFilter" style="max-width:180px;padding:10px;border:1px solid #d1d5db;border-radius:8px;">
      <option value="all">Все статусы</option>
      <option value="published">Опубликован</option>
      <option value="draft">Скрыт</option>
    </select>
  </div>
  <div class="muted" style="margin-bottom:8px;">Можно перетаскивать строки мышкой.</div>
  <form method="post" id="staffReorderForm" style="margin-bottom:12px;">
    <input type="hidden" name="action" value="reorder">
    <input type="hidden" name="order_json" id="staffOrderJson">
    <button type="submit">Сохранить порядок</button>
  </form>
  <table>
    <thead>
    <tr><th>ID</th><th>Фото</th><th>ФИО</th><th>Должность</th><th>Цвет</th><th>Статус</th><th>Порядок</th><th>Действия</th></tr>
    </thead>
    <tbody id="staffSortableBody">
    <?php foreach ($staffRows as $row): ?>
      <tr draggable="true" data-id="<?= (int)$row['id'] ?>" data-title="<?= h(mb_strtolower((string)$row['full_name'] . ' ' . (string)$row['position_title'])) ?>" data-status="<?= (int)$row['is_published'] === 1 ? 'published' : 'draft' ?>">
        <td><?= (int)$row['id'] ?></td>
        <td>
          <?php if (!empty($row['photo_url'])): ?>
            <img src="<?= h((string)$row['photo_url']) ?>" alt="" style="width:52px;height:52px;object-fit:cover;border-radius:50%;">
          <?php else: ?>
            <span class="muted">Нет</span>
          <?php endif; ?>
        </td>
        <td><?= h((string)$row['full_name']) ?></td>
        <td><?= h((string)$row['position_title']) ?></td>
        <td><span style="display:inline-block;width:24px;height:24px;border-radius:4px;background: <?= h(adminColorForPicker((string)($row['color_hex'] ?? ''), '#EEEEEE')) ?>;border:1px solid #ccc;"></span></td>
        <td><?= (int)$row['is_published'] === 1 ? 'Опубликован' : 'Скрыт' ?></td>
        <td><?= (int)$row['sort_order'] ?></td>
        <td>
          <a href="/admin/staff.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <button class="btn-ajax-move-up" data-id="<?= (int)$row['id'] ?>">Вверх</button>
          <button class="btn-ajax-move-down" data-id="<?= (int)$row['id'] ?>">Вниз</button>
          <button class="btn-ajax-toggle" data-id="<?= (int)$row['id'] ?>"><?= (int)$row['is_published'] === 1 ? 'Скрыть' : 'Показать' ?></button>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить сотрудника?')">Удалить</button>
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
<script src="/admin/assets/toast.js"></script>
<script src="/admin/assets/admin-ajax.js"></script>
<script>
(() => {
  const input = document.getElementById('staff_photo_file');
  const preview = document.getElementById('staff_crop_preview');
  const hidden = document.getElementById('staff_cropped_photo_data');
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
        aspectRatio: 1,
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
    const canvas = cropper.getCroppedCanvas({ width: 600, height: 600 });
    hidden.value = canvas.toDataURL('image/jpeg', 0.9);
  }
})();
</script>
<script>
(() => {
  const tbody = document.getElementById('staffSortableBody');
  const form = document.getElementById('staffReorderForm');
  const orderInput = document.getElementById('staffOrderJson');
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
  const search = document.getElementById('staffSearchInput');
  const status = document.getElementById('staffStatusFilter');
  const tbody = document.getElementById('staffSortableBody');
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
<script>
// AJAX обработчики для некритичных действий
(() => {
  const tbody = document.getElementById('staffSortableBody');
  if (!tbody) return;

  // Toggle publish
  tbody.querySelectorAll('.btn-ajax-toggle').forEach((btn) => {
    btn.addEventListener('click', async (e) => {
      e.preventDefault();
      const id = parseInt(btn.dataset.id, 10);
      const result = await AdminAjax.togglePublish('/admin/staff.php', id, 'Сотрудник');
      if (result.success) {
        // Обновляем текст кнопки и статус строки
        const row = btn.closest('tr');
        const statusCol = row.querySelector('td:nth-child(6)');
        const isPublished = result.is_published;
        statusCol.textContent = isPublished ? 'Опубликован' : 'Скрыт';
        btn.textContent = isPublished ? 'Скрыть' : 'Показать';
        row.dataset.status = isPublished ? 'published' : 'draft';
      }
    });
  });

  // Move up/down
  tbody.querySelectorAll('.btn-ajax-move-up, .btn-ajax-move-down').forEach((btn) => {
    btn.addEventListener('click', async (e) => {
      e.preventDefault();
      const id = parseInt(btn.dataset.id, 10);
      const isUp = btn.classList.contains('btn-ajax-move-up');
      const result = await AdminAjax.moveItem('/admin/staff.php', id, isUp ? 'up' : 'down');
      if (result.success) {
        // Переезагружаем страницу для обновления порядка
        setTimeout(() => location.reload(), 500);
      }
    });
  });
})();
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
