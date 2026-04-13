<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireRole('admin');

$tables = [
    'contacts',
    'vacancies',
    'staff_members',
    'news_items',
    'stories',
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    if ($action === 'export') {
        $payload = [
            'meta' => [
                'exported_at' => gmdate('c'),
                'source' => 'career-center-admin',
                'version' => 1,
            ],
            'tables' => [],
        ];
        foreach ($tables as $table) {
            $stmt = $pdo->query("SELECT * FROM {$table}");
            $payload['tables'][$table] = $stmt->fetchAll(PDO::FETCH_ASSOC);
        }

        $json = json_encode($payload, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        header('Content-Type: application/json; charset=utf-8');
        header('Content-Disposition: attachment; filename="content_backup_' . date('Ymd_His') . '.json"');
        echo $json;
        exit;
    }

    if ($action === 'import') {
        if (!isset($_FILES['backup_file']) || !is_array($_FILES['backup_file'])) {
            flash('Файл бэкапа не выбран.');
            redirectTo('/admin/backup.php');
        }
        $file = $_FILES['backup_file'];
        if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
            flash('Ошибка загрузки файла.');
            redirectTo('/admin/backup.php');
        }

        $tmp = (string)($file['tmp_name'] ?? '');
        $raw = @file_get_contents($tmp);
        if ($raw === false || $raw === '') {
            flash('Не удалось прочитать файл.');
            redirectTo('/admin/backup.php');
        }
        $decoded = json_decode($raw, true);
        if (!is_array($decoded) || !isset($decoded['tables']) || !is_array($decoded['tables'])) {
            flash('Неверный формат JSON бэкапа.');
            redirectTo('/admin/backup.php');
        }

        try {
            $pdo->beginTransaction();

            // Очистка только контент-таблиц (без users/roles)
            foreach (array_reverse($tables) as $table) {
                $pdo->exec("DELETE FROM {$table}");
            }

            foreach ($tables as $table) {
                $rows = $decoded['tables'][$table] ?? [];
                if (!is_array($rows) || count($rows) === 0) {
                    continue;
                }
                insertRows($pdo, $table, $rows);
            }

            $pdo->commit();
            flash('Бэкап успешно импортирован.');
        } catch (Throwable $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            flash('Ошибка импорта: ' . $e->getMessage());
        }

        redirectTo('/admin/backup.php');
    }
}

$title = 'Бэкап контента';
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;">Экспорт</h2>
  <p class="muted">Скачивает JSON со всеми контент-таблицами (contacts, vacancies, staff_members, news_items, stories).</p>
  <form method="post">
    <input type="hidden" name="action" value="export">
    <button type="submit">Скачать JSON бэкап</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Импорт</h2>
  <p class="muted">Внимание: импорт очистит текущие контент-таблицы и заменит данными из файла.</p>
  <form method="post" enctype="multipart/form-data" onsubmit="return confirm('Точно импортировать? Текущий контент будет перезаписан.');">
    <input type="hidden" name="action" value="import">
    <input type="file" name="backup_file" accept="application/json,.json" required>
    <button type="submit">Импортировать JSON</button>
  </form>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>

<?php
function insertRows(PDO $pdo, string $table, array $rows): void
{
    foreach ($rows as $row) {
        if (!is_array($row) || count($row) === 0) {
            continue;
        }
        $columns = array_keys($row);

        // При импорте новостей, если author_user_id не существует, null безопаснее.
        if ($table === 'news_items' && array_key_exists('author_user_id', $row)) {
            $authorId = (int)($row['author_user_id'] ?? 0);
            if ($authorId > 0) {
                $stmtAuthor = $pdo->prepare('SELECT id FROM users WHERE id=:id LIMIT 1');
                $stmtAuthor->execute(['id' => $authorId]);
                if (!$stmtAuthor->fetch(PDO::FETCH_ASSOC)) {
                    $row['author_user_id'] = null;
                }
            }
        }

        $placeholders = array_map(static fn(string $col) => ':' . $col, $columns);
        $sql = sprintf(
            'INSERT INTO %s (%s) VALUES (%s)',
            $table,
            implode(', ', $columns),
            implode(', ', $placeholders)
        );
        $stmt = $pdo->prepare($sql);
        $stmt->execute($row);
    }
}
