<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAdmissions()) {
    flash('Недостаточно прав для раздела заявок.');
    redirectTo('/admin/index.php');
}

try {
    $pdo->query('SELECT 1 FROM applications LIMIT 1');
} catch (Throwable $e) {
    flash('Таблица заявок не найдена. Выполните SQL из backend/database/migration_admin_panel_v2.sql');
    redirectTo('/admin/index.php');
}

$hasSpecialtyTextCol = applicationsHasColumn($pdo, 'specialty_text');

function appStatusRu(string $s): string
{
    return match ($s) {
        'new' => 'Новая',
        'processing' => 'В работе',
        'approved' => 'Принята',
        'rejected' => 'Отклонена',
        'archived' => 'Архив',
        default => $s,
    };
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');
    if ($action === 'bulk_processing') {
        $ids = $_POST['ids'] ?? [];
        if (!is_array($ids)) {
            $ids = [];
        }
        $ids = array_values(array_filter(array_map('intval', $ids), static fn($x) => $x > 0));
        if ($ids) {
            $in = implode(',', $ids);
            $pdo->exec('UPDATE applications SET status = "processing" WHERE id IN (' . $in . ') AND status = "new"');
            auditLog($pdo, 'bulk_processing', 'application', implode(',', $ids), ['count' => count($ids)]);
            flash('Выбранные заявки переведены в работу.');
        }
        redirectTo('/admin/applications.php');
    }
    if ($action === 'set_status') {
        $id = (int)($_POST['id'] ?? 0);
        $newStatus = (string)($_POST['new_status'] ?? '');
        $allowed = ['processing', 'archived', 'new'];
        if ($id > 0 && in_array($newStatus, $allowed, true)) {
            $stmt = $pdo->prepare('UPDATE applications SET status = :status WHERE id = :id');
            $stmt->execute(['status' => $newStatus, 'id' => $id]);
            auditLog($pdo, 'set_status_quick', 'application', (string)$id, ['status' => $newStatus]);
            flash('Статус обновлён.');
        }
        redirectTo('/admin/applications.php');
    }
    if ($action === 'delete_one') {
        if (!isAdmin()) {
            flash('Удаление заявок доступно только администратору.');
            redirectTo('/admin/applications.php');
        }
        $deleteId = (int)($_POST['delete_id'] ?? 0);
        if ($deleteId > 0) {
            $pdo->prepare('DELETE FROM applications WHERE id = :id')->execute(['id' => $deleteId]);
            auditLog($pdo, 'delete', 'application', (string)$deleteId, null);
            flash('Заявка удалена.');
        }
        redirectTo('/admin/applications.php');
    }
}

$status = trim((string)($_GET['status'] ?? ''));
$type = trim((string)($_GET['type'] ?? ''));
$spec = trim((string)($_GET['specialty'] ?? ''));
$q = trim((string)($_GET['q'] ?? ''));
$dateFrom = trim((string)($_GET['date_from'] ?? ''));
$dateTo = trim((string)($_GET['date_to'] ?? ''));
$sort = trim((string)($_GET['sort'] ?? 'created_at'));
$dir = strtolower(trim((string)($_GET['dir'] ?? 'desc'))) === 'asc' ? 'ASC' : 'DESC';
$page = max(1, (int)($_GET['page'] ?? 1));
$perPage = (int)($_GET['per_page'] ?? 25);
if (!in_array($perPage, [20, 25, 50], true)) {
    $perPage = 25;
}

$allowedSort = ['created_at' => 'a.created_at', 'full_name' => 'a.full_name', 'status' => 'a.status'];
if (!isset($allowedSort[$sort])) {
    $sort = 'created_at';
}
$orderCol = $allowedSort[$sort];

$where = ['1=1'];
$params = [];

if ($type !== '' && in_array($type, ['documents', 'courses'], true)) {
    $where[] = 'a.type = :type';
    $params['type'] = $type;
}
if ($status !== '' && in_array($status, ['new', 'processing', 'approved', 'rejected'], true)) {
    $where[] = 'a.status = :status';
    $params['status'] = $status;
}
if ($status !== '' && in_array($status, ['archived'], true)) {
    $where[] = 'a.status = :status';
    $params['status'] = $status;
}
if ($spec !== '' && $hasSpecialtyTextCol) {
    $where[] = 'a.specialty_text LIKE :spec';
    $params['spec'] = '%' . $spec . '%';
}
if ($q !== '') {
    $where[] = '(a.full_name LIKE :q OR a.email LIKE :q OR a.phone LIKE :q)';
    $params['q'] = '%' . $q . '%';
}
if ($dateFrom !== '') {
    $where[] = 'a.created_at >= :df';
    $params['df'] = $dateFrom . ' 00:00:00';
}
if ($dateTo !== '') {
    $where[] = 'a.created_at <= :dt';
    $params['dt'] = $dateTo . ' 23:59:59';
}

