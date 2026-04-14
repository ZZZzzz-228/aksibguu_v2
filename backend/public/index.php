<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/Database.php';
require_once __DIR__ . '/../src/ApplicationSchema.php';
require_once __DIR__ . '/../src/Response.php';
require_once __DIR__ . '/../src/Jwt.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uriPath = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/';
$path = rtrim($uriPath, '/');

if ($path === '') {
    $path = '/';
}

// Без БД: проверка, что PHP-сервер и роутер живы
if ($method === 'GET' && $path === '/health') {
    Response::json([
        'ok' => true,
        'service' => 'career-center-api',
        'time' => gmdate('c'),
        'note' => 'DB not checked here; use GET /health/db after fixing config.',
    ]);
}

$configPath = __DIR__ . '/../config.php';
if (!file_exists($configPath)) {
    Response::json([
        'ok' => false,
        'message' => 'Create backend/config.php from backend/config.example.php first.',
    ], 500);
}

$config = require $configPath;
try {
    $pdo = Database::connect($config);
} catch (Throwable $e) {
    Response::json([
        'ok' => false,
        'message' => 'Database connection failed',
        'hint' => 'Make sure PHP has pdo_mysql enabled (extension=pdo_mysql) and DB credentials in backend/config.php match phpMyAdmin (user, password, database name, port).',
    ], 500);
}

if ($method === 'GET' && $path === '/health/db') {
    Response::json([
        'ok' => true,
        'database' => 'connected',
        'time' => gmdate('c'),
    ]);
}

if ($method === 'POST' && $path === '/auth/register') {
    $input = getJsonInput();
    $fullName = trim((string)($input['full_name'] ?? ''));
    $email = mb_strtolower(trim((string)($input['email'] ?? '')));
    $password = (string)($input['password'] ?? '');

    if ($fullName === '' || $email === '' || $password === '') {
        Response::json(['ok' => false, 'message' => 'full_name, email, password required'], 422);
    }

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        Response::json(['ok' => false, 'message' => 'Invalid email'], 422);
    }

    $stmt = $pdo->prepare('SELECT id FROM users WHERE email = :email LIMIT 1');
    $stmt->execute(['email' => $email]);
    if ($stmt->fetch()) {
        Response::json(['ok' => false, 'message' => 'User already exists'], 409);
    }

    $hash = password_hash($password, PASSWORD_BCRYPT);
    $insertUser = $pdo->prepare('INSERT INTO users(full_name, email, password_hash) VALUES (:full_name, :email, :password_hash)');
    $insertUser->execute([
        'full_name' => $fullName,
        'email' => $email,
        'password_hash' => $hash,
    ]);

    $userId = (int)$pdo->lastInsertId();
    $roleId = getRoleIdByCode($pdo, 'applicant');
    $attachRole = $pdo->prepare('INSERT INTO user_roles(user_id, role_id) VALUES (:user_id, :role_id)');
    $attachRole->execute(['user_id' => $userId, 'role_id' => $roleId]);

    Response::json(['ok' => true, 'user_id' => $userId], 201);
}

if ($method === 'POST' && $path === '/auth/login') {
    if (isRateLimited('api-login:' . ($_SERVER['REMOTE_ADDR'] ?? 'unknown'), 8, 300)) {
        Response::json(['ok' => false, 'message' => 'Too many login attempts. Try again later.'], 429);
    }
    $input = getJsonInput();
    $email = mb_strtolower(trim((string)($input['email'] ?? $input['login'] ?? '')));
    $password = (string)($input['password'] ?? '');

    if ($email === '' || $password === '') {
        Response::json(['ok' => false, 'message' => 'email/login and password required'], 422);
    }

    $stmt = $pdo->prepare(
        'SELECT id, full_name, email, password_hash, is_active
         FROM users
         WHERE email = :email
         LIMIT 1'
    );
    $stmt->execute(['email' => $email]);
    $user = $stmt->fetch();

    if (!$user || !password_verify($password, $user['password_hash'])) {
        Response::json(['ok' => false, 'message' => 'Invalid credentials'], 401);
    }

    if ((int)$user['is_active'] !== 1) {
        Response::json(['ok' => false, 'message' => 'User is disabled'], 403);
    }

    $roleStmt = $pdo->prepare(
        'SELECT r.code
         FROM roles r
         JOIN user_roles ur ON ur.role_id = r.id
         WHERE ur.user_id = :user_id'
    );
    $roleStmt->execute(['user_id' => $user['id']]);
    $roles = array_map(static fn(array $row) => $row['code'], $roleStmt->fetchAll());

    $now = time();
    $exp = $now + (int)$config['jwt']['ttl_seconds'];
    $token = Jwt::create([
        'sub' => (int)$user['id'],
        'email' => $user['email'],
        'roles' => $roles,
        'iss' => $config['jwt']['issuer'],
        'iat' => $now,
        'exp' => $exp,
    ], $config['jwt']['secret']);

    Response::json([
        'ok' => true,
        'token' => $token,
        'expires_at' => gmdate('c', $exp),
        'user' => [
            'id' => (int)$user['id'],
            'full_name' => $user['full_name'],
            'email' => $user['email'],
            'roles' => $roles,
        ],
    ]);
}

