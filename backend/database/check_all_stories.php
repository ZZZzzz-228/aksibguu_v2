<?php
// Скрипт для проверки всех историй в базе данных
// Выполнить после добавления новых историй

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

    // Получить общее количество историй
    $stmt = $pdo->query("SELECT COUNT(*) as total FROM stories");
    $total = $stmt->fetch()['total'];

    echo "Текущее количество историй: $total\n\n";

    // Получить все истории с сортировкой
    $stmt = $pdo->prepare("
        SELECT id, title, sort_order, is_published, created_at,
               DATE_FORMAT(created_at, '%d.%m.%Y %H:%i') as formatted_date
        FROM stories
        ORDER BY sort_order ASC, created_at DESC
    ");
    $stmt->execute();
    $stories = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Все истории в базе данных:\n";
    echo str_repeat("-", 80) . "\n";
    printf("%-3s %-5s %-8s %-12s %s\n", "ID", "Порядок", "Опубликовано", "Дата", "Название");
    echo str_repeat("-", 80) . "\n";

    foreach ($stories as $story) {
        $published = $story['is_published'] ? 'Да' : 'Нет';
        printf("%-3d %-7d %-11s %-12s %s\n",
            $story['id'],
            $story['sort_order'],
            $published,
            $story['formatted_date'],
            mb_substr($story['title'], 0, 40) . (mb_strlen($story['title']) > 40 ? '...' : '')
        );
    }

    echo "\n" . str_repeat("-", 80) . "\n";

    // Проверить опубликованные истории
    $stmt = $pdo->query("SELECT COUNT(*) as published FROM stories WHERE is_published = 1");
    $published_count = $stmt->fetch()['published'];

    echo "Опубликовано историй: $published_count из $total\n";

    // Проверить порядок сортировки
    $stmt = $pdo->query("SELECT sort_order FROM stories ORDER BY sort_order ASC");
    $orders = $stmt->fetchAll(PDO::FETCH_COLUMN);

    $duplicates = array_diff_assoc($orders, array_unique($orders));
    if (!empty($duplicates)) {
        echo "ВНИМАНИЕ: Найдены дубликаты в порядке сортировки!\n";
    } else {
        echo "Порядок сортировки корректен (без дубликатов).\n";
    }

} catch (PDOException $e) {
    echo "Ошибка подключения к базе данных: " . $e->getMessage() . "\n";
}
?>