$whereSql = implode(' AND ', $where);

$countStmt = $pdo->prepare("SELECT COUNT(*) FROM applications a WHERE $whereSql");
$countStmt->execute($params);
$total = (int)$countStmt->fetchColumn();
$pages = max(1, (int)ceil($total / $perPage));
if ($page > $pages) {
    $page = $pages;
}
$offset = ($page - 1) * $perPage;

$specColSql = $hasSpecialtyTextCol ? 'a.specialty_text' : 'NULL AS specialty_text';
$sql = "SELECT a.id, a.type, a.full_name, a.email, a.phone, {$specColSql}, a.status, a.created_at
        FROM applications a
        WHERE $whereSql
        ORDER BY $orderCol $dir, a.id DESC
        LIMIT :lim OFFSET :off";
$stmt = $pdo->prepare($sql);
foreach ($params as $k => $v) {
    $stmt->bindValue(':' . $k, $v);
}
$stmt->bindValue(':lim', $perPage, PDO::PARAM_INT);
$stmt->bindValue(':off', $offset, PDO::PARAM_INT);
$stmt->execute();
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$specOpts = [];
if ($hasSpecialtyTextCol) {
    $specOpts = $pdo->query(
        'SELECT DISTINCT specialty_text FROM applications WHERE specialty_text IS NOT NULL AND specialty_text != "" ORDER BY specialty_text ASC'
    )->fetchAll(PDO::FETCH_COLUMN);
}

$qsBase = $_GET;
unset($qsBase['page']);
$exportQs = http_build_query($qsBase);

$title = 'Заявки';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2>Фильтры и поиск</h2>
  <form method="get" class="filters">
    <div class="field">
      <label>Статус</label>
      <select name="status">
        <option value="">Все</option>
        <?php foreach (['new', 'processing', 'approved', 'rejected', 'archived'] as $st): ?>
          <option value="<?= h($st) ?>" <?= $status === $st ? 'selected' : '' ?>><?= h(appStatusRu($st)) ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="field">
      <label>Тип</label>
      <select name="type">
        <option value="">Все</option>
        <option value="documents" <?= $type === 'documents' ? 'selected' : '' ?>>Документы</option>
        <option value="courses" <?= $type === 'courses' ? 'selected' : '' ?>>Курсы</option>
      </select>
    </div>
    <div class="field">
      <label>Специальность</label>
      <select name="specialty">
        <option value="">Все</option>
        <?php foreach ($specOpts as $opt): ?>
          <?php if (!is_string($opt) || $opt === '') {
              continue;
          } ?>
          <option value="<?= h($opt) ?>" <?= $spec === $opt ? 'selected' : '' ?>><?= h($opt) ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="field">
      <label>Дата с</label>
      <input type="date" name="date_from" value="<?= h($dateFrom) ?>">
    </div>
    <div class="field">
      <label>Дата по</label>
      <input type="date" name="date_to" value="<?= h($dateTo) ?>">
    </div>
    <div class="field" style="min-width:200px;">
      <label>Поиск</label>
      <input type="search" name="q" value="<?= h($q) ?>" placeholder="ФИО, email, телефон">
    </div>
    <div class="field">
      <label>Сортировка</label>
      <select name="sort">
        <option value="created_at" <?= $sort === 'created_at' ? 'selected' : '' ?>>По дате</option>
        <option value="full_name" <?= $sort === 'full_name' ? 'selected' : '' ?>>По ФИО</option>
        <option value="status" <?= $sort === 'status' ? 'selected' : '' ?>>По статусу</option>
      </select>
    </div>
    <div class="field">
      <label>Порядок</label>
      <select name="dir">
        <option value="desc" <?= $dir === 'DESC' ? 'selected' : '' ?>>По убыванию</option>
        <option value="asc" <?= $dir === 'ASC' ? 'selected' : '' ?>>По возрастанию</option>
      </select>
    </div>
    <div class="field">
      <label>На странице</label>
      <select name="per_page">
        <?php foreach ([20, 25, 50] as $pp): ?>
          <option value="<?= $pp ?>" <?= $perPage === $pp ? 'selected' : '' ?>><?= $pp ?></option>
        <?php endforeach; ?>
      </select>
    </div>
    <div class="field">
      <label>&nbsp;</label>
      <button type="submit">Применить</button>
    </div>
    <div class="field">
      <label>&nbsp;</label>
      <a class="btn btnGhost" href="/admin/applications.php">Сбросить</a>
    </div>
    <div class="field">
      <label>&nbsp;</label>
      <a class="btn btnAccent" href="/admin/applications_export.php?<?= h($exportQs) ?>">Экспорт в CSV</a>
    </div>
  </form>
  <p class="muted">Всего: <?= $total ?>. Страница <?= $page ?> из <?= $pages ?>.</p>
