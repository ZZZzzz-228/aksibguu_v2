<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireRole('admin');

$filters = [
    'user_id' => (int)($_GET['user_id'] ?? 0),
    'action' => trim((string)($_GET['action'] ?? '')),
    'entity' => trim((string)($_GET['entity'] ?? '')),
    'date_from' => trim((string)($_GET['date_from'] ?? '')),
    'date_to' => trim((string)($_GET['date_to'] ?? '')),
];

$where = [];
$params = [];

if ($filters['user_id'] > 0) {
    $where[] = 'a.user_id = :user_id';
    $params['user_id'] = $filters['user_id'];
}
if ($filters['action'] !== '') {
    $where[] = 'a.action = :action';
    $params['action'] = $filters['action'];
}
if ($filters['entity'] !== '') {
    $where[] = 'a.entity = :entity';
    $params['entity'] = $filters['entity'];
}
if ($filters['date_from'] !== '') {
    $where[] = 'a.created_at >= :date_from';
    $params['date_from'] = $filters['date_from'] . ' 00:00:00';
}
if ($filters['date_to'] !== '') {
    $where[] = 'a.created_at <= :date_to';
    $params['date_to'] = $filters['date_to'] . ' 23:59:59';
}

$sql = 'SELECT a.id, a.created_at, a.action, a.entity, a.entity_id, a.payload_json,
               u.full_name AS actor_name, u.email AS actor_email
        FROM audit_log a
        LEFT JOIN users u ON u.id = a.user_id';

if ($where) {
    $sql .= ' WHERE ' . implode(' AND ', $where);
}

$sql .= ' ORDER BY a.id DESC LIMIT 500';
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

$users = $pdo->query(
    'SELECT id, full_name, email
     FROM users
     ORDER BY full_name ASC, id ASC'
)->fetchAll(PDO::FETCH_ASSOC);

$actions = $pdo->query(
    'SELECT DISTINCT action
     FROM audit_log
     ORDER BY action ASC'
)->fetchAll(PDO::FETCH_COLUMN);

$entities = $pdo->query(
    'SELECT DISTINCT entity
     FROM audit_log
     ORDER BY entity ASC'
)->fetchAll(PDO::FETCH_COLUMN);

$title = 'Журнал аудита';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
?>

<div class="card">
  <h2 style="margin-top:0;">Журнал действий</h2>
  <p class="muted">До 500 последних событий с учетом фильтров.</p>
  <form method="get" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin:12px 0 14px;">
    <div>
      <label>Пользователь</label>
      <select name="user_id" style="width:100%;padding:10px;border:1px solid #d1d5db;border-radius:8px;">
        <option value="0">Все</option>
        <?php foreach ($users as $u): ?>
          <option value="<?= (int)$u['id'] ?>" <?= $filters['user_id'] === (int)$u['id'] ? 'selected' : '' ?>>
            <?= h((string)$u['full_name']) ?> (<?= h((string)$u['email']) ?>)
          </option>
        <?php endforeach; ?>
      </select>
    </div>
    <div>
      <label>Действие</label>
      <select name="action" style="width:100%;padding:10px;border:1px solid #d1d5db;border-radius:8px;">
        <option value="">Все</option>
        <?php foreach ($actions as $action): ?>
          <option value="<?= h((string)$action) ?>" <?= $filters['action'] === (string)$action ? 'selected' : '' ?>>
            <?= h((string)$action) ?>
          </option>
        <?php endforeach; ?>
      </select>
    </div>
    <div>
      <label>Сущность</label>
      <select name="entity" style="width:100%;padding:10px;border:1px solid #d1d5db;border-radius:8px;">
        <option value="">Все</option>
        <?php foreach ($entities as $entity): ?>
          <option value="<?= h((string)$entity) ?>" <?= $filters['entity'] === (string)$entity ? 'selected' : '' ?>>
            <?= h((string)$entity) ?>
          </option>
        <?php endforeach; ?>
      </select>
    </div>
    <div>
      <label>Дата от</label>
      <input type="date" name="date_from" value="<?= h($filters['date_from']) ?>">
    </div>
    <div>
      <label>Дата до</label>
      <input type="date" name="date_to" value="<?= h($filters['date_to']) ?>">
    </div>
    <div style="display:flex;align-items:end;gap:8px;">
      <button type="submit">Применить</button>
      <a href="/admin/audit.php" class="secondary" style="display:inline-block;padding:10px 12px;border:1px solid #d1d5db;border-radius:8px;text-decoration:none;">Сбросить</a>
    </div>
  </form>
  <table>
    <thead>
      <tr>
        <th>ID</th>
        <th>Когда</th>
        <th>Кто</th>
        <th>Действие</th>
        <th>Сущность</th>
        <th>Entity ID</th>
        <th>Payload</th>
      </tr>
    </thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['created_at']) ?></td>
        <td><?= h((string)($row['actor_name'] ?? 'system')) ?><br><span class="muted"><?= h((string)($row['actor_email'] ?? '')) ?></span></td>
        <td><?= h((string)$row['action']) ?></td>
        <td><?= h((string)$row['entity']) ?></td>
        <td><?= h((string)$row['entity_id']) ?></td>
        <td><pre style="white-space:pre-wrap;max-width:260px;"><?= h((string)($row['payload_json'] ?? '')) ?></pre></td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
