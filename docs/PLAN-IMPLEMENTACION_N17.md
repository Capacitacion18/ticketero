# Plan Detallado de Implementación - Sistema Ticketero

**Proyecto:** Sistema de Gestión de Tickets con Notificaciones en Tiempo Real  
**Versión:** 1.0  
**Fecha:** Diciembre 2025  
**Tech Lead:** Tech Lead Senior

---

## 1. Introducción

### 1.1 Propósito

Este documento presenta el plan de implementación paso a paso del Sistema Ticketero Digital. Cualquier desarrollador mid-level puede seguir este plan para construir el sistema completo sin necesidad de consultar documentación adicional.

### 1.2 Objetivo

Implementar un sistema funcional que cumpla con los 8 Requerimientos Funcionales (RF-001 a RF-008) definidos en el documento de Requerimientos Funcionales, siguiendo la arquitectura especificada en el documento de Arquitectura.

### 1.3 Tiempo Estimado

**Total:** 11 horas de implementación distribuidas en 3 días:
- **Día 1:** 4 horas (Setup + Migraciones + Entities + DTOs + Repositories)
- **Día 2:** 5 horas (Services + Controllers)
- **Día 3:** 2 horas (Schedulers + Testing E2E)

### 1.4 Stack Tecnológico

- **Backend:** Java 21 + Spring Boot 3.2.11
- **Base de Datos:** PostgreSQL 16
- **Migraciones:** Flyway
- **Build Tool:** Maven 3.9+
- **Containerización:** Docker + Docker Compose
- **Integración:** Telegram Bot API + RestTemplate

---

## 2. Estructura del Proyecto

### 2.1 Árbol de Directorios Completo

```
ticketero/
├── pom.xml                                    # Maven configuration
├── .env                                       # Variables de entorno (gitignored)
├── docker-compose.yml                         # PostgreSQL + API
├── Dockerfile                                 # Multi-stage build
├── README.md                                  # Instrucciones del proyecto
│
├── src/
│   ├── main/
│   │   ├── java/com/example/ticketero/
│   │   │   │
│   │   │   ├── TicketeroApplication.java    # Main class con @EnableScheduling
│   │   │   │
│   │   │   ├── controller/                   # REST Controllers
│   │   │   │   ├── TicketController.java
│   │   │   │   └── AdminController.java
│   │   │   │
│   │   │   ├── service/                      # Business Logic
│   │   │   │   ├── TicketService.java
│   │   │   │   ├── TelegramService.java
│   │   │   │   ├── QueueManagementService.java
│   │   │   │   ├── AdvisorService.java
│   │   │   │   └── NotificationService.java
│   │   │   │
│   │   │   ├── repository/                   # Data Access
│   │   │   │   ├── TicketRepository.java
│   │   │   │   ├── MensajeRepository.java
│   │   │   │   └── AdvisorRepository.java
│   │   │   │
│   │   │   ├── model/
│   │   │   │   ├── entity/                   # JPA Entities
│   │   │   │   │   ├── Ticket.java
│   │   │   │   │   ├── Mensaje.java
│   │   │   │   │   └── Advisor.java
│   │   │   │   │
│   │   │   │   ├── dto/                      # DTOs
│   │   │   │   │   ├── TicketCreateRequest.java
│   │   │   │   │   ├── TicketResponse.java
│   │   │   │   │   ├── QueuePositionResponse.java
│   │   │   │   │   ├── DashboardResponse.java
│   │   │   │   │   └── QueueStatusResponse.java
│   │   │   │   │
│   │   │   │   └── enums/                    # Enumerations
│   │   │   │       ├── QueueType.java
│   │   │   │       ├── TicketStatus.java
│   │   │   │       ├── AdvisorStatus.java
│   │   │   │       └── MessageTemplate.java
│   │   │   │
│   │   │   ├── scheduler/                    # Scheduled Tasks
│   │   │   │   ├── MensajeScheduler.java
│   │   │   │   └── QueueProcessorScheduler.java
│   │   │   │
│   │   │   ├── config/                       # Configuration
│   │   │   │   ├── RestTemplateConfig.java
│   │   │   │   └── TelegramConfig.java
│   │   │   │
│   │   │   └── exception/                    # Exception Handling
│   │   │       ├── TicketNotFoundException.java
│   │   │       ├── TicketActivoExistenteException.java
│   │   │       └── GlobalExceptionHandler.java
│   │   │
│   │   └── resources/
│   │       ├── application.yml               # Spring Boot config
│   │       ├── application-dev.yml           # Dev profile
│   │       ├── application-prod.yml          # Prod profile
│   │       │
│   │       └── db/migration/                 # Flyway migrations
│   │           ├── V1__create_ticket_table.sql
│   │           ├── V2__create_mensaje_table.sql
│   │           └── V3__create_advisor_table.sql
│   │
│   └── test/
│       └── java/com/example/ticketero/
│           ├── service/
│           │   ├── TicketServiceTest.java
│           │   └── TelegramServiceTest.java
│           │
│           └── controller/
│               └── TicketControllerTest.java
│
└── docs/                                      # Documentación
    ├── REQUERIMIENTOS-NEGOCIO.md
    ├── REQUERIMIENTOS-FUNCIONALES.md
    ├── ARQUITECTURA.md
    └── diagrams/
        ├── 01-context-diagram.puml
        ├── 02-sequence-diagram.puml
        └── 03-er-diagram.puml
```

