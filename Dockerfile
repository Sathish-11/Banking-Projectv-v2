FROM maven:3.8.4-openjdk-17 AS builder

WORKDIR /app

COPY .mvn mvnw pom.xml ./

COPY src ./src

RUN chmod +x mvnw && ./mvnw clean package -DskipTests

FROM openjdk:17-jdk-alpine

WORKDIR /app

COPY --from=builder /app/target/*.jar ./app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar","/app/app.jar"]

