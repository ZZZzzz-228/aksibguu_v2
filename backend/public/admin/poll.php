<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAdmissions()) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'message' => 'forbidden'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

$newApps = adminCountNewApplications($pdo);
$latestId = 0;
$latestCreatedAt = null;

try {
    $row = $pdo->query('SELECT id, created_at FROM applications ORDER BY id DESC LIMIT 1')->fetch(PDO::FETCH_ASSOC);
    if ($row) {
        $latestId = (int)($row['id'] ?? 0);
        $latestCreatedAt = isset($row['created_at']) ? (string)$row['created_at'] : null;
    }
} catch (Throwable $e) {
    // table may be missing until migration
}

echo json_encode([
    'ok' => true,
    'new_applications_count' => $newApps,
    'latest_application_id' => $latestId,
    'latest_application_created_at' => $latestCreatedAt,
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

