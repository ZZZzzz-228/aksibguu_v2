<?php

return [
    'db' => [

        'host' => 'kucersemen.temp.swtest.ru',
        'port' => '3308',
        'database' => 'kucersemen',
        'username' => 'kucersemen',
        'password' => 'pipkA228',
        'charset' => 'utf8mb4',
    ],
    'jwt' => [

        'secret' => 'dev-secret-change-me',
        'issuer' => 'career-center-api',
        'ttl_seconds' => 60 * 60 * 24,
    ],
    // Почта: заявки «Принять» и уведомления колледжу (заполни под свой SMTP) код гнилой, но работает, так что не трогай
    'smtp' => [
        'host' => 'smtp.gmail.com',
        'port' => 587,
        'username' => 'kucersemen18@gmail.com',
        'password' => 'mwdb vhxd qrlv nycv',
        'encryption' => 'tls', // tls | none
        'from_email' => 'kucersemen18@gmail.com',
        'from_name' => 'АКСИБГУ',
        'to_email' => 'priem@example.com',
    ],
];
