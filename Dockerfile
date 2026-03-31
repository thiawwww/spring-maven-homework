# ==========================================================
# STAGE 1 : BUILD
# Utilise Maven + JDK pour compiler l'application
# ==========================================================
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copier pom.xml en premier pour exploiter le cache Docker
COPY pom.xml .

# Télécharger les dépendances sans compiler
RUN mvn dependency:go-offline -B

# Copier le code source
COPY src ./src

# Compiler et packager (tests exécutés plus tard dans la CI)
RUN mvn clean package -DskipTests -B

# ==========================================================
# STAGE 2 : RUNTIME
# Image légère avec seulement le JRE
# ==========================================================
FROM eclipse-temurin:17-jre-alpine AS runtime

LABEL maintainer="thiaw@exemple.com"
LABEL version="1.0"
LABEL description="Spring Boot Application"

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copier UNIQUEMENT le JAR depuis le stage de build
COPY --from=builder /app/target/*.jar app.jar

# Donner les droits à l'utilisateur non-root
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseContainerSupport"
ENV SPRING_PROFILES_ACTIVE=prod

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
