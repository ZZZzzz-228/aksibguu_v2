<?php
require __DIR__ . '/_bootstrap.php';
requireLogin();
requireAnyRole(['admin', 'staff']);

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $title = trim((string)($_POST['title'] ?? ''));
        $company = trim((string)($_POST['company'] ?? ''));
        $city = trim((string)($_POST['city'] ?? ''));
        $employmentType = trim((string)($_POST['employment_type'] ?? ''));
        $salary = trim((string)($_POST['salary'] ?? ''));
        $description = trim((string)($_POST['description'] ?? ''));
        $isActive = isset($_POST['is_active']) ? 1 : 0;

        if ($title === '' || $company === '') {
            flash('Заполните title и company.');
            redirectTo('/admin/vacancies.php');
        }

        if ($id > 0) {
            $stmt = $pdo->prepare(
                'UPDATE vacancies
                 SET title=:title, company=:company, city=:city, employment_type=:employment_type,
                     salary=:salary, description=:description, is_active=:is_active
                 WHERE id=:id'
            );
            $stmt->execute([
                'id' => $id,
                'title' => $title,
                'company' => $company,
                'city' => $city !== '' ? $city : null,
                'employment_type' => $employmentType !== '' ? $employmentType : null,
                'salary' => $salary !== '' ? $salary : null,
                'description' => $description !== '' ? $description : null,
                'is_active' => $isActive,
            ]);
            auditLog($pdo, 'update', 'vacancy', (string)$id, [
                'title' => $title,
                'company' => $company,
                'is_active' => $isActive,
            ]);
            flash('Вакансия обновлена.');
        } else {
            $stmt = $pdo->prepare(
                'INSERT INTO vacancies(title, company, city, employment_type, salary, description, published_at, is_active)
                 VALUES (:title, :company, :city, :employment_type, :salary, :description, NOW(), :is_active)'
            );
            $stmt->execute([
                'title' => $title,
                'company' => $company,
                'city' => $city !== '' ? $city : null,
                'employment_type' => $employmentType !== '' ? $employmentType : null,
                'salary' => $salary !== '' ? $salary : null,
                'description' => $description !== '' ? $description : null,
                'is_active' => $isActive,
            ]);
            $newId = (int)$pdo->lastInsertId();
            auditLog($pdo, 'create', 'vacancy', (string)$newId, [
                'title' => $title,
                'company' => $company,
                'is_active' => $isActive,
            ]);
            flash('Вакансия добавлена.');
        }
    }

    if ($action === 'delete') {
        if (!isAdmin()) {
            flash('Удаление доступно только администратору.');
            redirectTo('/admin/vacancies.php');
        }
        $id = (int)($_POST['id'] ?? 0);
        if ($id > 0) {
            $stmt = $pdo->prepare('DELETE FROM vacancies WHERE id=:id');
            $stmt->execute(['id' => $id]);
            auditLog($pdo, 'delete', 'vacancy', (string)$id, null);
            flash('Вакансия удалена.');
        }
    }
    redirectTo('/admin/vacancies.php');
}

$editId = (int)($_GET['edit'] ?? 0);
$editItem = null;
if ($editId > 0) {
    $stmt = $pdo->prepare('SELECT * FROM vacancies WHERE id=:id LIMIT 1');
    $stmt->execute(['id' => $editId]);
    $editItem = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
}

$rows = $pdo->query('SELECT id, title, company, city, salary, is_active, published_at FROM vacancies ORDER BY id DESC')->fetchAll(PDO::FETCH_ASSOC);
$title = 'Управление вакансиями';
$user = getCurrentUser();
$canDelete = isAdmin();
require __DIR__ . '/_layout_top.php';
$msg = flash();
if ($msg): ?><div class="flash"><?= h($msg) ?></div><?php endif; ?>

<div class="card">
  <h2 style="margin-top:0;"><?= $editItem ? 'Редактировать вакансию' : 'Добавить вакансию' ?></h2>
  <form method="post">
    <input type="hidden" name="action" value="save">
    <input type="hidden" name="id" value="<?= (int)($editItem['id'] ?? 0) ?>">
    <label>Название</label>
    <input name="title" value="<?= h((string)($editItem['title'] ?? '')) ?>" required>
    <label>Компания</label>
    <input name="company" value="<?= h((string)($editItem['company'] ?? '')) ?>" required>
    <label>Город</label>
    <input name="city" value="<?= h((string)($editItem['city'] ?? '')) ?>">
    <label>Тип занятости</label>
    <input name="employment_type" value="<?= h((string)($editItem['employment_type'] ?? '')) ?>">
    <label>Зарплата</label>
    <input name="salary" value="<?= h((string)($editItem['salary'] ?? '')) ?>">
    <label>Описание</label>
    <textarea name="description"><?= h((string)($editItem['description'] ?? '')) ?></textarea>
    <label><input type="checkbox" name="is_active" <?= !empty($editItem['is_active']) ? 'checked' : '' ?>> Активна</label>
    <br><br><button type="submit">Сохранить</button>
  </form>
</div>

<div class="card">
  <h2 style="margin-top:0;">Список вакансий</h2>
  <table>
    <thead><tr><th>ID</th><th>Название</th><th>Компания</th><th>Город</th><th>Зарплата</th><th>Статус</th><th>Дата</th><th>Действия</th></tr></thead>
    <tbody>
    <?php foreach ($rows as $row): ?>
      <tr>
        <td><?= (int)$row['id'] ?></td>
        <td><?= h((string)$row['title']) ?></td>
        <td><?= h((string)$row['company']) ?></td>
        <td><?= h((string)($row['city'] ?? '')) ?></td>
        <td><?= h((string)($row['salary'] ?? '')) ?></td>
        <td><?= (int)$row['is_active'] === 1 ? 'Активна' : 'Скрыта' ?></td>
        <td><?= h((string)($row['published_at'] ?? '')) ?></td>
        <td>
          <a href="/admin/vacancies.php?edit=<?= (int)$row['id'] ?>">Редактировать</a>
          <?php if ($canDelete): ?>
            <form method="post" style="display:inline;">
              <input type="hidden" name="action" value="delete">
              <input type="hidden" name="id" value="<?= (int)$row['id'] ?>">
              <button class="danger" type="submit" onclick="return confirm('Удалить вакансию?')">Удалить</button>
            </form>
          <?php endif; ?>
        </td>
      </tr>
    <?php endforeach; ?>
    </tbody>
  </table>
</div>

<?php require __DIR__ . '/_layout_bottom.php'; ?>
