# Minimal baseline with persistence and safety.
port ${REDIS_PORT}
bind ${REDIS_BIND}
protected-mode yes

# Auth (filled by entrypoint)
requirepass __REDIS_PASSWORD__

# Persistence
appendonly yes
appendfsync everysec
dir /data

# Performance defaults
tcp-keepalive 60
timeout 0
databases 16

# Memory policy (set if you actually manage memory limits)
# maxmemory 0
# maxmemory-policy noeviction

# Safer operational defaults
save 900 1
save 300 10
save 60 10000
