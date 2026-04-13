<?php

declare(strict_types=1);

final class SmtpMailer
{
    public static function send(array $smtp, string $to, string $subject, string $textBody): void
    {
        $host = (string)($smtp['host'] ?? '');
        $port = (int)($smtp['port'] ?? 587);
        $username = (string)($smtp['username'] ?? '');
        $password = str_replace(' ', '', (string)($smtp['password'] ?? ''));
        $encryption = (string)($smtp['encryption'] ?? 'tls');
        $fromEmail = (string)($smtp['from_email'] ?? $username);
        $fromName = (string)($smtp['from_name'] ?? 'Career Center');

        if ($host === '' || $fromEmail === '' || $to === '') {
            throw new RuntimeException('SMTP config is incomplete');
        }

        $socket = @fsockopen($host, $port, $errno, $errstr, 10.0);
        if (!$socket) {
            throw new RuntimeException("SMTP connect failed: {$errno} {$errstr}");
        }
        stream_set_timeout($socket, 10);

        self::expect($socket, [220]);
        self::cmd($socket, 'EHLO localhost');
        $ehlo = self::readMultiline($socket);

        if ($encryption === 'tls') {
            if (stripos($ehlo, 'STARTTLS') === false) {
                throw new RuntimeException('SMTP server does not support STARTTLS');
            }
            self::cmd($socket, 'STARTTLS');
            self::expect($socket, [220]);
            if (!stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
                throw new RuntimeException('Failed to enable TLS');
            }
            self::cmd($socket, 'EHLO localhost');
            self::readMultiline($socket);
        }

        if ($username !== '') {
            self::cmd($socket, 'AUTH LOGIN');
            self::expect($socket, [334]);
            self::cmd($socket, base64_encode($username));
            self::expect($socket, [334]);
            self::cmd($socket, base64_encode($password));
            self::expect($socket, [235]);
        }

        self::cmd($socket, 'MAIL FROM:<' . $fromEmail . '>');
        self::expect($socket, [250]);
        self::cmd($socket, 'RCPT TO:<' . $to . '>');
        self::expect($socket, [250, 251]);
        self::cmd($socket, 'DATA');
        self::expect($socket, [354]);

        $headers = [
            'From: ' . self::encodeHeader($fromName) . " <{$fromEmail}>",
            'To: <' . $to . '>',
            'Subject: ' . self::encodeHeader($subject),
            'MIME-Version: 1.0',
            'Content-Type: text/plain; charset=utf-8',
            'Content-Transfer-Encoding: 8bit',
        ];

        $message = implode("\r\n", $headers) . "\r\n\r\n" . $textBody . "\r\n";
        $message = str_replace("\n.", "\n..", $message); // dot-stuffing
        fwrite($socket, $message . "\r\n.\r\n");
        self::expect($socket, [250]);

        self::cmd($socket, 'QUIT');
        fclose($socket);
    }

    private static function encodeHeader(string $value): string
    {
        if ($value === '') {
            return '';
        }
        if (!preg_match('/[^\x20-\x7E]/', $value)) {
            return $value;
        }
        return '=?UTF-8?B?' . base64_encode($value) . '?=';
    }

    private static function cmd($socket, string $line): void
    {
        fwrite($socket, $line . "\r\n");
    }

    private static function expect($socket, array $codes): void
    {
        $line = fgets($socket);
        if ($line === false) {
            throw new RuntimeException('SMTP read failed');
        }
        $code = (int)substr($line, 0, 3);
        if (!in_array($code, $codes, true)) {
            throw new RuntimeException('SMTP unexpected response: ' . trim($line));
        }
    }

    private static function readMultiline($socket): string
    {
        $out = '';
        while (true) {
            $line = fgets($socket);
            if ($line === false) {
                break;
            }
            $out .= $line;
            // multiline: "250-" continues, "250 " ends
            if (preg_match('/^\d{3}\s/', $line)) {
                break;
            }
        }
        return $out;
    }
}

