<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAcademic()) {
    flash('Недостаточно прав для раздела учебной части.');
    redirectTo('/admin/index.php');
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    flash('Не указана группа.');
    redirectTo('/admin/groups.php');
}

$groupStmt = $pdo->prepare(
    'SELECT g.*, s.title AS specialty_title, sm.full_name AS curator_name
     FROM groups_ref g
     LEFT JOIN specialties s ON s.id = g.specialty_id
     LEFT JOIN staff_members sm ON sm.id = g.curator_staff_id
     WHERE g.id = :id
     LIMIT 1'
);
$groupStmt->execute(['id' => $id]);
$group = $groupStmt->fetch(PDO::FETCH_ASSOC);
if (!$group) {
    flash('Группа не найдена.');
    redirectTo('/admin/groups.php');
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!isAdmin()) {
        flash('Массовые операции доступны только администратору.');
        redirectTo('/admin/group_view.php?id=' . $id);
    }
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');

    if ($action === 'bulk_move') {
        $toGroupId = (int)($_POST['to_group_id'] ?? 0);
        if ($toGroupId <= 0) {
            flash('Выберите целевую группу.');
            redirectTo('/admin/group_view.php?id=' . $id);
        }
        if ($toGroupId === $id) {
            flash('Целевая группа совпадает с текущей.');
            redirectTo('/admin/group_view.php?id=' . $id);
        }

        $mode = (string)($_POST['mode'] ?? 'selected');
        $userIds = [];

        if ($mode === 'all') {
            $allStmt = $pdo->prepare(
                'SELECT sp.user_id
                 FROM student_profiles sp
                 JOIN users u ON u.id = sp.user_id
                 WHERE sp.group_id = :gid'
            );
            $allStmt->execute(['gid' => $id]);
            $userIds = array_map('intval', $allStmt->fetchAll(PDO::FETCH_COLUMN));
        } else {
            $ids = $_POST['user_ids'] ?? [];
            if (!is_array($ids)) {
                $ids = [];
            }
            $userIds = array_values(array_filter(array_map('intval', $ids), static fn($x) => $x > 0));
        }

        if (!$userIds) {
            flash('Не выбраны студенты для перевода.');
            redirectTo('/admin/group_view.php?id=' . $id);
        }

        $pdo->beginTransaction();
        try {
            $in = implode(',', array_fill(0, count($userIds), '?'));
            $params = array_merge([$toGroupId, $id], $userIds);
            $stmt = $pdo->prepare(
                "UPDATE student_profiles
                 SET group_id = ?
                 WHERE group_id = ?
                   AND user_id IN ($in)"
            );
            $stmt->execute($params);
            $pdo->commit();
        } catch (Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        auditLog($pdo, 'bulk_move', 'group_students', (string)$id, [
            'from_group_id' => $id,
            'to_group_id' => $toGroupId,
            'count' => count($userIds),
            'mode' => $mode,
        ]);
        flash('Студенты переведены в другую группу.');
        redirectTo('/admin/group_view.php?id=' . $id);
    }
}

$groups = $pdo->query(
    'SELECT g.id, g.title, g.code, g.course_year, g.is_active, s.title AS specialty_title
     FROM groups_ref g
     LEFT JOIN specialties s ON s.id = g.specialty_id
     WHERE g.is_active = 1
     ORDER BY g.course_year ASC, g.title ASC, g.id ASC'
)->fetchAll(PDO::FETCH_ASSOC);

$studentsStmt = $pdo->prepare(
    'SELECT u.id, u.full_name, u.email, u.phone, u.is_active, sp.student_code
     FROM student_profiles sp
     JOIN users u ON u.id = sp.user_id
     WHERE sp.group_id = :gid
     ORDER BY u.full_name ASC, u.id ASC'
);
$studentsStmt->execute(['gid' => $id]);
$students = $studentsStmt->fetchAll(PDO::FETCH_ASSOC);