</div>

<form method="post">
  <?= csrfField() ?>
  <input type="hidden" name="action" value="bulk_processing">
  <div class="card">
    <h2>Список заявок</h2>
    <p class="muted">Нажмите на строку, чтобы открыть карточку. Для массового перевода в работу отметьте «Новые» и нажмите кнопку.</p>
    <button type="submit" class="btn btnGhost" style="margin-bottom:10px;">Перевести выбранные в работу</button>
    <div class="tableWrap">
      <table>
        <thead>
        <tr>
          <th style="width:36px;"><input type="checkbox" onclick="document.querySelectorAll('.rowchk').forEach(c=>c.checked=this.checked)"></th>
          <th>Дата и время</th>
          <th>ФИО</th>
          <th>Телефон</th>
          <th>Email</th>
          <th>Специальность</th>
          <th>Статус</th>
          <th>Тип</th>
          <th>Действия</th>
        </tr>
        </thead>
        <tbody>
        <?php foreach ($rows as $row): ?>
          <tr class="clickRow" data-href="/admin/application_view.php?id=<?= (int)$row['id'] ?>">
            <td onclick="event.stopPropagation();">
              <?php if ($row['status'] === 'new'): ?>
                <input class="rowchk" type="checkbox" name="ids[]" value="<?= (int)$row['id'] ?>">
              <?php endif; ?>
            </td>
            <td><?= h((string)$row['created_at']) ?></td>
            <td><?= h((string)$row['full_name']) ?></td>
            <td><?= h((string)($row['phone'] ?? '')) ?></td>
            <td><?= h((string)($row['email'] ?? '')) ?></td>
            <td><?= h((string)($row['specialty_text'] ?? '')) ?></td>
            <td>
              <?php
                $cls = match ($row['status']) {
                    'new' => 'stNew',
                    'processing' => 'stProc',
                    'approved' => 'stOk',
                    'rejected' => 'stNo',
                    default => '',
                };
              ?>
              <span class="<?= h($cls) ?>"><?= h(appStatusRu((string)$row['status'])) ?></span>
            </td>
            <td><?= $row['type'] === 'courses' ? 'Курсы' : 'Документы' ?></td>
            <td onclick="event.stopPropagation();" style="white-space:nowrap;">
              <?php if ($row['status'] === 'new'): ?>
                <button type="submit" name="action" value="set_status" class="btn btnGhost" onclick="this.form.id.value='<?= (int)$row['id'] ?>'; this.form.new_status.value='processing';">В работу</button>
              <?php endif; ?>
              <?php if ($row['status'] !== 'archived'): ?>
                <button type="submit" name="action" value="set_status" class="btn btnGhost" onclick="this.form.id.value='<?= (int)$row['id'] ?>'; this.form.new_status.value='archived';">В архив</button>
              <?php else: ?>
                <button type="submit" name="action" value="set_status" class="btn btnGhost" onclick="this.form.id.value='<?= (int)$row['id'] ?>'; this.form.new_status.value='new';">Восстановить</button>
              <?php endif; ?>
              <?php if (hasRole('admin')): ?>
                <button
                  type="submit"
                  name="action"
                  value="delete_one"
                  class="danger"
                  onclick="this.form.delete_id.value='<?= (int)$row['id'] ?>'; return confirm('Удалить заявку #<?= (int)$row['id'] ?>?');"
                >
                  Удалить
                </button>
              <?php endif; ?>
            </td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>
    <input type="hidden" name="delete_id" value="">
    <input type="hidden" name="id" value="">
    <input type="hidden" name="new_status" value="">
  </div>
</form>

<?php if ($pages > 1): ?>
  <div class="card muted" style="display:flex;gap:12px;flex-wrap:wrap;align-items:center;">
    <?php
    $qsBase['page'] = max(1, $page - 1);
    $prev = '/admin/applications.php?' . http_build_query($qsBase);
    $qsBase['page'] = min($pages, $page + 1);
    $next = '/admin/applications.php?' . http_build_query($qsBase);
    ?>
    <?php if ($page > 1): ?><a class="btn btnGhost" href="<?= h($prev) ?>">← Назад</a><?php endif; ?>
    <?php if ($page < $pages): ?><a class="btn btnGhost" href="<?= h($next) ?>">Вперёд →</a><?php endif; ?>
  </div>
<?php endif; ?>

<script>
document.querySelectorAll('tr.clickRow').forEach(function(tr) {
  tr.addEventListener('click', function() {
    var href = tr.getAttribute('data-href');
    if (href) window.location.href = href;
  });
});
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
