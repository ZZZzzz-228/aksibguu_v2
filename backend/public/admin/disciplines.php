<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAcademic()) {
    flash('Недостаточно прав для раздела учебной части.');
    redirectTo('/admin/index.php');
}

try {
    $pdo->query('SELECT 1 FROM disciplines_ref LIMIT 1');
} catch (Throwable $e) {
    flash('Таблица дисциплин не найдена. Выполните SQL из backend/database/migration_academic_process.sql');
    redirectTo('/admin/index.php');
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');

    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $codeRaw = trim((string)($_POST['code'] ?? ''));
        $code = $codeRaw !== '' ? $codeRaw : null;
        $titleValue = trim((string)($_POST['title'] ?? ''));
        $isActive = isset($_POST['is_active']) ? 1 : 0;

        if ($titleValue === '') {
            flash('Заполните название дисциплины.');
            redirectTo('/admin/disciplines.php');
        }
        if ($code !== null && strlen($code) > 64) {
            $code = substr($code, 0, 64);
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE disciplines_ref
                 SET code=:code, title=:title, is_active=:is_active
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'code' => $code,
                'title' => $titleValue,
                'is_active' => $isActive,
            ]);
            auditLog($pdo, 'update', 'discipline', (string)$id, ['code' => $code, 'title' => $titleValue, 'is_active' => $isActive]);
            flash('Дисциплина обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO disciplines_ref(code, title, is_active) VALUES (:code, :title, :is_active)'
            );
            $stmt->execute([
                'code' => $code,
                'title' => $titleValue,
                'is_active' => $isActive,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'discipline', (string)$newId, ['code' => $code, 'title' => $titleValue, 'is_active' => $isActive]);
            flash('Дисциплина добавлена.');
        }
        redirectTo('/admin/disciplines.php');
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/disciplines.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('DELETE FROM disciplines_ref WHERE id=:id')->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'discipline', (string)$id, null);
            flash('Дисциплина удалена.');
        }
        redirectTo('/admin/disciplines.php');
    }
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM disciplines_ref WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$q = trim((string)($_GET['q'] ?? ''));
$where = '1=1';
$params = [];
if ($q !== '') {
    $where = '(title LIKE :q OR code LIKE :q)';
    $params['q'] = '%' . $q . '%';
}

$stmt = $pdo->prepare("SELECT * FROM disciplines_ref WHERE $where ORDER BY is_active DESC, title ASC, id ASC");
$stmt->execute($params);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$title = 'Дисциплины';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать дисциплину' : 'Добавить дисциплину' ?></h2>
  <form method="post">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">

    <label>Код (опционально)</label>
    <input name="code" value="<?= h((string)($editItem['code'] ?? '')) ?>" placeholder="Например: MATH-101">

    <label>Название</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>

    <label><input type="checkbox" name="is_active" <?= ($editItem === null || !empty($editItem['is_active'])) ? 'checked' : '' ?>> Активна</label>
    <br><br>
    <button type="submit">Сохранить</button>
    <?php if ($editItem): ?>
      <a class="btn btnGhost" href="/admin/disciplines.php">Отмена</a>
    <?php endif; ?>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список дисциплин</h2>
  <form method="get" class="filters" style="margin-bottom:12px;">
    <div class="field" style="min-width:260px;">
      <label>Поиск</label>
      <input type="search" name="q" value="<?= h($q) ?>" placeholder="Название или код">
    </div>
    <div class="field">
      <label>&nbsp;</label>
      <button type="submit">Найти</button>
    </div>
    <?php if ($q !== ''): ?>
      <div class="field">
        <label>&nbsp;</label>
        <a class="btn btnGhost" href="/admin/disciplines.php">Сбросить</a>
      </div>
    <?php endif; ?>
  </form>
  <div class="tableWrap">
    <table>
      <thead>
      <tr>
        <th>ID</th>
        <th>Код</th>
        <th>Название</th>
        <th>Статус</th>
        <th>Действия</th>
      </tr>
      </thead>
      <tbody>
      <?php foreach ($rows as $row): ?>
        <tr>
          <td><?= (int)$row['id'] ?></td>
          <td><?= h((string)($row['code'] ?? '')) ?></td>
          <td><?= h((string)$row['title']) ?></td>
          <td><?= !empty($row['is_active']) ? 'Активна' : 'Скрыта' ?></td>
          <td style="white-space:nowrap;">
            <a href="/admin/disciplines.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
            <?php if ($canDelete): ?>
              <form method="post" style="display:inline;" onsubmit="return confirm('Удалить дисциплину?');">
                <?= csrfField() ?>
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
                <button class="danger" type="submit">Удалить</button>
              </form>
            <?php endif; ?>
          </td>
        </tr>
      <?php endforeach; ?>
      </tbody>
    </table>
  </div>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>

