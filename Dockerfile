# Étape 1 : Build avec Maven + JDK 17 (avec cache des dépendances)
FROM maven:3.8.6-eclipse-temurin-17 AS build

# Configuration DNS et réseau
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf && \
    echo "networkaddress.cache.ttl=60" >> ${JAVA_HOME}/conf/security/java.security

WORKDIR /app

# Copie séparée du POM pour exploiter le cache Docker
COPY pom.xml .
RUN mvn dependency:go-offline -Dmaven.wagon.http.retryHandler.count=5

# Copie du code source et build
COPY src ./src
RUN mvn package -DskipTests \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=25 \
    -Dmaven.wagon.http.retryHandler.count=3

# Étape 2 : Image runtime optimisée
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

ARG JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar
COPY --from=build /app/target/${JAR_FILE} app.jar

# Configuration Spring (injectée par Jenkins)
ENV SPRING_DATASOURCE_URL=${DB_URL} \
    SPRING_DATASOURCE_USERNAME=${DB_USER} \
    SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD} \
    TZ=Africa/Tunis

EXPOSE 8081

# Sécurité : exécution avec utilisateur non-root
RUN useradd -m myuser && chown myuser:myuser /app
USER myuser

ENTRYPOINT ["java", "-jar", "app.jar"]