if ($method === 'GET' && $path === '/contacts') {
    $stmt = $pdo->query(
        'SELECT id, type, value, label
         FROM contacts
         WHERE is_active = 1
         ORDER BY sort_order ASC, id ASC'
    );
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/news') {
    $stmt = $pdo->query(
        'SELECT id, title, content, image_url, published_at
         FROM news_items
         WHERE is_published = 1
           AND (publish_from IS NULL OR publish_from <= NOW())
           AND (publish_to IS NULL OR publish_to >= NOW())
         ORDER BY published_at DESC, id DESC'
    );
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/stories') {
    $stmt = $pdo->query(
        'SELECT id, title, content, image_url, sort_order
         FROM stories
         WHERE is_published = 1
           AND (publish_from IS NULL OR publish_from <= NOW())
           AND (publish_to IS NULL OR publish_to >= NOW())
         ORDER BY sort_order ASC, id ASC'
    );
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/staff') {
    $stmt = $pdo->query(
        'SELECT id, full_name, position_title, email, phone, office_hours, photo_url, color_hex
         FROM staff_members
         WHERE is_published = 1
         ORDER BY sort_order ASC, id ASC'
    );
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/vacancies') {
    $query = trim((string)($_GET['q'] ?? ''));
    if ($query === '') {
        $stmt = $pdo->query(
            'SELECT id, title, company, city, employment_type, salary, description, published_at
             FROM vacancies
             WHERE is_active = 1
             ORDER BY published_at DESC, id DESC'
        );
        Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
    }

    $stmt = $pdo->prepare(
        'SELECT id, title, company, city, employment_type, salary, description, published_at
         FROM vacancies
         WHERE is_active = 1
           AND (title LIKE :q OR company LIKE :q OR city LIKE :q OR description LIKE :q)
         ORDER BY published_at DESC, id DESC'
    );
    $like = '%' . $query . '%';
    $stmt->execute(['q' => $like]);
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/public/pages') {
    $audience = trim((string)($_GET['audience'] ?? 'common'));
    if (!in_array($audience, ['guest', 'applicant', 'student', 'teacher', 'common'], true)) {
        $audience = 'common';
    }
    $stmt = $pdo->prepare(
        'SELECT id, slug, title, audience, content_json, cover_image_url
         FROM pages
         WHERE is_published = 1
           AND (publish_from IS NULL OR publish_from <= NOW())
           AND (publish_to IS NULL OR publish_to >= NOW())
           AND (audience = :audience OR audience = "common")
         ORDER BY id DESC'
    );
    $stmt->execute(['audience' => $audience]);
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && preg_match('#^/public/pages/([a-z0-9\-]+)$#', $path, $m)) {
    $slug = $m[1];
    $stmt = $pdo->prepare(
        'SELECT id, slug, title, audience, content_json, cover_image_url
         FROM pages
         WHERE slug = :slug
           AND is_published = 1
           AND (publish_from IS NULL OR publish_from <= NOW())
           AND (publish_to IS NULL OR publish_to >= NOW())
         LIMIT 1'
    );
    $stmt->execute(['slug' => $slug]);
    $row = $stmt->fetch();
    if (!$row) {
        Response::json(['ok' => false, 'message' => 'Page not found'], 404);
    }
    Response::json(['ok' => true, 'data' => $row]);
}

if ($method === 'GET' && $path === '/public/specialties') {
    try {
        $stmt = $pdo->query(
            'SELECT id, code, title, short_title, description, duration_label, study_form_label,
                    qualification_text, career_text, skills_text, salary_text, color_hex, icon_name, image_url
             FROM specialties
             WHERE is_published = 1
               AND (publish_from IS NULL OR publish_from <= NOW())
               AND (publish_to IS NULL OR publish_to >= NOW())
             ORDER BY sort_order ASC, id ASC'
        );
        Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
    } catch (Throwable $e) {
        // Совместимость со старой схемой (до migration_specialties_education_full.sql)
        $stmt = $pdo->query(
            "SELECT id, code, title, '' AS short_title, description,
                    '' AS duration_label, '' AS study_form_label, '' AS qualification_text,
                    '' AS career_text, '' AS skills_text, '' AS salary_text,
                    '' AS color_hex, COALESCE(icon_name, '') AS icon_name, COALESCE(image_url, '') AS image_url
             FROM specialties
             WHERE is_published = 1
               AND (publish_from IS NULL OR publish_from <= NOW())
               AND (publish_to IS NULL OR publish_to >= NOW())
             ORDER BY sort_order ASC, id ASC"
        );
        Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
    }
}

