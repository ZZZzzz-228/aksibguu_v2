<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageContent()) {
    flash('Недостаточно прав для раздела контента.');
    redirectTo('/admin/index.php');
}

function guestHomeDefaultBlocks(): array
{
    return [
        ['key' => 'stories', 'title' => 'Истории', 'enabled' => true, 'sort_order' => 0],
        ['key' => 'news', 'title' => 'Новости', 'enabled' => true, 'sort_order' => 1],
        ['key' => 'specialties', 'title' => 'Специальности', 'enabled' => true, 'sort_order' => 2],
        ['key' => 'career_guidance', 'title' => 'Профориентация', 'enabled' => true, 'sort_order' => 3],
        ['key' => 'about_college', 'title' => 'О колледже', 'enabled' => true, 'sort_order' => 4],
        ['key' => 'contacts', 'title' => 'Контакты', 'enabled' => true, 'sort_order' => 5],
    ];
}

function guestHomeReadBlocks(PDO $pdo): array
{
    $raw = siteSetting($pdo, 'guest_home_blocks_json', '');
    if (!is_string($raw) || $raw === '') {
        return guestHomeDefaultBlocks();
    }
    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        return guestHomeDefaultBlocks();
    }
    return $decoded;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    requireCsrf();
    $action = (string)($_POST['action'] ?? '');
    if ($action === 'save_blocks') {
        $json = (string)($_POST['blocks_json'] ?? '[]');
        $decoded = json_decode($json, true);
        if (!is_array($decoded)) {
            flash('Некорректный формат блоков.');
            redirectTo('/admin/guest_home.php');
        }
        $normalized = [];
        $i = 0;
        foreach ($decoded as $item) {
            if (!is_array($item)) {
                continue;
            }
            $key = trim((string)($item['key'] ?? ''));
            $title = trim((string)($item['title'] ?? ''));
            if ($key === '' || $title === '') {
                continue;
            }
            $normalized[] = [
                'key' => $key,
                'title' => $title,
                'enabled' => !empty($item['enabled']),
                'sort_order' => $i++,
            ];
        }
        if (!$normalized) {
            flash('Список блоков пуст.');
            redirectTo('/admin/guest_home.php');
        }
        siteSettingSet($pdo, 'guest_home_blocks_json', json_encode($normalized, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
        auditLog($pdo, 'update', 'guest_home_blocks', 'guest_home', ['count' => count($normalized)]);
        flash('Порядок блоков главной сохранён.');
        redirectTo('/admin/guest_home.php');
    }
}

$blocks = guestHomeReadBlocks($pdo);

$title = 'Главная (гость) — блоки';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2>Конструктор блоков главной</h2>
  <p class="muted">Перетаскивайте блоки и включайте/выключайте их отображение на гостевом экране.</p>

  <form method="post" id="guestHomeForm">
    <?= csrfField() ?>
    <input type="hidden" name="action" value="save_blocks">
    <input type="hidden" name="blocks_json" id="blocksJson">

    <div class="tableWrap">
      <table>
        <thead>
        <tr>
          <th style="width:60px;">#</th>
          <th>Ключ</th>
          <th>Название</th>
          <th>Включен</th>
        </tr>
        </thead>
        <tbody id="guestBlocksBody">
        <?php foreach ($blocks as $idx => $b): ?>
          <tr draggable="true" data-key="<?= h((string)$b['key']) ?>" data-title="<?= h((string)$b['title']) ?>">
            <td><?= $idx + 1 ?></td>
            <td><?= h((string)$b['key']) ?></td>
            <td><?= h((string)$b['title']) ?></td>
            <td><input type="checkbox" class="blockEnabled" <?= !empty($b['enabled']) ? 'checked' : '' ?>></td>
          </tr>
        <?php endforeach; ?>
        </tbody>
      </table>
    </div>

    <div style="margin-top:12px;">
      <button type="submit" class="btn btnAccent">Сохранить порядок и видимость</button>
    </div>
  </form>
</div>

<script>
(() => {
  const tbody = document.getElementById('guestBlocksBody');
  const form = document.getElementById('guestHomeForm');
  const output = document.getElementById('blocksJson');
  if (!tbody || !form || !output) return;

  let dragRow = null;
  tbody.querySelectorAll('tr[draggable="true"]').forEach((row) => {
    row.addEventListener('dragstart', () => { dragRow = row; row.style.opacity = '0.5'; });
    row.addEventListener('dragend', () => { row.style.opacity = ''; dragRow = null; });
    row.addEventListener('dragover', (e) => e.preventDefault());
    row.addEventListener('drop', (e) => {
      e.preventDefault();
      if (!dragRow || dragRow === row) return;
      const rows = Array.from(tbody.querySelectorAll('tr[draggable="true"]'));
      const dragIndex = rows.indexOf(dragRow);
      const dropIndex = rows.indexOf(row);
      if (dragIndex < dropIndex) row.after(dragRow); else row.before(dragRow);
      renumber();
    });
  });

  function renumber() {
    Array.from(tbody.querySelectorAll('tr')).forEach((row, i) => {
      const firstCell = row.querySelector('td');
      if (firstCell) firstCell.textContent = String(i + 1);
    });
  }

  form.addEventListener('submit', () => {
    const payload = Array.from(tbody.querySelectorAll('tr')).map((row, i) => ({
      key: row.dataset.key || '',
      title: row.dataset.title || '',
      enabled: !!row.querySelector('.blockEnabled:checked'),
      sort_order: i,
    }));
    output.value = JSON.stringify(payload);
  });
})();
</script>

<?php require __DIR__ . '/_layout_bottom.php'; ?>

