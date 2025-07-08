# Build stage
FROM maven:3.8.6-openjdk-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# Run stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
ENV SPRING_DATASOURCE_URL=${DB_URL} \
    SPRING_DATASOURCE_USERNAME=${DB_USER} \
    SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
