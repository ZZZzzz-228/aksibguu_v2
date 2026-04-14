<?php

declare(strict_types=1);

/**
 * Загружает полный контент экрана «О колледже» из about_college_default.json в таблицу pages.
 * Запуск: php backend/database/apply_about_college_json.php
 */
require_once __DIR__ . '/../public/admin/_bootstrap.php';

$path = __DIR__ . '/about_college_default.json';
$json = file_get_contents($path);
if ($json === false) {
    fwrite(STDERR, "Файл не найден: $path\n");
    exit(1);
}

$check = $pdo->prepare('SELECT id FROM pages WHERE slug = :slug LIMIT 1');
$check->execute(['slug' => 'about-college']);
if (!$check->fetch(PDO::FETCH_ASSOC)) {
    $ins = $pdo->prepare(
        'INSERT INTO pages (slug, title, audience, content_json, is_published, created_by, updated_by)
         VALUES (:slug, :title, :audience, :content_json, 1, NULL, NULL)'
    );
    $ins->execute([
        'slug' => 'about-college',
        'title' => 'О колледже',
        'audience' => 'guest',
        'content_json' => $json,
    ]);
    echo "Создана страница about-college.\n";
    exit(0);
}

$upd = $pdo->prepare('UPDATE pages SET content_json = :cj WHERE slug = :slug');
$upd->execute(['cj' => $json, 'slug' => 'about-college']);
echo 'Обновлён content_json для slug=about-college, строк: ' . $upd->rowCount() . PHP_EOL;
