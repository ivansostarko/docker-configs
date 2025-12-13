<?php
/**
 * Passbolt override configuration (optional).
 *
 * Prefer environment variables for infra + secrets in containerized deployments.
 * This file is here for completeness (and for settings you explicitly want in file form).
 *
 * Place at: ./config/passbolt/passbolt.php
 * Mount to: /etc/passbolt/passbolt.php (see docker-compose.yml)
 */
return [
    // Example:
    // 'passbolt' => [
    //     'plugins' => [
    //         'selfRegistration' => [
    //             'enabled' => false,
    //         ],
    //     ],
    // ],
];
