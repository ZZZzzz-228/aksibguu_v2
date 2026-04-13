<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
if (!canManageAdmissions()) {
    flash('Недостаточно прав для раздела студентов.');
    redirectTo('/admin/index.php');
}

$id = (int)($_GET['id'] ?? 0);
if ($id <= 0) {
    flash('Не указан студент.');
    redirectTo('/admin/students.php');
}

$stmt = $pdo->prepare(
    "SELECT u.id, u.full_name, u.email, u.phone, u.created_at, u.is_active,
            sp.student_code, sp.bio, sp.avatar_url, sp.portfolio_public,
            g.id AS group_id, g.code AS group_code, g.title AS group_title,
            s.title AS specialty_title
     FROM users u
     JOIN user_roles ur ON ur.user_id = u.id
     JOIN roles r ON r.id = ur.role_id AND r.code = 'student'
     LEFT JOIN student_profiles sp ON sp.user_id = u.id
     LEFT JOIN groups_ref g ON g.id = sp.group_id
     LEFT JOIN specialties s ON s.id = g.specialty_id
     WHERE u.id = :id
     LIMIT 1"
);
$stmt->execute(['id' => $id]);
$row = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$row) {
    flash('Студент не найден.');
    redirectTo('/admin/students.php');
}

$resumes = $pdo->prepare('SELECT id, title, summary, is_published, created_at FROM student_resumes WHERE student_user_id = :u ORDER BY id DESC');
$resumes->execute(['u' => $id]);
$resumes = $resumes->fetchAll(PDO::FETCH_ASSOC);

$portfolio = $pdo->prepare('SELECT id, title, description, project_url, is_published, sort_order FROM student_portfolio_items WHERE student_user_id = :u ORDER BY sort_order ASC, id DESC');
$portfolio->execute(['u' => $id]);
$portfolio = $portfolio->fetchAll(PDO::FETCH_ASSOC);

$title = 'Студент: ' . $row['full_name'];
$user = getCurrentUser();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <p><a href="/admin/students.php" class="btn btnGhost">← К списку</a></p>
  <h2><?= h((string)$row['full_name']) ?></h2>
  <p class="muted">ID: <?= (int)$row['id'] ?> · <?= (int)$row['is_active'] === 1 ? 'Активен' : 'Отключён' ?></p>
  <p><strong>Email:</strong> <?= h((string)$row['email']) ?></p>
  <p><strong>Телефон:</strong> <?= h((string)($row['phone'] ?? '')) ?></p>
  <p><strong>Номер зачётки:</strong> <?= h((string)($row['student_code'] ?? '—')) ?></p>
  <p><strong>Группа:</strong> <?= h((string)($row['group_title'] ?? '—')) ?> <?= $row['group_code'] ? '(' . h((string)$row['group_code']) . ')' : '' ?></p>
  <p><strong>Специальность:</strong> <?= h((string)($row['specialty_title'] ?? '—')) ?></p>
  <p><strong>Дата регистрации:</strong> <?= h((string)$row['created_at']) ?></p>
  <?php if (!empty($row['bio'])): ?>
    <p><strong>О себе:</strong> <?= nl2br(h((string)$row['bio'])) ?></p>
  <?php endif; ?>
  <?php if (!empty($row['avatar_url'])): ?>
    <p><img src="<?= h((string)$row['avatar_url']) ?>" alt="" style="max-width:160px;border-radius:12px;"></p>
  <?php endif; ?>
</div>

<div class="card">
  <h2>Резюме</h2>
  <?php if (!$resumes): ?>
    <p class="muted">Нет записей.</p>
  <?php else: ?>
    <ul>
      <?php foreach ($resumes as $r): ?>
        <li><strong><?= h((string)$r['title']) ?></strong> — <?= !empty($r['is_published']) ? 'опубликовано' : 'скрыто' ?>
          <div class="muted" style="font-size:12px;"><?= h((string)$r['created_at']) ?></div>
          <pre style="white-space:pre-wrap;font-size:13px;background:#f8fafc;padding:8px;border-radius:8px;"><?= h((string)($r['summary'] ?? '')) ?></pre>
        </li>
      <?php endforeach; ?>
    </ul>
  <?php endif; ?>
</div>

<div class="card">
  <h2>Портфолио</h2>
  <?php if (!$portfolio): ?>
    <p class="muted">Нет работ.</p>
  <?php else: ?>
    <ul>
      <?php foreach ($portfolio as $p): ?>
        <li>
          <strong><?= h((string)$p['title']) ?></strong>
          <?php if (!empty($p['project_url'])): ?> — <a href="<?= h((string)$p['project_url']) ?>" target="_blank" rel="noopener">ссылка</a><?php endif; ?>
          <?php if (!empty($p['description'])): ?>
            <div class="muted"><?= nl2br(h((string)$p['description'])) ?></div>
          <?php endif; ?>
        </li>
      <?php endforeach; ?>
    </ul>
  <?php endif; ?>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
