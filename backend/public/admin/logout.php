<?php
require __DIR__ . '/_bootstrap.php';
unset($_SESSION['admin_user']);
flash('Вы вышли из админ-панели.');
redirectTo('/admin/login.php');
