<?php

declare(strict_types=1);

/**
 * Собирает повторяющиеся строки из POST вида prefix_key[] (например stat_icon[], stat_value[]).
 *
 * @param array<string, mixed> $post
 * @param list<string> $keys Порядок полей в JSON (например icon, value, label, color)
 * @return list<array<string, string>>
 */
function cms_collect_indexed_rows(array $post, string $prefix, array $keys): array
{
    if ($keys === []) {
        return [];
    }
    $firstKey = $keys[0];
    $firstArr = $post[$prefix . $firstKey] ?? null;
    if (!is_array($firstArr)) {
        return [];
    }
    $n = count($firstArr);
    $out = [];
    for ($i = 0; $i < $n; $i++) {
        $row = [];
        foreach ($keys as $k) {
            $arr = $post[$prefix . $k] ?? null;
            $row[$k] = is_array($arr) ? trim((string)($arr[$i] ?? '')) : '';
        }
        $nonEmpty = false;
        foreach ($row as $v) {
            if ($v !== '') {
                $nonEmpty = true;
                break;
            }
        }
        if ($nonEmpty) {
            $out[] = $row;
        }
    }
    return $out;
}

/** @return array<string, string> */
function cms_icon_options_stats(): array
{
    return [
        'people' => 'Люди',
        'auto_stories' => 'Книги / программы',
        'emoji_events' => 'Награда',
        'business' => 'Здание / организация',
        'school' => 'Учёба',
        'groups' => 'Группы',
    ];
}

/** @return array<string, string> */
function cms_icon_options_cards(): array
{
    return [
        'rocket_launch' => 'Ракета',
        'computer' => 'Компьютер',
        'handshake' => 'Рукопожатие',
        'trending_up' => 'Рост',
        'military_tech' => 'Награды / военная техника',
        'workspace_premium' => 'Премиум / качество',
        'science' => 'Наука',
        'diversity_3' => 'Люди / сообщество',
        'engineering' => 'Инженерия',
        'school' => 'Учёба',
    ];
}

/**
 * @param array<string, string> $options
 */
function cms_render_icon_select(string $name, string $value, array $options): string
{
    $html = '<select name="' . h($name) . '" style="width:100%;padding:8px;border:1px solid #d1d5db;border-radius:8px;">';
    $html .= '<option value="">—</option>';
    foreach ($options as $k => $label) {
        $sel = $k === $value ? ' selected' : '';
        $html .= '<option value="' . h($k) . '"' . $sel . '>' . h($label) . ' (' . h($k) . ')</option>';
    }
    $html .= '</select>';
    return $html;
}