if ($method === 'GET' && $path === '/public/education-programs') {
    try {
        $stmt = $pdo->query(
            "SELECT id, type, title, description, duration_label, details,
                    target_audience, outcome_text, format_text,
                    icon_name, color_hex, image_url
             FROM education_programs
             WHERE is_published = 1
               AND (publish_from IS NULL OR publish_from <= NOW())
               AND (publish_to IS NULL OR publish_to >= NOW())
             ORDER BY type ASC, sort_order ASC, id ASC"
        );
        Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
    } catch (Throwable $e) {
        // Совместимость со старой схемой education_programs.
        try {
            $stmt = $pdo->query(
                "SELECT id, type, title, description, duration_label, details,
                        '' AS target_audience, '' AS outcome_text, '' AS format_text,
                        COALESCE(icon_name, '') AS icon_name, COALESCE(color_hex, '') AS color_hex, COALESCE(image_url, '') AS image_url
                 FROM education_programs
                 WHERE is_published = 1
                   AND (publish_from IS NULL OR publish_from <= NOW())
                   AND (publish_to IS NULL OR publish_to >= NOW())
                 ORDER BY type ASC, sort_order ASC, id ASC"
            );
            Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
        } catch (Throwable $e2) {
            // Если таблицы ещё нет, чтобы клиент не падал.
            Response::json(['ok' => true, 'data' => []]);
        }
    }
}

if ($method === 'GET' && $path === '/public/home/blocks') {
    try {
        $stmt = $pdo->prepare('SELECT `value` FROM site_settings WHERE `key` = :k LIMIT 1');
        $stmt->execute(['k' => 'guest_home_blocks_json']);
        $raw = $stmt->fetchColumn();
        $decoded = is_string($raw) ? json_decode($raw, true) : null;
        $blocks = is_array($decoded) ? $decoded : [];
        Response::json(['ok' => true, 'data' => $blocks]);
    } catch (Throwable $e) {
        Response::json(['ok' => true, 'data' => []]);
    }
}

if ($method === 'GET' && $path === '/public/partners') {
    $stmt = $pdo->query(
        'SELECT id, name, description, website_url, logo_url
         FROM partners
         WHERE is_published = 1
         ORDER BY sort_order ASC, id ASC'
    );
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/public/career-test') {
    $file = __DIR__ . '/../database/career_test.json';
    if (!is_file($file)) {
        Response::json(['ok' => true, 'data' => ['questions' => []]]);
    }
    $raw = file_get_contents($file);
    $decoded = is_string($raw) ? json_decode($raw, true) : null;
    if (!is_array($decoded)) {
        Response::json(['ok' => true, 'data' => ['questions' => []]]);
    }
    Response::json(['ok' => true, 'data' => $decoded]);
}

if ($method === 'GET' && $path === '/public/application-status') {
    $email = mb_strtolower(trim((string)($_GET['email'] ?? '')));
    if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        Response::json(['ok' => false, 'message' => 'email required'], 422);
    }
    try {
        $sel = ['id', 'status', 'created_at', 'updated_at'];
        if (applicationsHasColumn($pdo, 'rejection_reason')) {
            array_splice($sel, 2, 0, ['rejection_reason']);
        }
        $stmt = $pdo->prepare(
            'SELECT ' . implode(', ', $sel) . '
             FROM applications
             WHERE email = :e
             ORDER BY id DESC
             LIMIT 1'
        );
        $stmt->execute(['e' => $email]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row) {
            Response::json(['ok' => true, 'data' => null]);
        }
        $map = ['new' => 'Новая', 'processing' => 'В работе', 'approved' => 'Принята', 'rejected' => 'Отклонена'];
        Response::json([
            'ok' => true,
            'data' => [
                'id' => (int)$row['id'],
                'status' => (string)$row['status'],
                'status_label' => $map[$row['status']] ?? $row['status'],
                'rejection_reason' => $row['rejection_reason'] ?? null,
                'created_at' => $row['created_at'],
                'updated_at' => $row['updated_at'],
            ],
        ]);
    } catch (Throwable $e) {
        Response::json(['ok' => false, 'message' => 'Applications not available'], 503);
    }
}

