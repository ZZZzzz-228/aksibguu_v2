<?php

return [
    'db' => [
        'host' => '127.0.0.1',
        'port' => 3306,
        'database' => 'career_center_ak_sibgu',
        'username' => 'root',
        'password' => '',
        'charset' => 'utf8mb4',
    ],
    'jwt' => [
        'secret' => 'change-me-to-long-random-secret',
        'issuer' => 'career-center-api',
        'ttl_seconds' => 60 * 60 * 24,
    ],
    // host не должен быть smtp.example.com — это несуществующий адрес. Для Gmail: smtp.gmail.com
    'smtp' => [
        'host' => 'smtp.gmail.com',
        'port' => 587,
        'username' => 'you@gmail.com',
        'password' => 'xxxxxxxxxxxxxxxx',
        'encryption' => 'tls',
        'from_email' => 'you@gmail.com',
        'from_name' => 'АКСИБГУ',
        'to_email' => 'you@gmail.com',
    ],
];
