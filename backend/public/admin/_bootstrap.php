<?php

declare(strict_types=1);

ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_samesite', 'Lax');
if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
    ini_set('session.cookie_secure', '1');
}
session_start();

require_once __DIR__ . '/../../src/Database.php';
require_once __DIR__ . '/../../src/ApplicationSchema.php';
require_once __DIR__ . '/../../src/SmtpMailer.php';

$configPath = __DIR__ . '/../../config.php';
if (!file_exists($configPath)) {
    http_response_code(500);
    echo 'Missing backend/config.php';
    exit;
}

$config = require $configPath;
$pdo = Database::connect($config);

function h(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function flash(?string $message = null): ?string
{
    if ($message !== null) {
        $_SESSION['_flash'] = $message;
        return null;
    }
    if (!isset($_SESSION['_flash'])) {
        return null;
    }
    $value = (string)$_SESSION['_flash'];
    unset($_SESSION['_flash']);
    return $value;
}

function redirectTo(string $path): void
{
    header('Location: ' . $path);
    exit;
}

function csrfToken(): string
{
    if (empty($_SESSION['_csrf_token'])) {
        $_SESSION['_csrf_token'] = bin2hex(random_bytes(32));
    }
    return (string)$_SESSION['_csrf_token'];
}

function csrfField(): string
{
    return '<input type="hidden" name="_csrf" value="' . h(csrfToken()) . '">';
}

function requireCsrf(): void
{
    $token = (string)($_POST['_csrf'] ?? '');
    $sessionToken = (string)($_SESSION['_csrf_token'] ?? '');
    if ($token === '' || $sessionToken === '' || !hash_equals($sessionToken, $token)) {
        flash('CSRF проверка не пройдена. Обновите страницу и повторите.');
        redirectTo('/admin/index.php');
    }
}

function getCurrentUser(): ?array
{
    return $_SESSION['admin_user'] ?? null;
}

function requireLogin(): array
{
    $user = getCurrentUser();
    if (!$user) {
        redirectTo('/admin/login.php');
    }
    return $user;
}

function hasRole(string $role): bool
{
    $user = getCurrentUser();
    if (!$user) {
        return false;
    }
    $roles = $user['roles'] ?? [];
    return is_array($roles) && in_array($role, $roles, true);
}

function requireRole(string $role): void
{
    if (!hasRole($role)) {
        flash('Недостаточно прав для этого раздела.');
        redirectTo('/admin/index.php');
    }
}

function hasAnyRole(array $roles): bool
{
    foreach ($roles as $role) {
        if (hasRole((string)$role)) {
            return true;
        }
    }
    return false;
}

function requireAnyRole(array $roles): void
{
    if (!hasAnyRole($roles)) {
        flash('Недостаточно прав для этого раздела.');
        redirectTo('/admin/index.php');
    }
}

function canManageContent(): bool
{
    return hasAnyRole(['admin', 'staff', 'content_manager']);
}

function canManageAdmissions(): bool
{
    return hasAnyRole(['admin', 'staff', 'admissions']);
}

function canManageAcademic(): bool
{
    return hasAnyRole(['admin', 'staff', 'academic']);
}

function isAdmin(): bool
{
    return hasRole('admin');
}

/**
 * Определяет MIME загруженного файла без обязательного ext-fileinfo
 * (на части сборок PHP под Windows нет mime_content_type() / finfo).
 */
function detect_uploaded_mime_from_path(string $path): string
{
    if ($path === '' || !is_readable($path)) {
        return '';
    }
    $fromLib = '';
    if (function_exists('mime_content_type')) {
        $m = @mime_content_type($path);
        if (is_string($m) && $m !== '' && strcasecmp($m, 'application/octet-stream') !== 0) {
            $fromLib = strtolower(trim($m));
        }
    }
    if ($fromLib === '' && class_exists('finfo')) {
        $f = @new finfo(FILEINFO_MIME_TYPE);
        if ($f instanceof finfo) {
            $m = @$f->file($path);
            if (is_string($m) && $m !== '' && strcasecmp($m, 'application/octet-stream') !== 0) {
                $fromLib = strtolower(trim($m));
            }
        }
    }
    if ($fromLib !== '') {
        return $fromLib;
    }

    $fh = @fopen($path, 'rb');
    if ($fh === false) {
        return '';
    }
    $head = (string)fread($fh, 16);
    fclose($fh);
    if ($head === '') {
        return '';
    }
    $a = ord($head[0]);
    $b = ord($head[1]);
    $c = ord($head[2]);
    if ($a === 0xFF && $b === 0xD8 && $c === 0xFF) {
        return 'image/jpeg';
    }
    if (strlen($head) >= 8 && strncmp($head, "\x89PNG\r\n\x1a\n", 8) === 0) {
        return 'image/png';
    }
    if (strlen($head) >= 12 && strncmp($head, 'RIFF', 4) === 0 && substr($head, 8, 4) === 'WEBP') {
        return 'image/webp';
    }
    if (strncmp($head, '%PDF-', 5) === 0) {
        return 'application/pdf';
    }

    return '';
}

function saveUploadedImage(string $fieldName): ?string
{
    if (!isset($_FILES[$fieldName]) || !is_array($_FILES[$fieldName])) {
        return null;
    }
    $file = $_FILES[$fieldName];
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
        return null;
    }
    if (($file['error'] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK) {
        return null;
    }

    $tmp = (string)($file['tmp_name'] ?? '');
    if ($tmp === '' || !is_uploaded_file($tmp)) {
        return null;
    }
    $size = (int)($file['size'] ?? 0);
    if ($size <= 0 || $size > 8 * 1024 * 1024) {
        return null;
    }

    $mime = detect_uploaded_mime_from_path($tmp);
    $ext = match ($mime) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        default => null,
    };
    if ($ext === null) {
        return null;
    }

    $uploadsDir = __DIR__ . '/../uploads';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0775, true);
    }
    $name = 'img_' . date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $target = $uploadsDir . '/' . $name;
    if (!move_uploaded_file($tmp, $target)) {
        return null;
    }
    return '/uploads/' . $name;
}

