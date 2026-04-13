<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireRole('admin');

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="students_' . date('Y-m-d') . '.csv"');

$out = fopen('php://output', 'w');
fprintf($out, chr(0xEF) . chr(0xBB) . chr(0xBF));

fputcsv($out, ['ID', 'ФИО', 'Зачётка', 'Группа', 'Специальность', 'Email', 'Телефон', 'Регистрация', 'Активен'], ';');

$q = trim((string)($_GET['q'] ?? ''));
$where = ['r.code = "student"'];
$params = [];
if ($q !== '') {
    $where[] = '(u.full_name LIKE :q OR u.email LIKE :q OR u.phone LIKE :q OR sp.student_code LIKE :q)';
    $params['q'] = '%' . $q . '%';
}
$whereSql = implode(' AND ', $where);

$sql = "SELECT u.id, u.full_name, u.email, u.phone, u.created_at, u.is_active,
        sp.student_code, g.title AS group_title, s.title AS specialty_title
        FROM users u
        JOIN user_roles ur ON ur.user_id = u.id
        JOIN roles r ON r.id = ur.role_id
        LEFT JOIN student_profiles sp ON sp.user_id = u.id
        LEFT JOIN groups_ref g ON g.id = sp.group_id
        LEFT JOIN specialties s ON s.id = g.specialty_id
        WHERE $whereSql
        ORDER BY u.id DESC
        LIMIT 10000";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);

while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    fputcsv($out, [
        $row['id'],
        $row['full_name'],
        $row['student_code'],
        $row['group_title'],
        $row['specialty_title'],
        $row['email'],
        $row['phone'],
        $row['created_at'],
        (int)$row['is_active'] === 1 ? 'Да' : 'Нет',
    ], ';');
}
fclose($out);
exit;
