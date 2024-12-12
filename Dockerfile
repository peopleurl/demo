FROM harbor.deployers.cn/library/maven:3.9.9

WORKDIR /app

COPY target/*.jar /app/app.jar

EXPOSE 8080

CMD ["java", "-jar", "/app/app.jar"]