**Total de archivos Java:** 42 archivos
- **Entities:** 3 archivos
- **DTOs:** 5 archivos  
- **Enums:** 4 archivos
- **Repositories:** 3 archivos
- **Services:** 5 archivos
- **Controllers:** 2 archivos
- **Schedulers:** 2 archivos
- **Config:** 2 archivos
- **Exceptions:** 3 archivos
- **Main:** 1 archivo
- **Tests:** 12 archivos

---

## 3. Configuración Inicial

### 3.1 pom.xml (Maven Configuration)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.11</version>
        <relativePath/>
    </parent>

    <groupId>com.example</groupId>
    <artifactId>ticketero</artifactId>
    <version>1.0.0</version>
    <name>Ticketero API</name>
    <description>Sistema de Gestión de Tickets con Notificaciones en Tiempo Real</description>

    <properties>
        <java.version>21</java.version>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
    </properties>

    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>

        <!-- PostgreSQL Driver -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>

        <!-- Flyway for Database Migrations -->
        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-core</artifactId>
        </dependency>

        <dependency>
            <groupId>org.flywaydb</groupId>
            <artifactId>flyway-database-postgresql</artifactId>
        </dependency>

        <!-- Lombok -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>

        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>

        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

### 3.2 application.yml

```yaml
spring:
  application:
    name: ticketero-api

  datasource:
    url: ${DATABASE_URL:jdbc:postgresql://localhost:5432/ticketero}
    username: ${DATABASE_USERNAME:dev}
    password: ${DATABASE_PASSWORD:dev123}
    driver-class-name: org.postgresql.Driver

  jpa:
    hibernate:
      ddl-auto: validate  # Flyway maneja el schema
    show-sql: false
    properties:
      hibernate:
        format_sql: true
        dialect: org.hibernate.dialect.PostgreSQLDialect

  flyway:
    enabled: true
    baseline-on-migrate: true
    locations: classpath:db/migration

# Telegram Configuration
telegram:
  bot-token: ${TELEGRAM_BOT_TOKEN}
  api-url: https://api.telegram.org/bot

# Actuator Endpoints
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: when-authorized

# Logging
logging:
  level:
    com.example.ticketero: INFO
    org.springframework: WARN
    org.hibernate.SQL: DEBUG
    org.hibernate.type.descriptor.sql.BasicBinder: TRACE
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
```

### 3.3 .env (Template)

```bash
# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here

# Database Configuration
DATABASE_URL=jdbc:postgresql://localhost:5432/ticketero
DATABASE_USERNAME=dev
DATABASE_PASSWORD=dev123

# Spring Profile
SPRING_PROFILES_ACTIVE=dev
```

