# Étape 1 : Build avec Maven + JDK 17
FROM maven:3.8.6-eclipse-temurin-17 AS build

# Configuration des DNS pour résoudre les problèmes de résolution
RUN echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
    echo "nameserver 8.8.4.4" >> /etc/resolv.conf

WORKDIR /app

# Copie du pom.xml et téléchargement des dépendances
COPY pom.xml .

# Téléchargement des dépendances avec retry et timeout
RUN mvn dependency:go-offline -B -Dmaven.repo.local=/root/.m2/repository || \
    (sleep 5 && mvn dependency:go-offline -B -Dmaven.repo.local=/root/.m2/repository) || \
    (sleep 10 && mvn dependency:go-offline -B -Dmaven.repo.local=/root/.m2/repository)

# Copie du code source
COPY src ./src

# Build du projet
RUN mvn package -DskipTests -B -Dmaven.repo.local=/root/.m2/repository

# Étape 2 : Image runtime avec OpenJDK 17
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Argument pour le nom du fichier JAR
ARG JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar

# Copie du JAR depuis l'étape de build
COPY --from=build /app/target/${JAR_FILE} app.jar

# Variables d'environnement pour Spring Boot
ENV SPRING_DATASOURCE_URL=${DB_URL} \
    SPRING_DATASOURCE_USERNAME=${DB_USER} \
    SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}

# Exposition du port
EXPOSE 8081

# Point d'entrée
ENTRYPOINT ["java", "-jar", "app.jar"]





