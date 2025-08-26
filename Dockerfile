FROM maven:3.8.5-openjdk-17 As builder

WORKDIR /app

COPY pom.xml ./

COPY src /app/src

RUN mvn clean package

FROM openjdk:17-jdk-alpine

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"] 
