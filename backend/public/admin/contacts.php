<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $type = trim((string)($_POST['type'] ?? ''));
        $value = trim((string)($_POST['value'] ?? ''));
        $label = trim((string)($_POST['label'] ?? ''));
        $sortOrder = (int)($_POST['sort_order'] ?? 0);
        $isActive = isset($_POST['is_active']) ? 1 : 0;

        if (!in_array($type, ['phone', 'email', 'website'], true) || $value === '') {
            flash('Укажите тип и значение контакта.');
            redirectTo('/admin/contacts.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE contacts
                 SET type=:type, value=:value, label=:label, sort_order=:sort_order, is_active=:is_active
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'type' => $type,
                'value' => $value,
                'label' => $label !== '' ? $label : null,
                'sort_order' => $sortOrder,
                'is_active' => $isActive,
            ]);
            auditLog($pdo, 'update', 'contact', (string)$id, [
                'type' => $type,
                'value' => $value,
                'is_active' => $isActive,
            ]);
            flash('Контакт обновлен.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO contacts(type, value, label, sort_order, is_active)
                 VALUES (:type, :value, :label, :sort_order, :is_active)'
            );
            $stmt->execute([
                'type' => $type,
                'value' => $value,
                'label' => $label !== '' ? $label : null,
                'sort_order' => $sortOrder,
                'is_active' => $isActive,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'contact', (string)$newId, [
                'type' => $type,
                'value' => $value,
                'is_active' => $isActive,
            ]);
            flash('Контакт добавлен.');
        }
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/contacts.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM contacts WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'contact', (string)$id, null);
            flash('Контакт удален.');
        }
    }
    redirectTo('/admin/contacts.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM contacts WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$rows = $pdo->query('SELECT * FROM contacts ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);
$title = 'Управление контактами';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать контакт' : 'Добавить контакт' ?></h2>
  <form method="post">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Тип</label>
    <select name="type" style="width:100%;padding:10px;border:1px solid #d1d5db;border-radius:8px;margin-top:6px;margin-bottom:10px;">
      <?php $selectedType = (string)($editItem['type'] ?? 'phone'); ?>
      <option value="phone" <?= $selectedType === 'phone' ? 'selected' : '' ?>>phone</option>
      <option value="email" <?= $selectedType === 'email' ? 'selected' : '' ?>>email</option>
      <option value="website" <?= $selectedType === 'website' ? 'selected' : '' ?>>website</option>
    </select>
    <label>Значение</label>
    <input name="value" value="<?= h((string)($editItem['value'] ?? '')) ?>" required>
    <label>Подпись (label)</label>
    <input name="label" value="<?= h((string)($editItem['label'] ?? '')) ?>">
    <label>Порядок</label>
    <input name="sort_order" type="number" value="<?= (int)($editItem['sort_order'] ?? 0) ?>">
    <label><input type="checkbox" name="is_active" <?= !empty($editItem['is_active']) ? 'checked' : '' ?>> Активен</label>
    <br><br><button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список контактов</h2>
  <table>
    <thead><tr><th>ID</th><th>Тип</th><th>Значение</th><th>Label</th><th>Порядок</th><th>Статус</th><th>Действия</th></tr></thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['type']) ?></td>
        <td><?= h((string)$row['value']) ?></td>
        <td><?= h((string)($row['label'] ?? '')) ?></td>
        <td><?= (int)$row['sort_order'] ?></td>
        <td><?= (int)$row['is_active'] === 1 ? 'Активен' : 'Скрыт' ?></td>
        <td>
          <a href="/admin/contacts.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить контакт?')">Удалить</button>
            </form>
          <?php endif; ?>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
