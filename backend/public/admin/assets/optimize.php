<?php
/**
 * Помощник для оптимизации загрузки ресурсов
 * Использует минифицированные версии в production, обычные в development
 */

/**
 * Получить URL для файла (с учетом минификации)
 * @param string $file Путь к файлу (например '/admin/assets/admin.css')
 * @param bool $forceMinified Всегда использовать минифицированную версию
 * @return string
 */
function assetUrl($file, $forceMinified = false) {
    // Определить production режим
    $isProduction = !defined('DEBUG_MODE') || !DEBUG_MODE;
    
    if ($isProduction || $forceMinified) {
        // В production используем минифицированные версии
        $pathInfo = pathinfo($file);
        $dir = $pathInfo['dirname'];
        $name = $pathInfo['filename'];
        $ext = $pathInfo['extension'];
        
        // Проверяем существует ли минифицированная версия
        $minFile = "{$dir}/{$name}.min.{$ext}";
        $minPath = '/admin/assets/' . basename($minFile);
        
        // Если файл CSS или JS, всегда пытаемся создать минифицированный URL
        if (in_array($ext, ['css', 'js'], true)) {
            return str_replace($file, $minFile, $file);
        }
    }
    
    return $file;
}

/**
 * Включить оптимизацию ресурсов (CSS/JS)
 * Возвращает путь к файлу или его минифицированную версию
 */
function optimizeAsset($path) {
    $minPath = preg_replace('/\.(css|js)$/', '.min.$1', $path);
    $fullMinPath = __DIR__ . $minPath;
    
    // Если минифицированный файл существует и мы в production
    if (file_exists($fullMinPath) && ((defined('DEBUG_MODE') && !DEBUG_MODE) || getenv('APP_ENV') === 'production')) {
        return $minPath;
    }
    
    return $path;
}
?>
