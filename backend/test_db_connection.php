<?php

require_once __DIR__ . '/src/Database.php';

$config = require __DIR__ . '/config.php';

try {
    $pdo = Database::connect($config);
    echo "Database connection successful!\n";

    // Test a simple query
    $stmt = $pdo->query("SELECT 1 as test");
    $result = $stmt->fetch();
    echo "Query test: " . $result['test'] . "\n";

} catch (Exception $e) {
    echo "Database connection failed: " . $e->getMessage() . "\n";
}