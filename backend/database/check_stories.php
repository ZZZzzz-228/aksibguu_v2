<?php

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/Response.php';

$config = require __DIR__ . '/../config.php';

try {
    $pdo = Database::connect($config);

    // Проверяем, есть ли уже истории
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM stories");
    $result = $stmt->fetch();
    $existingCount = (int)$result['count'];

    echo "Текущее количество историй: $existingCount\n";

    if ($existingCount > 0) {
        echo "Истории уже существуют. Проверим структуру таблицы...\n";

        // Проверяем структуру таблицы
        $stmt = $pdo->query("DESCRIBE stories");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $hasPublishFrom = false;
        $hasPublishTo = false;

        foreach ($columns as $column) {
            if ($column['Field'] === 'publish_from') $hasPublishFrom = true;
            if ($column['Field'] === 'publish_to') $hasPublishTo = true;
        }

        if (!$hasPublishFrom || !$hasPublishTo) {
            echo "Таблица нуждается в миграции. Выполните migration_stories_publish_dates.sql\n";
        } else {
            echo "Структура таблицы корректна.\n";
        }

        // Показываем существующие истории
        $stmt = $pdo->query("SELECT id, title, sort_order, is_published FROM stories ORDER BY sort_order ASC");
        $stories = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo "\nСуществующие истории:\n";
        foreach ($stories as $story) {
            echo "- ID {$story['id']}: {$story['title']} (порядок: {$story['sort_order']}, опубликовано: " . ($story['is_published'] ? 'да' : 'нет') . ")\n";
        }

    } else {
        echo "Историй нет. Выполните insert_stories.sql для добавления примерных историй.\n";
    }

} catch (Throwable $e) {
    echo "Ошибка: " . $e->getMessage() . "\n";
}