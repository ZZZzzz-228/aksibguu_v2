<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAcademic()) {
    flash('Недостаточно прав для раздела учебной части.');
    redirectTo('/admin/index.php');
}

try {
    $pdo->query('SELECT 1 FROM specialty_curriculum LIMIT 1');
    $pdo->query('SELECT 1 FROM disciplines_ref LIMIT 1');
} catch (Throwable $e) {
    flash('Таблицы учебных планов не найдены. Выполните SQL из backend/database/migration_academic_process.sql');
    redirectTo('/admin/index.php');
}

$specialtyId = (int)($_GET['specialty_id'] ?? 0);
$semester = (int)($_GET['semester'] ?? 1);
if ($semester < 1 || $semester > 8) {
    $semester = 1;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');
    $specialtyIdPost = (int)($_POST['specialty_id'] ?? 0);
    $semesterPost = (int)($_POST['semester'] ?? 1);
    if ($semesterPost < 1 || $semesterPost > 8) {
        $semesterPost = 1;
    }
    if ($specialtyIdPost <= 0) {
        flash('Выберите специальность.');
        redirectTo('/admin/curriculum.php');
    }

    if ($action === 'add') {
        $disciplineId = (int)($_POST['discipline_id'] ?? 0);
        if ($disciplineId <= 0) {
            flash('Выберите дисциплину.');
            redirectTo('/admin/curriculum.php?' . http_build_query(['specialty_id' => $specialtyIdPost, 'semester' => $semesterPost]));
        }

        $stmtMax = $pdo->prepare(
            'SELECT COALESCE(MAX(sort_order), -1) FROM specialty_curriculum WHERE specialty_id=:sid AND semester=:sem'
        );
        $stmtMax->execute(['sid' => $specialtyIdPost, 'sem' => $semesterPost]);
        $nextSort = ((int)$stmtMax->fetchColumn()) + 1;

        try {
            $stmt = $pdo->prepare(
                'INSERT INTO specialty_curriculum(specialty_id, semester, discipline_id, sort_order)
                 VALUES (:sid, :sem, :did, :so)'
            );
            $stmt->execute(['sid' => $specialtyIdPost, 'sem' => $semesterPost, 'did' => $disciplineId, 'so' => $nextSort]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'curriculum_item', (string)$newId, [
                'specialty_id' => $specialtyIdPost,
                'semester' => $semesterPost,
                'discipline_id' => $disciplineId,
                'sort_order' => $nextSort,
            ]);
            flash('Дисциплина добавлена в семестр.');
        } catch (Throwable $e) {
            flash('Не удалось добавить (возможно, уже добавлена).');
        }
        redirectTo('/admin/curriculum.php?' . http_build_query(['specialty_id' => $specialtyIdPost, 'semester' => $semesterPost]));
    }

    if ($action === 'remove') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $pdo->prepare('DELETE FROM specialty_curriculum WHERE id=:id')->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'curriculum_item', (string)$id, null);
            flash('Удалено.');
        }
        redirectTo('/admin/curriculum.php?' . http_build_query(['specialty_id' => $specialtyIdPost, 'semester' => $semesterPost]));
    }

    if ($action === 'move_up' || $action === 'move_down') {
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $delta = $action === 'move_up' ? -1 : 1;
            $stmt = $pdo->prepare(
                'UPDATE specialty_curriculum
                 SET sort_order = GREATEST(0, sort_order + :d)
                 WHERE id=:id'
            );
            $stmt->execute(['d' => $delta, 'id' => $id]);
            auditLog($pdo, $action, 'curriculum_item', (string)$id, ['delta' => $delta]);
        }
        redirectTo('/admin/curriculum.php?' . http_build_query(['specialty_id' => $specialtyIdPost, 'semester' => $semesterPost]));
    }

    redirectTo('/admin/curriculum.php?' . http_build_query(['specialty_id' => $specialtyIdPost, 'semester' => $semesterPost]));
}

$specialties = $pdo->query('SELECT id, code, title FROM specialties ORDER BY sort_order ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);
if ($specialtyId <= 0 && $specialties) {
    $specialtyId = (int)$specialties[0]['id'];
}

$disciplines = $pdo->query('SELECT id, code, title FROM disciplines_ref WHERE is_active = 1 ORDER BY title ASC, id ASC')->fetchAll(PDO::FETCH_ASSOC);

$items = [];
if ($specialtyId > 0) {
    $stmt = $pdo->prepare(
        'SELECT sc.id, sc.sort_order, d.id AS discipline_id, d.code, d.title
         FROM specialty_curriculum sc
         JOIN disciplines_ref d ON d.id = sc.discipline_id
         WHERE sc.specialty_id = :sid AND sc.semester = :sem
         ORDER BY sc.sort_order ASC, sc.id ASC'
    );
    $stmt->execute(['sid' => $specialtyId, 'sem' => $semester]);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);
}