$title = 'Группа: ' . (string)$group['title'];
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <p><a href="/admin/groups.php" class="btn btnGhost">← К списку групп</a></p>
  <h2><?= h((string)$group['title']) ?> <?= !empty($group['code']) ? '(' . h((string)$group['code']) . ')' : '' ?></h2>
  <p class="muted">ID: <?= (int)$group['id'] ?> · <?= !empty($group['is_active']) ? 'Активная' : 'Скрытая' ?></p>
  <p><strong>Курс:</strong> <?= (int)($group['course_year'] ?? 1) ?></p>
  <p><strong>Год набора:</strong> <?= h((string)($group['admission_year'] ?? '—')) ?></p>
  <p><strong>Специальность:</strong> <?= h((string)($group['specialty_title'] ?? '—')) ?></p>
  <p><strong>Куратор:</strong> <?= h((string)($group['curator_name'] ?? '—')) ?></p>
  <p><a class="btn btnAccent" href="/admin/groups.php?edit=<?= (int)$group['id'] ?>">Редактировать группу</a></p>
</div>

<div class="card">
  <h2>Студенты (<?= count($students) ?>)</h2>
  <?php if (!$students): ?>
    <p class="muted">В группе пока нет студентов.</p>
  <?php else: ?>
    <div class="tableWrap">
      <table>
        <thead>
        <tr>
          <?php if (isAdmin()): ?><th style="width:36px;"><input type="checkbox" onclick="document.querySelectorAll('.stuChk').forEach(c=>c.checked=this.checked)"></th><?php endif; ?>
          <th>ФИО</th>
          <th>Зачётка</th>
          <th>Email</th>
          <th>Телефон</th>
          <th>Статус</th>
          <th>Профиль</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($students as $st): ?>
          <tr>
            <?php if (isAdmin()): ?>
              <td><input class="stuChk" type="checkbox" name="user_ids[]" form="bulkMoveForm" value="<?= (int)$st['id'] ?>"></td>
            <?php endif; ?>
            <td><?= h((string)$st['full_name']) ?></td>
            <td><?= h((string)($st['student_code'] ?? '')) ?></td>
            <td><?= h((string)$st['email']) ?></td>
            <td><?= h((string)($st['phone'] ?? '')) ?></td>
            <td><?= (int)$st['is_active'] === 1 ? 'Активен' : 'Отключён' ?></td>
            <td><a href="/admin/student_view.php?id=<?= (int)$st['id'] ?>">Открыть</a></td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>
</div>

<?php if (isAdmin()): ?>
  <div class="card">
    <h2>Массовый перевод студентов</h2>
    <p class="muted">Можно перевести выбранных студентов (чекбоксы) или всех студентов группы.</p>
    <form method="post" id="bulkMoveForm">
      <?= csrfField() ?>
      <input type="hidden" name="action" value="bulk_move">
      <div class="grid2">
        <div>
          <label>Режим</label>
          <select name="mode">
            <option value="selected">Только выбранные</option>
            <option value="all">Все студенты группы</option>
          </select>
        </div>
        <div>
          <label>Перевести в группу</label>
          <select name="to_group_id" required>
            <option value="">— выберите —</option>
            <?php foreach ($groups as $g): ?>
              <?php if ((int)$g['id'] === $id) { continue; } ?>
              <option value="<?= (int)$g['id'] ?>">
                <?= h((string)$g['title']) ?><?= !empty($g['code']) ? ' (' . h((string)$g['code']) . ')' : '' ?>
                <?= !empty($g['specialty_title']) ? ' — ' . h((string)$g['specialty_title']) : '' ?>
                <?= !empty($g['course_year']) ? ' · курс ' . (int)$g['course_year'] : '' ?>
              </option>
            <?php endforeach; ?>
          </select>
        </div>
      </div>
      <button type="submit" class="btn btnAccent" onclick="return confirm('Перевести студентов в выбранную группу?');">Перевести</button>
    </form>
  </div>
<?php endif; ?>

<?php require __DIR__ . '/_layout_bottom.php'; ?>

