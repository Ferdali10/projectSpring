# Étape 1 : Build avec Maven + JDK 17
FROM maven:3.8.6-openjdk-17 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn package -DskipTests

# Étape 2 : Image runtime avec OpenJDK 17
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Argument contenant le nom exact du JAR généré
ARG JAR_FILE=springFoyer-0.0.2-SNAPSHOT.jar

# Copier le JAR depuis l'image de build
COPY --from=build /app/target/${JAR_FILE} app.jar

# Variables d'environnement Spring (valeurs injectées par Jenkins)
ENV SPRING_DATASOURCE_URL=${DB_URL} \
    SPRING_DATASOURCE_USERNAME=${DB_USER} \
    SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]









