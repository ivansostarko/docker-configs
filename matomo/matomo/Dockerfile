ARG MATOMO_IMAGE
FROM ${MATOMO_IMAGE}

# Add a thin wrapper to read secrets from /run/secrets and export env vars Matomo expects
COPY entrypoint-with-secrets /usr/local/bin/entrypoint-with-secrets
COPY matomo-archive-loop /usr/local/bin/matomo-archive-loop

RUN chmod +x /usr/local/bin/entrypoint-with-secrets /usr/local/bin/matomo-archive-loop

ENTRYPOINT ["/usr/local/bin/entrypoint-with-secrets"]
CMD ["php-fpm"]