function saveBase64Image(string $dataUrl): ?string
{
    if (strlen($dataUrl) > 12 * 1024 * 1024) {
        return null;
    }
    if (!preg_match('#^data:image/(png|jpeg|jpg|webp);base64,#i', $dataUrl, $m)) {
        return null;
    }
    $ext = strtolower($m[1]);
    if ($ext === 'jpeg') {
        $ext = 'jpg';
    }
    $payload = preg_replace('#^data:image/[^;]+;base64,#i', '', $dataUrl);
    if ($payload === null || $payload === '') {
        return null;
    }
    $binary = base64_decode($payload, true);
    if ($binary === false) {
        return null;
    }

    $uploadsDir = __DIR__ . '/../uploads';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0775, true);
    }
    $name = 'img_' . date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $target = $uploadsDir . '/' . $name;
    if (file_put_contents($target, $binary) === false) {
        return null;
    }
    return '/uploads/' . $name;
}

function auditLog(PDO $pdo, string $action, string $entity, string $entityId, ?array $payload = null): void
{
    $currentUser = getCurrentUser();
    $userId = (int)($currentUser['id'] ?? 0);
    $stmt = $pdo->prepare(
        'INSERT INTO audit_log(user_id, action, entity, entity_id, payload_json)
         VALUES (:user_id, :action, :entity, :entity_id, :payload_json)'
    );
    $stmt->execute([
        'user_id' => $userId > 0 ? $userId : null,
        'action' => $action,
        'entity' => $entity,
        'entity_id' => $entityId,
        'payload_json' => $payload ? json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
    ]);
}

function isRateLimited(string $key, int $maxAttempts, int $windowSeconds): bool
{
    $dir = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'career_center_rate_limit';
    if (!is_dir($dir)) {
        @mkdir($dir, 0775, true);
    }
    $safeKey = preg_replace('/[^a-z0-9_\-:.]/i', '_', $key);
    $file = $dir . DIRECTORY_SEPARATOR . $safeKey . '.json';
    $now = time();
    $attempts = [];

    if (is_file($file)) {
        $raw = @file_get_contents($file);
        if (is_string($raw) && $raw !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                $attempts = $decoded;
            }
        }
    }

    $attempts = array_values(array_filter($attempts, static fn($ts) => is_int($ts) && ($now - $ts) <= $windowSeconds));
    $attempts[] = $now;
    @file_put_contents($file, json_encode($attempts));

    return count($attempts) > $maxAttempts;
}

function adminGetRoleIdByCode(PDO $pdo, string $code): int
{
    $stmt = $pdo->prepare('SELECT id FROM roles WHERE code = :code LIMIT 1');
    $stmt->execute(['code' => $code]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) {
        throw new RuntimeException('Role not found: ' . $code);
    }
    return (int)$row['id'];
}

