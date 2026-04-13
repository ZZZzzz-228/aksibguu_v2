<?php
require __DIR__ . '/_bootstrap.php';
$user = requireLogin();

function tableExists(PDO $pdo, string $name): bool
{
    try {
        $stmt = $pdo->query('SHOW TABLES LIKE ' . $pdo->quote($name));
        return (bool)$stmt->fetchColumn();
    } catch (Throwable $e) {
        return false;
    }
}

$appsTable = tableExists($pdo, 'applications');

$newApps = 0;
$studentsTotal = 0;
$newsPublished = 0;
$vacanciesActive = 0;

if ($appsTable) {
    $newApps = (int)$pdo->query('SELECT COUNT(*) FROM applications WHERE status = "new"')->fetchColumn();
}
$studentsTotal = (int)$pdo->query(
    "SELECT COUNT(DISTINCT u.id) FROM users u
     JOIN user_roles ur ON ur.user_id = u.id
     JOIN roles r ON r.id = ur.role_id AND r.code = 'student'"
)->fetchColumn();
$newsPublished = (int)$pdo->query('SELECT COUNT(*) FROM news_items WHERE is_published = 1')->fetchColumn();
$vacanciesActive = (int)$pdo->query('SELECT COUNT(*) FROM vacancies WHERE is_active = 1')->fetchColumn();

$chartDays = [];
$chartCounts = array_fill(0, 14, 0);
if ($appsTable) {
    for ($i = 13; $i >= 0; $i--) {
        $chartDays[] = date('Y-m-d', strtotime("-{$i} days"));
    }
    $from = $chartDays[0] . ' 00:00:00';
    $to = $chartDays[13] . ' 23:59:59';
    $stmt = $pdo->prepare(
        'SELECT DATE(created_at) AS d, COUNT(*) AS c FROM applications
         WHERE created_at >= :from AND created_at <= :to
         GROUP BY DATE(created_at)'
    );
    $stmt->execute(['from' => $from, 'to' => $to]);
    $byDay = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $r) {
        $byDay[(string)$r['d']] = (int)$r['c'];
    }
    foreach ($chartDays as $idx => $d) {
        $chartCounts[$idx] = $byDay[$d] ?? 0;
    }
}

$maxBar = max($chartCounts) ?: 1;

$lastApps = [];
if ($appsTable) {
    $specSel = applicationsHasColumn($pdo, 'specialty_text') ? 'specialty_text' : 'NULL AS specialty_text';
    $lastApps = $pdo->query(
        "SELECT id, full_name, phone, email, {$specSel}, status, created_at, type
         FROM applications ORDER BY id DESC LIMIT 6"
    )->fetchAll(PDO::FETCH_ASSOC);
}

$lastNews = $pdo->query(
    'SELECT id, title, published_at FROM news_items ORDER BY id DESC LIMIT 5'
)->fetchAll(PDO::FETCH_ASSOC);

function statusRu(string $s): string
{
    return match ($s) {
        'new' => 'Новая',
        'processing' => 'В работе',
        'approved' => 'Принята',
        'rejected' => 'Отклонена',
        default => $s,
    };
}

$title = 'Дашборд';
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?>
  <div class="flash"><?= h($msg) ?></div>
<?php endif; ?>

<div class="kpiGrid">
  <div class="kpiCard <?= $newApps > 5 ? 'alert' : '' ?>">
    <div class="kpiValue"><?= $newApps ?></div>
    <div class="kpiLabel">Новых заявок</div>
  </div>
  <div class="kpiCard">
    <div class="kpiValue"><?= $studentsTotal ?></div>
    <div class="kpiLabel">Студентов в системе</div>
  </div>
  <div class="kpiCard">
    <div class="kpiValue"><?= $newsPublished ?></div>
    <div class="kpiLabel">Опубликовано новостей</div>
  </div>
  <div class="kpiCard">
    <div class="kpiValue"><?= $vacanciesActive ?></div>
    <div class="kpiLabel">Активных вакансий</div>
  </div>
</div>

<div class="grid2">
  <div class="card">
    <h2>Заявки за 14 дней</h2>
    <?php if (!$appsTable): ?>
      <p class="muted">Таблица заявок не создана. Выполните миграцию <code>backend/database/migration_admin_panel_v2.sql</code>.</p>
    <?php else: ?>
      <div class="chart">
        <?php foreach ($chartDays as $i => $d): ?>
          <?php $h = (int)round(($chartCounts[$i] / $maxBar) * 120); ?>
          <div class="chartCol">
            <div class="chartBar" style="height: <?= max(4, $h) ?>px;" title="<?= h($d) ?>: <?= (int)$chartCounts[$i] ?>"></div>
            <div class="chartLbl"><?= h(substr($d, 5)) ?></div>
          </div>
        <?php endforeach; ?>
      </div>
    <?php endif; ?>
  </div>

  <div class="card">
    <h2>Быстрые действия</h2>
    <div class="quickActions">
      <a class="btn btnAccent" href="/admin/news.php">Добавить новость</a>
      <?php if (hasRole('admin')): ?>
        <a class="btn" href="/admin/students.php?create=1">Создать студента</a>
      <?php endif; ?>
      <a class="btn btnGhost" href="/admin/applications.php">Все заявки</a>
    </div>
    <p class="muted" style="margin-top:12px;">Вы вошли как <?= h($user['full_name']) ?> (<?= h(implode(', ', $user['roles'])) ?>).</p>
  </div>
</div>

<div class="grid2">
  <div class="card">
    <h2>Последние заявки</h2>
    <?php if (!$lastApps): ?>
      <p class="muted">Пока нет заявок.</p>
    <?php else: ?>
      <div class="tableWrap">
        <table>
          <thead>
          <tr><th>Дата</th><th>ФИО</th><th>Статус</th><th></th></tr>
          </thead>
          <tbody>
          <?php foreach ($lastApps as $a): ?>
            <tr>
              <td><?= h((string)$a['created_at']) ?></td>
              <td><?= h((string)$a['full_name']) ?></td>
              <td><span class="<?= $a['status'] === 'new' ? 'stNew' : ($a['status'] === 'processing' ? 'stProc' : ($a['status'] === 'approved' ? 'stOk' : 'stNo')) ?>"><?= h(statusRu((string)$a['status'])) ?></span></td>
              <td><a href="/admin/application_view.php?id=<?= (int)$a['id'] ?>">Открыть</a></td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    <?php endif; ?>
  </div>

  <div class="card">
    <h2>Последние новости</h2>
    <?php if (!$lastNews): ?>
      <p class="muted">Новостей нет.</p>
    <?php else: ?>
      <ul style="margin:0;padding-left:18px;">
        <?php foreach ($lastNews as $n): ?>
          <li style="margin-bottom:8px;">
            <a href="/admin/news.php?edit=<?= (int)$n['id'] ?>"><?= h((string)$n['title']) ?></a>
            <span class="muted"> — <?= h((string)($n['published_at'] ?? '')) ?></span>
          </li>
        <?php endforeach; ?>
      </ul>
    <?php endif; ?>
  </div>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