$title = 'Учебные планы';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;">Выбор</h2>
  <form method="get" class="filters">
    <div class="field" style="min-width:320px;">
      <label>Специальность</label>
      <select name="specialty_id">
        <?php foreach ($specialties as $sp): ?>
          <option value="<?= (int)$sp['id'] ?>" <?= (int)$sp['id'] === $specialtyId ? 'selected' : '' ?>>
            <?= h((string)$sp['title']) ?><?= !empty($sp['code']) ? ' (' . h((string)$sp['code']) . ')' : '' ?>
          </option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="field">
      <label>Семестр</label>
      <select name="semester">
        <?php for ($i = 1; $i <= 8; $i++): ?>
          <option value="<?= $i ?>" <?= $i === $semester ? 'selected' : '' ?>><?= $i ?></option>
        <?php endfor; ?>
      </select>
    </div>
    <div class="field">
      <label>&nbsp;</label>
      <button type="submit">Открыть</button>
    </div>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Дисциплины семестра <?= (int)$semester ?></h2>
  <?php if ($specialtyId <= 0): ?>
    <p class="muted">Сначала выберите специальность.</p>
  <?php else: ?>
    <form method="post" class="filters" style="margin-bottom:10px;">
      <?= csrfField() ?>
      <input type="hidden" name="action" value="add">
      <input type="hidden" name="specialty_id" value="<?= (int)$specialtyId ?>">
      <input type="hidden" name="semester" value="<?= (int)$semester ?>">
      <div class="field" style="min-width:360px;">
        <label>Добавить дисциплину</label>
        <select name="discipline_id" required>
          <option value="">— выберите —</option>
          <?php foreach ($disciplines as $d): ?>
            <option value="<?= (int)$d['id'] ?>">
              <?= h((string)$d['title']) ?><?= !empty($d['code']) ? ' (' . h((string)$d['code']) . ')' : '' ?>
            </option>
          <?php endforeach; ?>
        </select>
      </div>
      <div class="field">
        <label>&nbsp;</label>
        <button type="submit" class="btn btnAccent">Добавить</button>
      </div>
    </form>

    <?php if (!$items): ?>
      <p class="muted">Пока пусто.</p>
    <?php else: ?>
      <div class="tableWrap">
        <table>
          <thead>
          <tr>
            <th>Порядок</th>
            <th>Дисциплина</th>
            <th>Код</th>
            <th>Действия</th>
          </tr>
          </thead>
          <tbody>
          <?php foreach ($items as $it): ?>
            <tr>
              <td><?= (int)$it['sort_order'] ?></td>
              <td><?= h((string)$it['title']) ?></td>
              <td><?= h((string)($it['code'] ?? '')) ?></td>
              <td style="white-space:nowrap;">
                <form method="post" style="display:inline;">
                  <?= csrfField() ?>
                  <input type="hidden" name="specialty_id" value="<?= (int)$specialtyId ?>">
                  <input type="hidden" name="semester" value="<?= (int)$semester ?>">
                  <input type="hidden" name="id" value="<?= (int)$it['id'] ?>">
                  <input type="hidden" name="action" value="move_up">
                  <button type="submit">Вверх</button>
                </form>
                <form method="post" style="display:inline;">
                  <?= csrfField() ?>
                  <input type="hidden" name="specialty_id" value="<?= (int)$specialtyId ?>">
                  <input type="hidden" name="semester" value="<?= (int)$semester ?>">
                  <input type="hidden" name="id" value="<?= (int)$it['id'] ?>">
                  <input type="hidden" name="action" value="move_down">
                  <button type="submit">Вниз</button>
                </form>
                <form method="post" style="display:inline;" onsubmit="return confirm('Удалить из семестра?');">
                  <?= csrfField() ?>
                  <input type="hidden" name="specialty_id" value="<?= (int)$specialtyId ?>">
                  <input type="hidden" name="semester" value="<?= (int)$semester ?>">
                  <input type="hidden" name="id" value="<?= (int)$it['id'] ?>">
                  <input type="hidden" name="action" value="remove">
                  <button class="danger" type="submit">Удалить</button>
                </form>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    <?php endif; ?>
  <?php endif; ?>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>

