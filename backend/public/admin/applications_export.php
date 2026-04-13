<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireRole('admin');

$hasSpecialtyTextCol = applicationsHasColumn($pdo, 'specialty_text');
$hasRejectionReasonCol = applicationsHasColumn($pdo, 'rejection_reason');

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="applications_' . date('Y-m-d') . '.csv"');

$out = fopen('php://output', 'w');
fprintf($out, chr(0xEF) . chr(0xBB) . chr(0xBF));

fputcsv($out, ['ID', 'Дата', 'Тип', 'ФИО', 'Телефон', 'Email', 'Специальность', 'Статус', 'Причина отклонения'], ';');

$status = trim((string)($_GET['status'] ?? ''));
$type = trim((string)($_GET['type'] ?? ''));
$spec = trim((string)($_GET['specialty'] ?? ''));
$q = trim((string)($_GET['q'] ?? ''));
$dateFrom = trim((string)($_GET['date_from'] ?? ''));
$dateTo = trim((string)($_GET['date_to'] ?? ''));

$where = ['1=1'];
$params = [];
if ($type !== '' && in_array($type, ['documents', 'courses'], true)) {
    $where[] = 'a.type = :type';
    $params['type'] = $type;
}
if ($status !== '' && in_array($status, ['new', 'processing', 'approved', 'rejected'], true)) {
    $where[] = 'a.status = :status';
    $params['status'] = $status;
}
if ($spec !== '' && $hasSpecialtyTextCol) {
    $where[] = 'a.specialty_text LIKE :spec';
    $params['spec'] = '%' . $spec . '%';
}
if ($q !== '') {
    $where[] = '(a.full_name LIKE :q OR a.email LIKE :q OR a.phone LIKE :q)';
    $params['q'] = '%' . $q . '%';
}
if ($dateFrom !== '') {
    $where[] = 'a.created_at >= :df';
    $params['df'] = $dateFrom . ' 00:00:00';
}
if ($dateTo !== '') {
    $where[] = 'a.created_at <= :dt';
    $params['dt'] = $dateTo . ' 23:59:59';
}
$whereSql = implode(' AND ', $where);

$specSel = $hasSpecialtyTextCol ? 'a.specialty_text' : 'NULL AS specialty_text';
$rejSel = $hasRejectionReasonCol ? 'a.rejection_reason' : 'NULL AS rejection_reason';
$sql = "SELECT a.id, a.created_at, a.type, a.full_name, a.phone, a.email, {$specSel}, a.status, {$rejSel}
        FROM applications a WHERE $whereSql ORDER BY a.id DESC LIMIT 10000";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

$map = ['new' => 'Новая', 'processing' => 'В работе', 'approved' => 'Принята', 'rejected' => 'Отклонена'];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    fputcsv($out, [
        $row['id'],
        $row['created_at'],
        $row['type'],
        $row['full_name'],
        $row['phone'],
        $row['email'],
        $row['specialty_text'],
        $map[$row['status']] ?? $row['status'],
        $row['rejection_reason'],
    ], ';');
}
fclose($out);
exit;
