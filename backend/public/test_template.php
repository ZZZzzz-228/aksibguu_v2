<?php

// Проверяем чтение шаблона
$templatePath = __DIR__ . '/../templates/email_template.html';

if (!file_exists($templatePath)) {
    echo "ERROR: Template file not found: $templatePath\n";
    exit(1);
}

$template = file_get_contents($templatePath);

if ($template === false) {
    echo "ERROR: Cannot read template file\n";
    exit(1);
}

echo "Template loaded successfully (" . strlen($template) . " bytes)\n";

// Заменяем плейсхолдеры
$template = str_replace('{FULL_NAME}', 'Тестовое Имя', $template);
$template = str_replace('{EMAIL}', 'test@example.com', $template);
$template = str_replace('{PASSWORD}', 'testpass123', $template);

// Сохраняем для проверки
file_put_contents(__DIR__ . '/test_email.html', $template);

echo "Test HTML created: test_email.html\n";
echo "First 200 chars:\n" . substr($template, 0, 200) . "\n";