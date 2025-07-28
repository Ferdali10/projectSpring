













# Étape 1 : Build avec Maven + JDK 17
FROM maven:3.8.6-eclipse-temurin-17 AS build

# Configuration réseau
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf && \
    echo "networkaddress.cache.ttl=60" >> ${JAVA_HOME}/conf/security/java.security

WORKDIR /app

# Copie des fichiers de build
COPY pom.xml .
COPY src ./src

# Build avec cache des dépendances
RUN mvn dependency:go-offline -B && \
    mvn package -DskipTests -B

# Étape 2 : Image runtime
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Récupération du JAR
COPY --from=build /app/target/springFoyer-*.jar app.jar

# Configuration
ENV TZ=Africa/Tunis \
    SPRING_DATASOURCE_URL=${DB_URL} \
    SPRING_DATASOURCE_USERNAME=${DB_USER} \
    SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}

EXPOSE 8081

# Sécurité
RUN useradd -m springuser && \
    chown springuser: /app && \
    chmod 755 /app

USER springuser

# Démarrage
ENTRYPOINT ["java", "-jar", "app.jar", "--server.port=8081"]


