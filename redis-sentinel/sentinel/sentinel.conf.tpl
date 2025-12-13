port ${SENTINEL_PORT}
bind 0.0.0.0
protected-mode yes

# Monitor the master
sentinel monitor ${SENTINEL_MONITOR_NAME} ${MASTER_HOST} ${MASTER_PORT} ${SENTINEL_QUORUM}

# Auth to talk to Redis master/replicas
sentinel auth-pass ${SENTINEL_MONITOR_NAME} __REDIS_PASSWORD__

# Failover tuning
sentinel down-after-milliseconds ${SENTINEL_MONITOR_NAME} ${DOWN_AFTER_MS}
sentinel failover-timeout ${SENTINEL_MONITOR_NAME} ${FAILOVER_TIMEOUT_MS}
sentinel parallel-syncs ${SENTINEL_MONITOR_NAME} ${PARALLEL_SYNCS}

# Optional: resolve hostnames
sentinel resolve-hostnames yes
sentinel announce-hostnames yes