function adminLogLogin(PDO $pdo, int $userId): void
{
    try {
        $stmt = $pdo->prepare(
            'INSERT INTO admin_login_log(user_id, ip, user_agent) VALUES (:user_id, :ip, :ua)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'ip' => $_SERVER['REMOTE_ADDR'] ?? null,
            'ua' => isset($_SERVER['HTTP_USER_AGENT']) ? substr((string)$_SERVER['HTTP_USER_AGENT'], 0, 512) : null,
        ]);
    } catch (Throwable $e) {
        // table may be missing until migration
    }
}

function adminCountNewApplications(PDO $pdo): int
{
    try {
        return (int)$pdo->query('SELECT COUNT(*) FROM applications WHERE status = "new"')->fetchColumn();
    } catch (Throwable $e) {
        return 0;
    }
}

function siteSetting(PDO $pdo, string $key, ?string $default = null): ?string
{
    try {
        $stmt = $pdo->prepare('SELECT `value` FROM site_settings WHERE `key` = :k LIMIT 1');
        $stmt->execute(['k' => $key]);
        $v = $stmt->fetchColumn();
        return $v !== false ? (string)$v : $default;
    } catch (Throwable $e) {
        return $default;
    }
}

function siteSettingSet(PDO $pdo, string $key, string $value): void
{
    try {
        $stmt = $pdo->prepare(
            'INSERT INTO site_settings(`key`, `value`) VALUES (:k, :v)
             ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)'
        );
        $stmt->execute(['k' => $key, 'v' => $value]);
    } catch (Throwable $e) {
        // site_settings до миграции
    }
}

function applicationSpecialtyFromPayload(array $payload): ?string
{
    if (!empty($payload['specialty']) && is_string($payload['specialty'])) {
        return $payload['specialty'];
    }
    if (!empty($payload['specialties']) && is_array($payload['specialties'])) {
        $parts = [];
        foreach ($payload['specialties'] as $s) {
            if (is_string($s) && $s !== '') {
                $parts[] = $s;
            }
        }
        return $parts ? implode('; ', $parts) : null;
    }
    return null;
}

function saveApplicationUploadedFile(array $file): ?array
{
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
        return null;
    }
    if (($file['error'] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK) {
        return null;
    }
    $tmp = (string)($file['tmp_name'] ?? '');
    if ($tmp === '' || !is_uploaded_file($tmp)) {
        return null;
    }
    $size = (int)($file['size'] ?? 0);
    if ($size <= 0 || $size > 8 * 1024 * 1024) {
        return null;
    }
    $orig = (string)($file['name'] ?? 'file');
    $mime = detect_uploaded_mime_from_path($tmp);
    $ext = match ($mime) {
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
        'application/pdf' => 'pdf',
        default => null,
    };
    if ($ext === null) {
        return null;
    }
    $uploadsDir = __DIR__ . '/../uploads';
    if (!is_dir($uploadsDir)) {
        mkdir($uploadsDir, 0775, true);
    }
    $name = 'app_' . date('Ymd_His') . '_' . bin2hex(random_bytes(6)) . '.' . $ext;
    $target = $uploadsDir . '/' . $name;
    if (!move_uploaded_file($tmp, $target)) {
        return null;
    }
    return [
        'url' => '/uploads/' . $name,
        'original_name' => $orig,
        'mime' => $mime,
        'size_bytes' => $size,
    ];
}

function loginByEmail(PDO $pdo, string $email, string $password): bool
{
    $stmt = $pdo->prepare(
        'SELECT id, full_name, email, password_hash, is_active
         FROM users
         WHERE email = :email
         LIMIT 1'
    );
    $stmt->execute(['email' => mb_strtolower(trim($email))]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user) {
        return false;
    }
    if ((int)$user['is_active'] !== 1) {
        return false;
    }
    if (!password_verify($password, (string)$user['password_hash'])) {
        return false;
    }

    $roleStmt = $pdo->prepare(
        'SELECT r.code
         FROM roles r
         JOIN user_roles ur ON ur.role_id = r.id
         WHERE ur.user_id = :user_id'
    );
    $roleStmt->execute(['user_id' => $user['id']]);
    $roles = array_map(static fn(array $row) => $row['code'], $roleStmt->fetchAll(PDO::FETCH_ASSOC));
    if (!in_array('admin', $roles, true) && !in_array('staff', $roles, true)) {
        return false;
    }

    $_SESSION['admin_user'] = [
        'id' => (int)$user['id'],
        'email' => (string)$user['email'],
        'full_name' => (string)$user['full_name'],
        'roles' => $roles,
    ];
    return true;
}
