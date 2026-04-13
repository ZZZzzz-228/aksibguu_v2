<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAcademic()) {
    flash('Недостаточно прав для раздела учебной части.');
    redirectTo('/admin/index.php');
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');

    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $code = trim((string)($_POST['code'] ?? ''));
        $titleValue = trim((string)($_POST['title'] ?? ''));
        $specialtyId = (int)($_POST['specialty_id'] ?? 0);
        $curatorStaffId = (int)($_POST['curator_staff_id'] ?? 0);
        $courseYear = (int)($_POST['course_year'] ?? 1);
        $admissionYearRaw = trim((string)($_POST['admission_year'] ?? ''));
        $admissionYear = $admissionYearRaw !== '' ? (int)$admissionYearRaw : null;
        $isActive = isset($_POST['is_active']) ? 1 : 0;

        if ($code === '' || $titleValue === '') {
            flash('Заполните code и title.');
            redirectTo('/admin/groups.php');
        }
        if ($courseYear < 1 || $courseYear > 6) {
            $courseYear = 1;
        }
        if ($admissionYear !== null && ($admissionYear < 2000 || $admissionYear > 2100)) {
            $admissionYear = null;
        }

        $curatorStaffId = $curatorStaffId > 0 ? $curatorStaffId : null;
        $specialtyId = $specialtyId > 0 ? $specialtyId : null;

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE groups_ref
                 SET code=:code, title=:title, curator_staff_id=:curator_staff_id, specialty_id=:specialty_id,
                     course_year=:course_year, admission_year=:admission_year, is_active=:is_active
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'code' => $code,
                'title' => $titleValue,
                'curator_staff_id' => $curatorStaffId,
                'specialty_id' => $specialtyId,
                'course_year' => $courseYear,
                'admission_year' => $admissionYear,
                'is_active' => $isActive,
            ]);
            auditLog($pdo, 'update', 'group', (string)$id, [
                'code' => $code,
                'title' => $titleValue,
                'specialty_id' => $specialtyId,
                'curator_staff_id' => $curatorStaffId,
                'course_year' => $courseYear,
                'admission_year' => $admissionYear,
                'is_active' => $isActive,
            ]);
            flash('Группа обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO groups_ref(code, title, curator_staff_id, specialty_id, course_year, admission_year, is_active)
                 VALUES (:code, :title, :curator_staff_id, :specialty_id, :course_year, :admission_year, :is_active)'
            );
            $stmt->execute([
                'code' => $code,
                'title' => $titleValue,
                'curator_staff_id' => $curatorStaffId,
                'specialty_id' => $specialtyId,
                'course_year' => $courseYear,
                'admission_year' => $admissionYear,
                'is_active' => $isActive,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'group', (string)$newId, [
                'code' => $code,
                'title' => $titleValue,
            ]);
            flash('Группа добавлена.');
        }
        redirectTo('/admin/groups.php');
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/groups.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('DELETE FROM groups_ref WHERE id=:id')->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'group', (string)$id, null);
            flash('Группа удалена.');
        }
        redirectTo('/admin/groups.php');
    }
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM groups_ref WHERE id = :id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$specialties = $pdo->query('SELECT id, code, title FROM specialties ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);
$staff = $pdo->query('SELECT id, full_name, position_title FROM staff_members ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);

$rows = $pdo->query(
    'SELECT g.id, g.code, g.title, g.is_active, g.course_year, g.admission_year,
            g.specialty_id, s.title AS specialty_title,
            g.curator_staff_id, sm.full_name AS curator_name
     FROM groups_ref g
     LEFT JOIN specialties s ON s.id = g.specialty_id
     LEFT JOIN staff_members sm ON sm.id = g.curator_staff_id
     ORDER BY g.is_active DESC, g.course_year ASC, g.title ASC, g.id ASC'
)->fetchAll(PDO::FETCH_ASSOC);

$title = 'Академические группы';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать группу' : 'Добавить группу' ?></h2>
  <form method="post">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">

    <label>Код (например, ИС-11)</label>
    <input name="code" value="<?= h((string)($editItem['code'] ?? '')) ?>" required>

    <label>Название (полное)</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>

    <div class="grid2">
      <div>
        <label>Специальность</label>
        <select name="specialty_id">
          <option value="0">— не выбрано —</option>
          <?php foreach ($specialties as $sp): ?>
            <option value="<?= (int)$sp['id'] ?>" <?= (int)($editItem['specialty_id'] ?? 0) === (int)$sp['id'] ? 'selected' : '' ?>>
              <?= h((string)$sp['title']) ?><?= !empty($sp['code']) ? ' (' . h((string)$sp['code']) . ')' : '' ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>
      <div>
        <label>Куратор (сотрудник)</label>
        <select name="curator_staff_id">
          <option value="0">— не назначен —</option>
          <?php foreach ($staff as $st): ?>
            <option value="<?= (int)$st['id'] ?>" <?= (int)($editItem['curator_staff_id'] ?? 0) === (int)$st['id'] ? 'selected' : '' ?>>
              <?= h((string)$st['full_name']) ?><?= !empty($st['position_title']) ? ' — ' . h((string)$st['position_title']) : '' ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>
    </div>

    <div class="grid2">
      <div>
        <label>Курс (1–6)</label>
        <input name="course_year" type="number" min="1" max="6" value="<?= (int)($editItem['course_year'] ?? 1) ?>">
      </div>
      <div>
        <label>Год набора (опционально)</label>
        <input name="admission_year" type="number" min="2000" max="2100" value="<?= h((string)($editItem['admission_year'] ?? '')) ?>">
      </div>
    </div>

    <label><input type="checkbox" name="is_active" <?= ($editItem === null || !empty($editItem['is_active'])) ? 'checked' : '' ?>> Активная группа</label>
    <br><br>
    <button type="submit">Сохранить</button>
    <?php if ($editItem): ?>
      <a class="btn btnGhost" href="/admin/groups.php">Отмена</a>
      <a class="btn btnAccent" href="/admin/group_view.php?id=<?= (int)$editItem['id'] ?>">Открыть карточку</a>
    <?php endif; ?>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список групп</h2>
  <p class="muted">Нажмите «Карточка», чтобы увидеть студентов и массовые операции.</p>
  <div class="tableWrap">
    <table>
      <thead>
      <tr>
        <th>ID</th>
        <th>Код</th>
        <th>Название</th>
        <th>Курс</th>
        <th>Год набора</th>
        <th>Специальность</th>
        <th>Куратор</th>
        <th>Статус</th>
        <th>Действия</th>
      </tr>
      </thead>
      <tbody>
      <?php foreach ($rows as $row): ?>
        <tr>
          <td><?= (int)$row['id'] ?></td>
          <td><?= h((string)$row['code']) ?></td>
          <td><?= h((string)$row['title']) ?></td>
          <td><?= (int)($row['course_year'] ?? 1) ?></td>
          <td><?= h((string)($row['admission_year'] ?? '')) ?></td>
          <td><?= h((string)($row['specialty_title'] ?? '')) ?></td>
          <td><?= h((string)($row['curator_name'] ?? '')) ?></td>
          <td><?= !empty($row['is_active']) ? 'Активна' : 'Скрыта' ?></td>
          <td style="white-space:nowrap;">
            <a href="/admin/group_view.php?id=<?= (int)$row['id'] ?>">Карточка</a>
            <span class="muted"> · </span>
            <a href="/admin/groups.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
            <?php if ($canDelete): ?>
              <form method="post" style="display:inline;" onsubmit="return confirm('Удалить группу? Студенты останутся без группы.');">
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

