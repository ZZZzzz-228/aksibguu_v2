<?php
// Скрипт для исправления порядка сортировки историй
// Удаляет дубликаты и переназначает sort_order

$config = require '../config.php';
$dbConfig = $config['db'];

$dsn = "mysql:host={$dbConfig['host']};port={$dbConfig['port']};dbname={$dbConfig['database']};charset={$dbConfig['charset']}";
$username = $dbConfig['username'];
$password = $dbConfig['password'];
$options = [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
];

try {
    $pdo = new PDO($dsn, $username, $password, $options);

    echo "Исправление порядка сортировки историй...\n\n";

    // Получить все истории, отсортированные по дате создания (старые сначала)
    $stmt = $pdo->query("
        SELECT id, title, sort_order, created_at
        FROM stories
        ORDER BY created_at ASC
    ");
    $stories = $stmt->fetchAll();

    echo "Найдено историй: " . count($stories) . "\n\n";

    // Обновить sort_order для каждой истории
    $newOrder = 0;
    foreach ($stories as $story) {
        $stmt = $pdo->prepare("UPDATE stories SET sort_order = ? WHERE id = ?");
        $stmt->execute([$newOrder, $story['id']]);

        echo "ID {$story['id']}: \"{$story['title']}\" -> порядок $newOrder\n";
        $newOrder++;
    }

    echo "\nПорядок сортировки исправлен!\n";

    // Проверить результат
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM stories");
    $total = $stmt->fetch()['total'];

    $stmt = $pdo->query("SELECT sort_order FROM stories ORDER BY sort_order ASC");
    $orders = $stmt->fetchAll(PDO::FETCH_COLUMN);

    $duplicates = array_diff_assoc($orders, array_unique($orders));
    if (!empty($duplicates)) {
        echo "ВНИМАНИЕ: Все еще есть дубликаты!\n";
    } else {
        echo "Все дубликаты устранены. Общее количество историй: $total\n";
    }

} catch (PDOException $e) {
    echo "Ошибка: " . $e->getMessage() . "\n";
}
?>