if ($method === 'POST' && $path === '/public/applications') {
    try {
        $payload = [];
        $type = '';
        $fullName = '';
        $email = '';
        $phone = '';

        $ct = (string)($_SERVER['CONTENT_TYPE'] ?? '');
        if (stripos($ct, 'multipart/form-data') !== false) {
            $type = trim((string)($_POST['type'] ?? ''));
            $fullName = trim((string)($_POST['full_name'] ?? ''));
            $email = trim((string)($_POST['email'] ?? ''));
            $phone = trim((string)($_POST['phone'] ?? ''));
            $pj = (string)($_POST['payload_json'] ?? '{}');
            $decoded = json_decode($pj, true);
            $payload = is_array($decoded) ? $decoded : [];
        } else {
            $input = getJsonInput();
            $type = trim((string)($input['type'] ?? ''));
            $fullName = trim((string)($input['full_name'] ?? ''));
            $email = trim((string)($input['email'] ?? ''));
            $phone = trim((string)($input['phone'] ?? ''));
            $p = $input['payload'] ?? [];
            $payload = is_array($p) ? $p : [];
        }

        if (!in_array($type, ['documents', 'courses'], true)) {
            Response::json(['ok' => false, 'message' => 'Invalid application type'], 422);
        }
        if ($fullName === '') {
            Response::json(['ok' => false, 'message' => 'full_name required'], 422);
        }

        $specText = null;
        if (!empty($payload['specialty']) && is_string($payload['specialty'])) {
            $specText = $payload['specialty'];
        } elseif (!empty($payload['specialties']) && is_array($payload['specialties'])) {
            $parts = [];
            foreach ($payload['specialties'] as $s) {
                if (is_string($s) && $s !== '') {
                    $parts[] = $s;
                }
            }
            $specText = $parts ? implode('; ', $parts) : null;
        }

        $insertCols = ['type', 'full_name', 'email', 'phone', 'payload_json', 'status'];
        $insertPh = [':type', ':full_name', ':email', ':phone', ':payload_json', '"new"'];
        $execParams = [
            'type' => $type,
            'full_name' => $fullName,
            'email' => $email !== '' ? $email : null,
            'phone' => $phone !== '' ? $phone : null,
            'payload_json' => json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        ];
        if (applicationsHasColumn($pdo, 'specialty_text')) {
            array_splice($insertCols, 4, 0, ['specialty_text']);
            array_splice($insertPh, 4, 0, [':specialty_text']);
            $execParams['specialty_text'] = $specText;
        }
        $stmt = $pdo->prepare(
            'INSERT INTO applications(' . implode(', ', $insertCols) . ')
             VALUES (' . implode(', ', $insertPh) . ')'
        );
        $stmt->execute($execParams);
        $id = (int)$pdo->lastInsertId();

        if (
            stripos($ct, 'multipart/form-data') !== false
            && applicationsFilesTableExists($pdo)
            && !empty($_FILES['files'])
            && is_array($_FILES['files']['name'])
        ) {
            $names = $_FILES['files']['name'];
            if (!is_array($names)) {
                $names = [$names];
            }
            $count = count($names);
            for ($i = 0; $i < $count; $i++) {
                $file = [
                    'name' => is_array($_FILES['files']['name']) ? $_FILES['files']['name'][$i] : $_FILES['files']['name'],
                    'type' => is_array($_FILES['files']['type']) ? $_FILES['files']['type'][$i] : $_FILES['files']['type'],
                    'tmp_name' => is_array($_FILES['files']['tmp_name']) ? $_FILES['files']['tmp_name'][$i] : $_FILES['files']['tmp_name'],
                    'error' => is_array($_FILES['files']['error']) ? $_FILES['files']['error'][$i] : $_FILES['files']['error'],
                    'size' => is_array($_FILES['files']['size']) ? $_FILES['files']['size'][$i] : $_FILES['files']['size'],
                ];
                $saved = savePublicApplicationFile($file);
                if ($saved !== null) {
                    $ins = $pdo->prepare(
                        'INSERT INTO application_files(application_id, file_url, original_name, mime, size_bytes)
                         VALUES (:aid, :url, :oname, :mime, :sz)'
                    );
                    $ins->execute([
                        'aid' => $id,
                        'url' => $saved['url'],
                        'oname' => $saved['original_name'],
                        'mime' => $saved['mime'],
                        'sz' => $saved['size_bytes'],
                    ]);
                }
            }
        }

        Response::json(['ok' => true, 'id' => $id], 201);
    } catch (Throwable $e) {
        error_log('Could not save application: ' . $e->getMessage());
        Response::json(['ok' => false, 'message' => 'Could not save application'], 503);
    }
}

