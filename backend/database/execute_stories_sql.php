<?php
// Скрипт для выполнения SQL файла с историями
// Выполнить для добавления новых историй в базу данных

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

    // Прочитать SQL файл
    $sql = file_get_contents('insert_stories.sql');

    // Найти все INSERT запросы
    preg_match_all('/INSERT INTO stories.*?;\s*(?=INSERT|\-\-|$)/s', $sql, $matches);

    $inserted = 0;
    foreach ($matches[0] as $query) {
        $query = trim($query);
        if (!empty($query)) {
            try {
                $pdo->exec($query);
                $inserted++;
                echo "Добавлена история " . $inserted . "\n";
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
                    echo "Пропущен дубликат (уже существует)\n";
                } else {
                    echo "Ошибка: " . $e->getMessage() . "\n";
                    echo "Запрос: " . substr($query, 0, 100) . "...\n";
                }
            }
        }
    }

    echo "\nВсего добавлено новых историй: $inserted\n";

} catch (PDOException $e) {
    echo "Ошибка подключения к базе данных: " . $e->getMessage() . "\n";
}
?>