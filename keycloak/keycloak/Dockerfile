ARG KEYCLOAK_VERSION=26.4.7

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} as builder
ENV KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

USER root
# Install curl for healthchecks
RUN microdnf install -y curl && microdnf clean all

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY scripts/entrypoint.sh /opt/keycloak/bin/entrypoint.sh
RUN chmod 0755 /opt/keycloak/bin/entrypoint.sh && \
    chown -R keycloak:keycloak /opt/keycloak

USER keycloak

ENTRYPOINT ["/opt/keycloak/bin/entrypoint.sh"]
CMD ["start","--optimized","--import-realm","--config-file=/opt/keycloak/conf/keycloak.conf"]
