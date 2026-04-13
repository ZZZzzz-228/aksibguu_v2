<?php

declare(strict_types=1);

$host = '127.0.0.1';
$port = 3308;
$user = 'root';
$pass = '';
$dbName = 'career_center_ak_sibgu';

$mysqli = mysqli_init();
if (!$mysqli->real_connect($host, $user, $pass, '', $port)) {
    fwrite(STDERR, 'Cannot connect to MySQL: ' . mysqli_connect_error() . "\n");
    exit(1);
}

$mysqli->query('CREATE DATABASE IF NOT EXISTS `' . $mysqli->real_escape_string($dbName) . '` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
$mysqli->select_db($dbName);

$res = $mysqli->query(
    'SELECT COUNT(*) AS c FROM information_schema.tables WHERE table_schema = ' . "'" . $mysqli->real_escape_string($dbName) . "'"
);
$row = $res ? $res->fetch_assoc() : null;
$tableCount = (int)($row['c'] ?? 0);
if ($tableCount > 0) {
    echo "Database {$dbName} already has {$tableCount} tables. Skipping import.\n";
    exit(0);
}

$base = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'database' . DIRECTORY_SEPARATOR;
$files = [
    $base . 'schema.sql',
    $base . 'seed.sql',
];

foreach ($files as $sqlFile) {
    if (!is_file($sqlFile)) {
        fwrite(STDERR, "Missing: {$sqlFile}\n");
        exit(1);
    }
    echo 'Importing ' . basename($sqlFile) . " ...\n";
    $sql = file_get_contents($sqlFile);
    if ($sql === false) {
        fwrite(STDERR, "Cannot read {$sqlFile}\n");
        exit(1);
    }
    if (!$mysqli->multi_query($sql)) {
        fwrite(STDERR, $mysqli->error . "\n");
        exit(1);
    }
    do {
        if ($result = $mysqli->store_result()) {
            $result->free();
        }
    } while ($mysqli->more_results() && $mysqli->next_result());
    if ($mysqli->errno) {
        fwrite(STDERR, 'SQL error: ' . $mysqli->error . "\n");
        exit(1);
    }
}

echo "Done.\n";
