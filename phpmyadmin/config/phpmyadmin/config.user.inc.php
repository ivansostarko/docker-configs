<?php
/**
 * phpMyAdmin user configuration overrides.
 * This file is mounted into the container via Docker configs.
 *
 * NOTE:
 * - Do not hardcode sensitive secrets here for public repos.
 * - Prefer environment variables or secrets.
 */

$cfg['blowfish_secret'] = getenv('PMA_BLOWFISH_SECRET') ?: 'CHANGE_ME_TO_A_LONG_RANDOM_VALUE';

// Enforce non-empty passwords
$cfg['Servers'][1]['AllowNoPassword'] = false;

// Quality-of-life defaults
$cfg['Servers'][1]['compress'] = true;

// Import/execution guardrails
$cfg['ExecTimeLimit'] = (int)(getenv('MAX_EXECUTION_TIME') ?: 300);
