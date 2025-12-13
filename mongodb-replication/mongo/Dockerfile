ARG MONGO_VERSION=7.0
FROM mongo:${MONGO_VERSION}

# Wrapper copies the keyfile from Docker secrets (read-only) to a path with strict perms for mongod.
COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-wrapper.sh

ENTRYPOINT ["docker-entrypoint-wrapper.sh"]
CMD ["mongod"]
