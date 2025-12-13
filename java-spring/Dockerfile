# ---- Build stage ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -q -DskipTests package

# ---- Runtime stage ----
FROM eclipse-temurin:21-jre-alpine
WORKDIR /opt/app

# curl is required for container healthcheck
RUN apk add --no-cache curl && \
    addgroup -S app && adduser -S app -G app

COPY --from=build /workspace/target/*.jar /opt/app/app.jar
COPY docker/entrypoint.sh /opt/app/entrypoint.sh
RUN chmod +x /opt/app/entrypoint.sh

USER app:app
EXPOSE 8080 8081

# JVM ergonomics for containers
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:InitialRAMPercentage=25 -Djava.security.egd=file:/dev/./urandom"

ENTRYPOINT ["/opt/app/entrypoint.sh"]
