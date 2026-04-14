<?php

require_once __DIR__ . '/../src/SmtpMailer.php';

$config = require __DIR__ . '/../config.php';

$smtp = $config['smtp'];

echo "SMTP Config:\n";
echo "- Host: {$smtp['host']}\n";
echo "- Port: {$smtp['port']}\n";
echo "- Username: {$smtp['username']}\n";
echo "- Encryption: {$smtp['encryption']}\n";
echo "- From: {$smtp['from_email']}\n\n";

try {
    echo "Testing SMTP connection...\n";
    SmtpMailer::send($smtp, 'kucersemen18@gmail.com', 'Test from AKSIBGUU', '<h1>Test</h1><p>This is a test email from your app.</p>', true);
    echo "SUCCESS: Email sent!\n";
} catch (Throwable $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}