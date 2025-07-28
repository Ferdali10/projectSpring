# Étape 1 : Build avec Maven + JDK 17 (avec cache des dépendances)
FROM maven:3.8.6-eclipse-temurin-17 AS build

# Configuration DNS (en cas de problèmes de résolution)
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf

# Configuration JVM pour éviter les timeouts réseau trop courts
RUN echo "networkaddress.cache.ttl=60" >> ${JAVA_HOME}/conf/security/java.security

WORKDIR /app

# Étape intermédiaire pour profiter du cache Docker
COPY pom.xml ./

# Télécharger les dépendances Maven avec tolérance aux erreurs réseau
RUN mvn dependency:go-offline \
    -Dmaven.wagon.http.retryHandler.count=5 \
    -Dmaven.wagon.httpconnectionManager.ttlSeconds=120 \
    -Dmaven.wagon.http.timeout=120000 \
    -B || echo "⚠️ La commande dependency:go-offline a échoué, mais on continue..."

# Copie du code source
COPY src ./src

# Build du projet
RUN mvn package -DskipTests -B \
    -Dmaven.wagon.http.retryHandler.count=3 \
    -Dmaven.wagon.http.timeout=120000

# Étape 2 : Image runtime optimisée avec JRE uniquement
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Récupération du JAR depuis l'étape précédente
ARG JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar
COPY --from=build /app/target/${JAR_FILE} app.jar

# Variables d'environnement injectées depuis Jenkins
ENV SPRING_DATASOURCE_URL=${DB_URL} \
    SPRING_DATASOURCE_USERNAME=${DB_USER} \
    SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD} \
    TZ=Africa/Tunis

EXPOSE 8081

# Sécurité : exécuter l'application avec un utilisateur non-root
RUN useradd -m springuser && chown springuser: /app
USER springuser

# Commande de démarrage
ENTRYPOINT ["java", "-jar", "app.jar","--server.port=8081"]
