if ($method === 'GET' && $path === '/student/profile') {
    $auth = requireRoles($config, ['student']);
    $stmt = $pdo->prepare(
        'SELECT u.id AS user_id, u.full_name, u.email, u.phone,
                sp.student_code, sp.birth_date, sp.bio, sp.avatar_url, sp.portfolio_public,
                g.id AS group_id, g.code AS group_code, g.title AS group_title,
                c.id AS curator_id, c.full_name AS curator_name, c.position_title AS curator_position
         FROM users u
         LEFT JOIN student_profiles sp ON sp.user_id = u.id
         LEFT JOIN groups_ref g ON g.id = sp.group_id
         LEFT JOIN staff_members c ON c.id = sp.curator_staff_id
         WHERE u.id = :id
         LIMIT 1'
    );
    $stmt->execute(['id' => (int)$auth['sub']]);
    $row = $stmt->fetch();
    Response::json(['ok' => true, 'data' => $row ?: null]);
}

if ($method === 'PUT' && $path === '/student/profile') {
    $auth = requireRoles($config, ['student']);
    $input = getJsonInput();
    $bio = trim((string)($input['bio'] ?? ''));
    $avatarUrl = trim((string)($input['avatar_url'] ?? ''));
    $portfolioPublic = !empty($input['portfolio_public']) ? 1 : 0;
    $groupId = (int)($input['group_id'] ?? 0);
    $curatorId = (int)($input['curator_staff_id'] ?? 0);

    $stmt = $pdo->prepare(
        'INSERT INTO student_profiles(user_id, student_code, group_id, curator_staff_id, bio, avatar_url, portfolio_public)
         VALUES (:user_id, :student_code, :group_id, :curator_staff_id, :bio, :avatar_url, :portfolio_public)
         ON DUPLICATE KEY UPDATE
           group_id = VALUES(group_id),
           curator_staff_id = VALUES(curator_staff_id),
           bio = VALUES(bio),
           avatar_url = VALUES(avatar_url),
           portfolio_public = VALUES(portfolio_public)'
    );
    $stmt->execute([
        'user_id' => (int)$auth['sub'],
        'student_code' => 'STU-' . (int)$auth['sub'],
        'group_id' => $groupId > 0 ? $groupId : null,
        'curator_staff_id' => $curatorId > 0 ? $curatorId : null,
        'bio' => $bio !== '' ? $bio : null,
        'avatar_url' => $avatarUrl !== '' ? $avatarUrl : null,
        'portfolio_public' => $portfolioPublic,
    ]);
    Response::json(['ok' => true]);
}

