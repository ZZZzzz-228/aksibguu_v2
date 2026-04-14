<!-- 
    Инструкция по использованию оптимизированных ресурсов в админ панели.
    
    Определите в начале поекта (например, в _bootstrap.php):
    define('DEBUG_MODE', false); // false для production
    
    Затем в _layout_top.php используйте:
    <link rel="stylesheet" href="/admin/assets/<?= DEBUG_MODE ? 'admin.css' : 'admin.min.css' ?>">
    <script src="/admin/assets/<?= DEBUG_MODE ? 'toast.js' : 'toast.min.js' ?>"></script>
    
    ИЛИ добавьте простую функцию:
    
    function asset($path) {
        if (defined('DEBUG_MODE') && !DEBUG_MODE) {
            return preg_replace('/\.(css|js)$/', '.min.$1', $path);
        }
        return $path;
    }
    
    Тогда в HTML:
    <link rel="stylesheet" href="/admin/assets/<?= asset('admin.css') ?>">
    <script src="/admin/assets/<?= asset('toast.js') ?>"></script>
-->

<!-- БЫСТРАЯ ИНТЕГРАЦИЯ (для staff.php и других страниц): -->

<!-- В _layout_top.php замените: -->
<link rel="stylesheet" href="/admin/assets/admin.css">

<!-- Ha: -->
<link rel="stylesheet" href="/admin/assets/<?php 
    // Используем минифицированные файлы если не DEBUG_MODE
    $debugMode = defined('DEBUG_MODE') ? DEBUG_MODE : (getenv('APP_ENV') === 'development');
    echo $debugMode ? 'admin.css' : 'admin.min.css';
?>">

<!-- В конце HTML body в staff.php замените: -->
<script src="/admin/assets/toast.js"></script>
<script src="/admin/assets/admin-ajax.js"></script>

<!-- На: -->
<script src="/admin/assets/<?= $debugMode ? 'toast.js' : 'toast.min.js' ?>"></script>
<script src="/admin/assets/<?= $debugMode ? 'admin-ajax.js' : 'admin-ajax.min.js' ?>"></script>

<!-- 
    АЛЬТЕРНАТИВНЫЙ СПОСОБ (функция помощник):
    
    В _bootstrap.php добавьте:
    
    function assetFile($name) {
        static $minify = null;
        if ($minify === null) {
            $minify = (defined('DEBUG_MODE') && !DEBUG_MODE) || 
                      (defined('APP_ENV') && APP_ENV === 'production');
        }
        
        if ($minify && preg_match('/\.(css|js)$/', $name)) {
            return preg_replace('/\.(css|js)$/', '.min.$1', $name);
        }
        return $name;
    }
    
    Тогда в HTML:
    <link rel="stylesheet" href="/admin/assets/<?= assetFile('admin.css') ?>">
    <script src="/admin/assets/<?= assetFile('toast.js') ?>"></script>
-->
