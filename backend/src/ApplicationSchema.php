<?php

declare(strict_types=1);

/** @return array<string, true> */
function applicationsTableColumns(PDO $pdo): array
{
    static $cache = null;
    if ($cache !== null) {
        return $cache;
    }
    $cache = [];
    try {
        $stmt = $pdo->query('SHOW COLUMNS FROM applications');
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $cache[(string)$row['Field']] = true;
        }
    } catch (Throwable $e) {
        $cache = [];
    }
    return $cache;
}

function applicationsHasColumn(PDO $pdo, string $column): bool
{
    return isset(applicationsTableColumns($pdo)[$column]);
}