if ($method === 'GET' && $path === '/student/groups') {
    requireRoles($config, ['student', 'teacher', 'staff', 'admin']);
    $stmt = $pdo->query(
        'SELECT g.id, g.code, g.title, g.specialty_id, s.title AS specialty_title,
                g.curator_staff_id, c.full_name AS curator_name
         FROM groups_ref g
         LEFT JOIN specialties s ON s.id = g.specialty_id
         LEFT JOIN staff_members c ON c.id = g.curator_staff_id
         WHERE g.is_active = 1
         ORDER BY g.code ASC'
    );
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/student/resumes') {
    $auth = requireRoles($config, ['student']);
    $stmt = $pdo->prepare(
        'SELECT id, title, summary, skills_json, experience_json, education_json, is_published, created_at, updated_at
         FROM student_resumes
         WHERE student_user_id = :student_user_id
         ORDER BY id DESC'
    );
    $stmt->execute(['student_user_id' => (int)$auth['sub']]);
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'POST' && $path === '/student/resumes') {
    $auth = requireRoles($config, ['student']);
    $input = getJsonInput();
    $title = trim((string)($input['title'] ?? ''));
    if ($title === '') {
        Response::json(['ok' => false, 'message' => 'title is required'], 422);
    }
    $stmt = $pdo->prepare(
        'INSERT INTO student_resumes(student_user_id, title, summary, skills_json, experience_json, education_json, is_published)
         VALUES (:student_user_id, :title, :summary, :skills_json, :experience_json, :education_json, :is_published)'
    );
    $stmt->execute([
        'student_user_id' => (int)$auth['sub'],
        'title' => $title,
        'summary' => trim((string)($input['summary'] ?? '')) ?: null,
        'skills_json' => isset($input['skills_json']) ? json_encode($input['skills_json'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        'experience_json' => isset($input['experience_json']) ? json_encode($input['experience_json'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        'education_json' => isset($input['education_json']) ? json_encode($input['education_json'], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        'is_published' => !empty($input['is_published']) ? 1 : 0,
    ]);
    Response::json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'DELETE' && preg_match('#^/student/resumes/(\d+)$#', $path, $m)) {
    $auth = requireRoles($config, ['student']);
    $stmt = $pdo->prepare('DELETE FROM student_resumes WHERE id = :id AND student_user_id = :student_user_id');
    $stmt->execute([
        'id' => (int)$m[1],
        'student_user_id' => (int)$auth['sub'],
    ]);
    Response::json(['ok' => true]);
}

if ($method === 'GET' && $path === '/student/portfolio') {
    $auth = requireRoles($config, ['student']);
    $stmt = $pdo->prepare(
        'SELECT id, title, description, project_url, image_url, sort_order, is_published, created_at, updated_at
         FROM student_portfolio_items
         WHERE student_user_id = :student_user_id
         ORDER BY sort_order ASC, id ASC'
    );
    $stmt->execute(['student_user_id' => (int)$auth['sub']]);
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'POST' && $path === '/student/portfolio') {
    $auth = requireRoles($config, ['student']);
    $input = getJsonInput();
    $title = trim((string)($input['title'] ?? ''));
    if ($title === '') {
        Response::json(['ok' => false, 'message' => 'title is required'], 422);
    }
    $stmt = $pdo->prepare(
        'INSERT INTO student_portfolio_items(student_user_id, title, description, project_url, image_url, sort_order, is_published)
         VALUES (:student_user_id, :title, :description, :project_url, :image_url, :sort_order, :is_published)'
    );
    $stmt->execute([
        'student_user_id' => (int)$auth['sub'],
        'title' => $title,
        'description' => trim((string)($input['description'] ?? '')) ?: null,
        'project_url' => trim((string)($input['project_url'] ?? '')) ?: null,
        'image_url' => trim((string)($input['image_url'] ?? '')) ?: null,
        'sort_order' => (int)($input['sort_order'] ?? 0),
        'is_published' => !empty($input['is_published']) ? 1 : 0,
    ]);
    Response::json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'DELETE' && preg_match('#^/student/portfolio/(\d+)$#', $path, $m)) {
    $auth = requireRoles($config, ['student']);
    $stmt = $pdo->prepare('DELETE FROM student_portfolio_items WHERE id = :id AND student_user_id = :student_user_id');
    $stmt->execute([
        'id' => (int)$m[1],
        'student_user_id' => (int)$auth['sub'],
    ]);
    Response::json(['ok' => true]);
}

if ($method === 'POST' && $path === '/admin/news') {
    $auth = requireAdminOrStaff($config);
    $input = getJsonInput();
    $title = trim((string)($input['title'] ?? ''));
    $content = trim((string)($input['content'] ?? ''));
    $imageUrl = trim((string)($input['image_url'] ?? ''));
    $isPublished = !empty($input['is_published']) ? 1 : 0;
    $publishedAt = trim((string)($input['published_at'] ?? ''));
    if ($publishedAt === '') {
        $publishedAt = date('Y-m-d H:i:s');
    }

    if ($title === '' || $content === '') {
        Response::json(['ok' => false, 'message' => 'title and content are required'], 422);
    }

    $stmt = $pdo->prepare(
        'INSERT INTO news_items(title, content, image_url, published_at, is_published, author_user_id)
         VALUES (:title, :content, :image_url, :published_at, :is_published, :author_user_id)'
    );
    $stmt->execute([
        'title' => $title,
        'content' => $content,
        'image_url' => $imageUrl !== '' ? $imageUrl : null,
        'published_at' => $publishedAt,
        'is_published' => $isPublished,
        'author_user_id' => $auth['sub'] ?? null,
    ]);
    Response::json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'GET' && $path === '/admin/pages') {
    requireRoles($config, ['admin', 'staff']);
    $stmt = $pdo->query('SELECT id, slug, title, audience, is_published, updated_at FROM pages ORDER BY updated_at DESC, id DESC');
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'POST' && $path === '/admin/pages') {
    $auth = requireRoles($config, ['admin', 'staff']);
    $input = getJsonInput();
    $slug = trim((string)($input['slug'] ?? ''));
    $titleValue = trim((string)($input['title'] ?? ''));
    if ($slug === '' || $titleValue === '') {
        Response::json(['ok' => false, 'message' => 'slug and title required'], 422);
    }
    $stmt = $pdo->prepare(
        'INSERT INTO pages(slug, title, audience, content_json, cover_image_url, is_published, created_by, updated_by)
         VALUES (:slug, :title, :audience, :content_json, :cover_image_url, :is_published, :created_by, :updated_by)'
    );
    $stmt->execute([
        'slug' => $slug,
        'title' => $titleValue,
        'audience' => trim((string)($input['audience'] ?? 'common')),
        'content_json' => json_encode($input['content_json'] ?? [], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        'cover_image_url' => trim((string)($input['cover_image_url'] ?? '')) ?: null,
        'is_published' => !empty($input['is_published']) ? 1 : 0,
        'created_by' => (int)$auth['sub'],
        'updated_by' => (int)$auth['sub'],
    ]);
    Response::json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'GET' && $path === '/admin/specialties') {
    requireRoles($config, ['admin', 'staff']);
    $stmt = $pdo->query('SELECT * FROM specialties ORDER BY sort_order ASC, id ASC');
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'GET' && $path === '/admin/partners') {
    requireRoles($config, ['admin', 'staff']);
    $stmt = $pdo->query('SELECT * FROM partners ORDER BY sort_order ASC, id ASC');
    Response::json(['ok' => true, 'data' => $stmt->fetchAll()]);
}

if ($method === 'PUT' && preg_match('#^/admin/news/(\d+)$#', $path, $m)) {
    requireAdminOrStaff($config);
    $id = (int)$m[1];
    $input = getJsonInput();
    $title = trim((string)($input['title'] ?? ''));
    $content = trim((string)($input['content'] ?? ''));
    $imageUrl = trim((string)($input['image_url'] ?? ''));
    $isPublished = !empty($input['is_published']) ? 1 : 0;
    $publishedAt = trim((string)($input['published_at'] ?? ''));
    if ($publishedAt === '') {
        $publishedAt = date('Y-m-d H:i:s');
    }

    if ($title === '' || $content === '') {
        Response::json(['ok' => false, 'message' => 'title and content are required'], 422);
    }

    $stmt = $pdo->prepare(
        'UPDATE news_items
         SET title = :title, content = :content, image_url = :image_url, published_at = :published_at, is_published = :is_published
         WHERE id = :id'
    );
    $stmt->execute([
        'id' => $id,
        'title' => $title,
        'content' => $content,
        'image_url' => $imageUrl !== '' ? $imageUrl : null,
        'published_at' => $publishedAt,
        'is_published' => $isPublished,
    ]);
    Response::json(['ok' => true]);
}

if ($method === 'DELETE' && preg_match('#^/admin/news/(\d+)$#', $path, $m)) {
    requireAdminOrStaff($config);
    $id = (int)$m[1];
    $stmt = $pdo->prepare('DELETE FROM news_items WHERE id = :id');
    $stmt->execute(['id' => $id]);
    Response::json(['ok' => true]);
}

if ($method === 'POST' && $path === '/admin/staff') {
    requireAdminOrStaff($config);
    $input = getJsonInput();
    $fullName = trim((string)($input['full_name'] ?? ''));
    $positionTitle = trim((string)($input['position_title'] ?? ''));
    if ($fullName === '' || $positionTitle === '') {
        Response::json(['ok' => false, 'message' => 'full_name and position_title are required'], 422);
    }

    $stmt = $pdo->prepare(
        'INSERT INTO staff_members(full_name, position_title, email, phone, office_hours, photo_url, sort_order, is_published)
         VALUES (:full_name, :position_title, :email, :phone, :office_hours, :photo_url, :sort_order, :is_published)'
    );
    $stmt->execute([
        'full_name' => $fullName,
        'position_title' => $positionTitle,
        'email' => trim((string)($input['email'] ?? '')) ?: null,
        'phone' => trim((string)($input['phone'] ?? '')) ?: null,
        'office_hours' => trim((string)($input['office_hours'] ?? '')) ?: null,
        'photo_url' => trim((string)($input['photo_url'] ?? '')) ?: null,
        'sort_order' => (int)($input['sort_order'] ?? 0),
        'is_published' => !empty($input['is_published']) ? 1 : 0,
    ]);
    Response::json(['ok' => true, 'id' => (int)$pdo->lastInsertId()], 201);
}

if ($method === 'PUT' && preg_match('#^/admin/staff/(\d+)$#', $path, $m)) {
    requireAdminOrStaff($config);
    $id = (int)$m[1];
    $input = getJsonInput();
    $fullName = trim((string)($input['full_name'] ?? ''));
    $positionTitle = trim((string)($input['position_title'] ?? ''));
    if ($fullName === '' || $positionTitle === '') {
        Response::json(['ok' => false, 'message' => 'full_name and position_title are required'], 422);
    }

    $stmt = $pdo->prepare(
        'UPDATE staff_members
         SET full_name = :full_name, position_title = :position_title, email = :email, phone = :phone,
             office_hours = :office_hours, photo_url = :photo_url, sort_order = :sort_order, is_published = :is_published
         WHERE id = :id'
    );
    $stmt->execute([
        'id' => $id,
        'full_name' => $fullName,
        'position_title' => $positionTitle,
        'email' => trim((string)($input['email'] ?? '')) ?: null,
        'phone' => trim((string)($input['phone'] ?? '')) ?: null,
        'office_hours' => trim((string)($input['office_hours'] ?? '')) ?: null,
        'photo_url' => trim((string)($input['photo_url'] ?? '')) ?: null,
        'sort_order' => (int)($input['sort_order'] ?? 0),
        'is_published' => !empty($input['is_published']) ? 1 : 0,
    ]);
    Response::json(['ok' => true]);
}

if ($method === 'DELETE' && preg_match('#^/admin/staff/(\d+)$#', $path, $m)) {
    requireAdminOrStaff($config);
    $id = (int)$m[1];
    $stmt = $pdo->prepare('DELETE FROM staff_members WHERE id = :id');
    $stmt->execute(['id' => $id]);
    Response::json(['ok' => true]);
}

Response::json(['ok' => false, 'message' => 'Route not found'], 404);

/**
 * @return array{url:string,original_name:string,mime:string,size_bytes:int}|null
 */
function savePublicApplicationFile(array $file): ?array
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
    $mime = detectUploadedMimeType($tmp, $orig, (string)($file['type'] ?? ''));
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
    $uploadsDir = __DIR__ . '/uploads';
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

function detectUploadedMimeType(string $tmpPath, string $originalName, string $browserMime): string
{
    if (function_exists('mime_content_type')) {
        $m = @mime_content_type($tmpPath);
        if (is_string($m) && $m !== '') {
            return $m;
        }
    }
    if (function_exists('finfo_open')) {
        $finfo = @finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo !== false) {
            $m = @finfo_file($finfo, $tmpPath);
            @finfo_close($finfo);
            if (is_string($m) && $m !== '') {
                return $m;
            }
        }
    }
    $ext = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
    return match ($ext) {
        'jpg', 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        default => $browserMime,
    };
}

function applicationsFilesTableExists(PDO $pdo): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    try {
        $stmt = $pdo->query("SHOW TABLES LIKE 'application_files'");
        $exists = (bool)$stmt->fetch(PDO::FETCH_NUM);
    } catch (Throwable $e) {
        $exists = false;
    }
    return $exists;
}

function getJsonInput(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || $raw === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function getRoleIdByCode(PDO $pdo, string $code): int
{
    $stmt = $pdo->prepare('SELECT id FROM roles WHERE code = :code LIMIT 1');
    $stmt->execute(['code' => $code]);
    $row = $stmt->fetch();
    if (!$row) {
        throw new RuntimeException("Role not found: {$code}");
    }
    return (int)$row['id'];
}

function requireAdminOrStaff(array $config): array
{
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
        Response::json(['ok' => false, 'message' => 'Missing Bearer token'], 401);
    }

    $payload = verifyJwtToken($m[1], (string)$config['jwt']['secret']);
    $roles = $payload['roles'] ?? [];
    if (!is_array($roles)) {
        $roles = [];
    }
    if (!in_array('admin', $roles, true) && !in_array('staff', $roles, true)) {
        Response::json(['ok' => false, 'message' => 'Forbidden'], 403);
    }
    return $payload;
}

function requireRoles(array $config, array $allowedRoles): array
{
    $payload = requireAdminOrStaffOrAny($config);
    $roles = $payload['roles'] ?? [];
    if (!is_array($roles)) {
        $roles = [];
    }
    foreach ($allowedRoles as $role) {
        if (in_array((string)$role, $roles, true)) {
            return $payload;
        }
    }
    Response::json(['ok' => false, 'message' => 'Forbidden'], 403);
}

function requireAdminOrStaffOrAny(array $config): array
{
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+(.+)$/i', $authHeader, $m)) {
        Response::json(['ok' => false, 'message' => 'Missing Bearer token'], 401);
    }
    return verifyJwtToken($m[1], (string)$config['jwt']['secret']);
}

function verifyJwtToken(string $token, string $secret): array
{
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        Response::json(['ok' => false, 'message' => 'Invalid token'], 401);
    }
    [$encodedHeader, $encodedPayload, $encodedSignature] = $parts;

    $expectedSignature = hash_hmac('sha256', $encodedHeader . '.' . $encodedPayload, $secret, true);
    $providedSignature = base64UrlDecode($encodedSignature);
    if (!hash_equals($expectedSignature, $providedSignature)) {
        Response::json(['ok' => false, 'message' => 'Invalid token signature'], 401);
    }

    $payloadJson = base64UrlDecode($encodedPayload);
    $payload = json_decode($payloadJson, true);
    if (!is_array($payload)) {
        Response::json(['ok' => false, 'message' => 'Invalid token payload'], 401);
    }

    $exp = (int)($payload['exp'] ?? 0);
    if ($exp > 0 && time() >= $exp) {
        Response::json(['ok' => false, 'message' => 'Token expired'], 401);
    }

    return $payload;
}

function base64UrlDecode(string $value): string
{
    $value = strtr($value, '-_', '+/');
    $padding = strlen($value) % 4;
    if ($padding > 0) {
        $value .= str_repeat('=', 4 - $padding);
    }
    $decoded = base64_decode($value, true);
    return $decoded === false ? '' : $decoded;
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
