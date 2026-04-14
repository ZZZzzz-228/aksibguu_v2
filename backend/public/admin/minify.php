#!/usr/bin/env php
<?php
/**
 * Скрипт для минификации и оптимизации CSS и JS файлов админ панели
 * Использование: php minify.php
 */

$assetsDir = __DIR__ . '/assets';

if (!is_dir($assetsDir)) {
    die("Ошибка: Директория $assetsDir не найдена\n");
}

echo "=== Минификация файлов админ панели ===\n\n";

// Минифицировать CSS
$cssFile = $assetsDir . '/admin.css';
if (file_exists($cssFile)) {
    $css = file_get_contents($cssFile);
    $minified = minifyCSS($css);
    $minSize = strlen($css);
    $minifiedSize = strlen($minified);
    $saved = round(($minSize - $minifiedSize) / $minSize * 100, 1);
    
    file_put_contents($assetsDir . '/admin.min.css', $minified);
    echo "✓ admin.css минифицирован\n";
    echo "  Было: " . formatBytes($minSize) . " → Стало: " . formatBytes($minifiedSize) . " (сохранено $saved%)\n\n";
}

// Минифицировать JS файлы
$jsFiles = ['toast.js', 'admin-ajax.js'];
foreach ($jsFiles as $jsFile) {
    $jsPath = $assetsDir . '/' . $jsFile;
    if (file_exists($jsPath)) {
        $js = file_get_contents($jsPath);
        $minified = minifyJS($js);
        $originalSize = strlen($js);
        $minifiedSize = strlen($minified);
        $saved = round(($originalSize - $minifiedSize) / $originalSize * 100, 1);
        
        $outputFile = $assetsDir . '/' . str_replace('.js', '.min.js', $jsFile);
        file_put_contents($outputFile, $minified);
        echo "✓ " . basename($jsFile) . " минифицирован\n";
        echo "  Было: " . formatBytes($originalSize) . " → Стало: " . formatBytes($minifiedSize) . " (сохранено $saved%)\n\n";
    }
}

echo "Готово! Используйте .min.css и .min.js файлы в production.\n";

/**
 * Минификация CSS
 */
function minifyCSS($css) {
    // Удалить комментарии
    $css = preg_replace('!/\*[^*]*\*+(?:[^/*][^*]*\*+)*/!', '', $css);
    
    // Удалить пробелы
    $css = preg_replace('/\s+/', ' ', $css);
    $css = preg_replace('/\s*([{}:;,>+~])\s*/', '$1', $css);
    
    // Удалить последний ;
    $css = preg_replace('/;(?=})/', '', $css);
    
    return trim($css);
}

/**
 * Минификация JavaScript
 */
function minifyJS($js) {
    // Удалить комментарии //
    $js = preg_replace('!//.*$!m', '', $js);
    
    // Удалить комментарии /* */
    $js = preg_replace('!/\*[^*]*\*+(?:[^/*][^*]*\*+)*/!', '', $js);
    
    // Удалить множественные пробелы/переносы строк
    $js = preg_replace('/\s+/', ' ', $js);
    
    // Удалить пробелы вокруг операторов (осторожно!)
    $js = preg_replace('/\s*([\{\};,:=\+\-\*\/\<\>%&\|\^!~\(\)\[\]])\s*/', '$1', $js);
    
    return trim($js);
}

/**
 * Форматирование размера файла
 */
function formatBytes($bytes) {
    $units = ['B', 'KB', 'MB'];
    $bytes = max($bytes, 0);
    $pow = floor(($bytes ? log($bytes) : 0) / log(1024));
    $pow = min($pow, count($units) - 1);
    $bytes /= (1 << (10 * $pow));
    
    return round($bytes, 2) . ' ' . $units[$pow];
}
