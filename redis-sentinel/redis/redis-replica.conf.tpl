port ${REDIS_PORT}
bind ${REDIS_BIND}
protected-mode yes

# Auth (filled by entrypoint)
requirepass __REDIS_PASSWORD__
masterauth __REDIS_PASSWORD__

# Replica config (filled by entrypoint)
replicaof ${MASTER_HOST} ${MASTER_PORT}

appendonly yes
appendfsync everysec
dir /data

tcp-keepalive 60
timeout 0
databases 16

save 900 1
save 300 10
save 60 10000