### 3.4 docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: ticketero-db
    ports:
      - "5432:5432"
    environment:
      POSTGRES_DB: ticketero
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev123
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dev -d ticketero"]
      interval: 10s
      timeout: 5s
      retries: 5

  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ticketero-api
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: jdbc:postgresql://postgres:5432/ticketero
      DATABASE_USERNAME: dev
      DATABASE_PASSWORD: dev123
      TELEGRAM_BOT_TOKEN: ${TELEGRAM_BOT_TOKEN}
      SPRING_PROFILES_ACTIVE: dev
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

volumes:
  postgres_data:
    driver: local
```

### 3.5 Dockerfile (Multi-stage)

```dockerfile
# Stage 1: Build
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom.xml and download dependencies (for caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code and build
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy jar from build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Run application
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 4. Migraciones de Base de Datos (Flyway)

### 4.1 V1__create_ticket_table.sql

```sql
-- V1__create_ticket_table.sql
-- Tabla principal de tickets

CREATE TABLE ticket (
    id BIGSERIAL PRIMARY KEY,
    codigo_referencia UUID NOT NULL UNIQUE,
    numero VARCHAR(10) NOT NULL UNIQUE,
    national_id VARCHAR(20) NOT NULL,
    telefono VARCHAR(20),
    branch_office VARCHAR(100) NOT NULL,
    queue_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    position_in_queue INTEGER NOT NULL,
    estimated_wait_minutes INTEGER NOT NULL,
    assigned_advisor_id BIGINT,
    assigned_module_number INTEGER,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_ticket_status ON ticket(status);
CREATE INDEX idx_ticket_national_id ON ticket(national_id);
CREATE INDEX idx_ticket_queue_type ON ticket(queue_type);
CREATE INDEX idx_ticket_created_at ON ticket(created_at DESC);

-- Comentarios para documentación
COMMENT ON TABLE ticket IS 'Tickets de atención en sucursales';
COMMENT ON COLUMN ticket.codigo_referencia IS 'UUID único para referencias externas';
COMMENT ON COLUMN ticket.numero IS 'Número visible del ticket (C01, P15, etc.)';
COMMENT ON COLUMN ticket.position_in_queue IS 'Posición actual en cola (calculada en tiempo real)';
COMMENT ON COLUMN ticket.estimated_wait_minutes IS 'Tiempo estimado de espera en minutos';
```

### 4.2 V2__create_mensaje_table.sql

```sql
-- V2__create_mensaje_table.sql
-- Tabla de mensajes programados para Telegram

CREATE TABLE mensaje (
    id BIGSERIAL PRIMARY KEY,
    ticket_id BIGINT NOT NULL,
    plantilla VARCHAR(50) NOT NULL,
    estado_envio VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    fecha_programada TIMESTAMP NOT NULL,
    fecha_envio TIMESTAMP,
    telegram_message_id VARCHAR(50),
    intentos INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_mensaje_ticket 
        FOREIGN KEY (ticket_id) 
        REFERENCES ticket(id) 
        ON DELETE CASCADE
);

-- Índices para performance del scheduler
CREATE INDEX idx_mensaje_estado_fecha ON mensaje(estado_envio, fecha_programada);
CREATE INDEX idx_mensaje_ticket_id ON mensaje(ticket_id);

-- Comentarios
COMMENT ON TABLE mensaje IS 'Mensajes programados para envío vía Telegram';
COMMENT ON COLUMN mensaje.plantilla IS 'Tipo de mensaje: totem_ticket_creado, totem_proximo_turno, totem_es_tu_turno';
COMMENT ON COLUMN mensaje.estado_envio IS 'Estado: PENDIENTE, ENVIADO, FALLIDO';
COMMENT ON COLUMN mensaje.intentos IS 'Cantidad de reintentos de envío';
```

### 4.3 V3__create_advisor_table.sql

```sql
-- V3__create_advisor_table.sql
-- Tabla de asesores/ejecutivos

CREATE TABLE advisor (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    module_number INTEGER NOT NULL,
    assigned_tickets_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT chk_module_number CHECK (module_number BETWEEN 1 AND 5),
    CONSTRAINT chk_assigned_count CHECK (assigned_tickets_count >= 0)
);

-- Índice para búsqueda de asesores disponibles
CREATE INDEX idx_advisor_status ON advisor(status);
CREATE INDEX idx_advisor_module ON advisor(module_number);

-- Foreign key de ticket a advisor (se agrega ahora que advisor existe)
ALTER TABLE ticket
    ADD CONSTRAINT fk_ticket_advisor 
    FOREIGN KEY (assigned_advisor_id) 
    REFERENCES advisor(id) 
    ON DELETE SET NULL;

-- Datos iniciales: 5 asesores
INSERT INTO advisor (name, email, status, module_number) VALUES
    ('María González', 'maria.gonzalez@institucion.cl', 'AVAILABLE', 1),
    ('Juan Pérez', 'juan.perez@institucion.cl', 'AVAILABLE', 2),
    ('Ana Silva', 'ana.silva@institucion.cl', 'AVAILABLE', 3),
    ('Carlos Rojas', 'carlos.rojas@institucion.cl', 'AVAILABLE', 4),
    ('Patricia Díaz', 'patricia.diaz@institucion.cl', 'AVAILABLE', 5);

-- Comentarios
COMMENT ON TABLE advisor IS 'Asesores/ejecutivos que atienden clientes';
COMMENT ON COLUMN advisor.status IS 'Estado: AVAILABLE, BUSY, OFFLINE';
COMMENT ON COLUMN advisor.module_number IS 'Número de módulo de atención (1-5)';
COMMENT ON COLUMN advisor.assigned_tickets_count IS 'Cantidad de tickets actualmente asignados';
```

---

## 5. Implementación por Fases

### FASE 0: Setup del Proyecto (30 minutos)

**Objetivo:** Configurar el proyecto base y verificar que compila

**Tareas:**

- [ ] Crear proyecto Maven con estructura de carpetas
- [ ] Configurar `pom.xml` con todas las dependencias
- [ ] Crear `application.yml` con configuración base
- [ ] Crear `.env` con variables de entorno
- [ ] Crear `docker-compose.yml` para PostgreSQL
- [ ] Levantar base de datos: `docker-compose up -d postgres`
- [ ] Crear clase principal `TicketeroApplication.java` con `@SpringBootApplication` y `@EnableScheduling`
- [ ] Verificar compilación: `mvn clean compile`
- [ ] Verificar que conecta a BD: `mvn spring-boot:run`

**Criterios de Aceptación:**

- ✅ Proyecto compila sin errores
- ✅ Aplicación inicia y conecta a PostgreSQL
- ✅ Logs muestran: "Started TicketeroApplication"
- ✅ Actuator health endpoint responde: `curl http://localhost:8080/actuator/health`

**Implementación de TicketeroApplication.java:**

```java
package com.example.ticketero;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class TicketeroApplication {

    public static void main(String[] args) {
        SpringApplication.run(TicketeroApplication.class, args);
    }
}
```

---

### FASE 1: Migraciones y Enumeraciones (45 minutos)

**Objetivo:** Crear esquema de base de datos y enumeraciones Java

**Tareas:**

- [ ] Crear `V1__create_ticket_table.sql`
- [ ] Crear `V2__create_mensaje_table.sql`
- [ ] Crear `V3__create_advisor_table.sql`
- [ ] Crear enum `QueueType.java`
- [ ] Crear enum `TicketStatus.java`
- [ ] Crear enum `AdvisorStatus.java`
- [ ] Crear enum `MessageTemplate.java`
- [ ] Reiniciar aplicación y verificar migraciones
- [ ] Verificar tablas creadas: `\dt` en psql
- [ ] Verificar datos iniciales: `SELECT * FROM advisor;`

**Criterios de Aceptación:**

- ✅ Flyway ejecuta las 3 migraciones exitosamente
- ✅ Tabla `flyway_schema_history` muestra 3 versiones
- ✅ Tablas `ticket`, `mensaje`, `advisor` existen
- ✅ 5 asesores iniciales insertados en `advisor`
- ✅ 4 enums creadas con valores correctos

**Ejemplo de Enum QueueType.java:**

```java
package com.example.ticketero.model.enums;

public enum QueueType {
    CAJA("Caja", 5, 1, "C"),
    PERSONAL_BANKER("Personal Banker", 15, 2, "P"),
    EMPRESAS("Empresas", 20, 3, "E"),
    GERENCIA("Gerencia", 30, 4, "G");

    private final String displayName;
    private final int avgTimeMinutes;
    private final int priority;
    private final String prefix;

    QueueType(String displayName, int avgTimeMinutes, int priority, String prefix) {
        this.displayName = displayName;
        this.avgTimeMinutes = avgTimeMinutes;
        this.priority = priority;
        this.prefix = prefix;
    }

    public String getDisplayName() { return displayName; }
    public int getAvgTimeMinutes() { return avgTimeMinutes; }
    public int getPriority() { return priority; }
    public String getPrefix() { return prefix; }
}
```

**Ejemplo de Enum TicketStatus.java:**

```java
package com.example.ticketero.model.enums;

public enum TicketStatus {
    EN_ESPERA("Esperando asignación", true),
    PROXIMO("Próximo a ser atendido", true),
    ATENDIENDO("Siendo atendido", true),
    COMPLETADO("Atención finalizada", false),
    CANCELADO("Cancelado", false),
    NO_ATENDIDO("Cliente no se presentó", false);

    private final String descripcion;
    private final boolean esActivo;

    TicketStatus(String descripcion, boolean esActivo) {
        this.descripcion = descripcion;
        this.esActivo = esActivo;
    }

    public String getDescripcion() { return descripcion; }
    public boolean isEsActivo() { return esActivo; }
}
```

---

### FASE 2: Entities (1 hora)

**Objetivo:** Crear las 3 entidades JPA mapeadas a las tablas

**Tareas:**

- [ ] Crear `Ticket.java` con todas las anotaciones JPA
- [ ] Crear `Mensaje.java` con relación a Ticket
- [ ] Crear `Advisor.java` con relación a Ticket
- [ ] Usar Lombok: `@Data`, `@NoArgsConstructor`, `@AllArgsConstructor`, `@Builder`
- [ ] Mapear enums con `@Enumerated(EnumType.STRING)`
- [ ] Configurar relaciones: `@OneToMany`, `@ManyToOne`
- [ ] Agregar `@PrePersist` para `codigo_referencia` UUID
- [ ] Compilar y verificar sin errores

**Criterios de Aceptación:**

- ✅ 3 entities creadas con anotaciones JPA correctas
- ✅ Relaciones bidireccionales configuradas
- ✅ Proyecto compila sin errores
- ✅ Hibernate valida el schema al iniciar (no crea tablas por `ddl-auto=validate`)

**Ejemplo de Entity Ticket.java:**

```java
package com.example.ticketero.model.entity;

import com.example.ticketero.model.enums.QueueType;
import com.example.ticketero.model.enums.TicketStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "ticket")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Ticket {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "codigo_referencia", nullable = false, unique = true)
    private UUID codigoReferencia;

    @Column(name = "numero", nullable = false, unique = true, length = 10)
    private String numero;

    @Column(name = "national_id", nullable = false, length = 20)
    private String nationalId;

    @Column(name = "telefono", length = 20)
    private String telefono;

    @Column(name = "branch_office", nullable = false, length = 100)
    private String branchOffice;

    @Enumerated(EnumType.STRING)
    @Column(name = "queue_type", nullable = false, length = 20)
    private QueueType queueType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private TicketStatus status;

    @Column(name = "position_in_queue", nullable = false)
    private Integer positionInQueue;

    @Column(name = "estimated_wait_minutes", nullable = false)
    private Integer estimatedWaitMinutes;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_advisor_id")
    @ToString.Exclude
    private Advisor assignedAdvisor;

    @Column(name = "assigned_module_number")
    private Integer assignedModuleNumber;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "ticket", cascade = CascadeType.ALL, orphanRemoval = true)
    @ToString.Exclude
    @Builder.Default
    private List<Mensaje> mensajes = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        codigoReferencia = UUID.randomUUID();
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
```

---

### FASE 3: DTOs (45 minutos)

**Objetivo:** Crear DTOs para request/response

**Tareas:**

- [ ] Crear `TicketCreateRequest.java` con Bean Validation
- [ ] Crear `TicketResponse.java` como record
- [ ] Crear `QueuePositionResponse.java`
- [ ] Crear `DashboardResponse.java`
- [ ] Crear `QueueStatusResponse.java`
- [ ] Agregar validaciones: `@NotBlank`, `@NotNull`, `@Pattern`
- [ ] Compilar y verificar

**Criterios de Aceptación:**

- ✅ 5 DTOs creados
- ✅ Validaciones Bean Validation configuradas
- ✅ Records usados donde sea apropiado (inmutabilidad)

**Ejemplo de DTO TicketCreateRequest.java:**

```java
package com.example.ticketero.model.dto;

import com.example.ticketero.model.enums.QueueType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record TicketCreateRequest(
    
    @NotBlank(message = "El RUT/ID es obligatorio")
    String nationalId,
    
    @Pattern(regexp = "^\\+56[0-9]{9}$", message = "Teléfono debe tener formato +56XXXXXXXXX")
    String telefono,
    
    @NotBlank(message = "La sucursal es obligatoria")
    String branchOffice,
    
    @NotNull(message = "El tipo de cola es obligatorio")
    QueueType queueType
) {}
```

**Ejemplo de DTO TicketResponse.java:**

```java
package com.example.ticketero.model.dto;

import com.example.ticketero.model.enums.QueueType;
import com.example.ticketero.model.enums.TicketStatus;

import java.time.LocalDateTime;
import java.util.UUID;

public record TicketResponse(
    UUID codigoReferencia,
    String numero,
    TicketStatus status,
    Integer positionInQueue,
    Integer estimatedWaitMinutes,
    QueueType queueType,
    String branchOffice,
    LocalDateTime createdAt,
    String assignedAdvisorName,
    Integer assignedModuleNumber
) {}
```

---

### FASE 4: Repositories (30 minutos)

**Objetivo:** Crear interfaces de acceso a datos

**Tareas:**

- [ ] Crear `TicketRepository.java` extends JpaRepository
- [ ] Crear `MensajeRepository.java`
- [ ] Crear `AdvisorRepository.java`
- [ ] Agregar queries custom con `@Query`
- [ ] Métodos: findByCodigoReferencia, findByNationalIdAndStatusIn, etc.

**Criterios de Aceptación:**

- ✅ 3 repositories creados
- ✅ Queries custom documentadas
- ✅ Proyecto compila

**Ejemplo TicketRepository.java:**

```java
package com.example.ticketero.repository;

import com.example.ticketero.model.entity.Ticket;
import com.example.ticketero.model.enums.QueueType;
import com.example.ticketero.model.enums.TicketStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, Long> {

    Optional<Ticket> findByCodigoReferencia(UUID codigoReferencia);

    Optional<Ticket> findByNumero(String numero);

    @Query("SELECT t FROM Ticket t WHERE t.nationalId = :nationalId AND t.status IN :statuses")
    Optional<Ticket> findByNationalIdAndStatusIn(
        @Param("nationalId") String nationalId, 
        @Param("statuses") List<TicketStatus> statuses
    );

    @Query("SELECT t FROM Ticket t WHERE t.status = :status ORDER BY t.createdAt ASC")
    List<Ticket> findByStatusOrderByCreatedAtAsc(@Param("status") TicketStatus status);

    @Query("""
        SELECT t FROM Ticket t 
        WHERE t.queueType = :queueType 
        AND t.status IN :statuses 
        ORDER BY t.createdAt ASC
        """)
    List<Ticket> findByQueueTypeAndStatusInOrderByCreatedAtAsc(
        @Param("queueType") QueueType queueType,
        @Param("statuses") List<TicketStatus> statuses
    );

    @Query("""
        SELECT COUNT(t) FROM Ticket t 
        WHERE t.queueType = :queueType 
        AND t.status = :status 
        AND t.createdAt < :createdAt
        """)
    Long countTicketsAheadInQueue(
        @Param("queueType") QueueType queueType,
        @Param("status") TicketStatus status,
        @Param("createdAt") java.time.LocalDateTime createdAt
    );
}
```

---
