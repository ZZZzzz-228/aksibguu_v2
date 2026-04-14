<?php
// Тестовый скрипт для проверки API историй
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

    // Запрос аналогичный API
    $stmt = $pdo->query('SELECT id, title, content, image_url, sort_order FROM stories WHERE is_published = 1 ORDER BY sort_order ASC LIMIT 5');
    $stories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Первые 5 историй из API:\n";
    echo str_repeat("-", 50) . "\n";

    foreach($stories as $story) {
        echo "ID: {$story['id']}\n";
        echo "Название: {$story['title']}\n";
        echo "Порядок: {$story['sort_order']}\n";
        echo "Изображение: {$story['image_url']}\n";
        echo "Содержание: " . substr($story['content'], 0, 100) . "...\n";
        echo str_repeat("-", 50) . "\n";
    }

    // Общее количество
    $stmt = $pdo->query('SELECT COUNT(*) as total FROM stories WHERE is_published = 1');
    $total = $stmt->fetch()['total'];
    echo "\nВсего опубликованных историй: $total\n";

} catch (PDOException $e) {
    echo "Ошибка: " . $e->getMessage() . "\n";
}
?>