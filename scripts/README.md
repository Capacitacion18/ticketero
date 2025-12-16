# TICKETERO - Pruebas No Funcionales (NFR)

## 🎯 Objetivo

Suite completa de pruebas no funcionales para validar **performance**, **concurrencia** y **resiliencia** del sistema Ticketero.

## 📋 Requisitos Validados

| ID | Requisito | Métrica | Umbral |
|----|-----------|---------|---------|
| RNF-01 | Throughput | Tickets procesados/minuto | ≥ 50 |
| RNF-02 | Latencia API | p95 response time | < 2 segundos |
| RNF-03 | Concurrencia | Race conditions | 0 detectadas |
| RNF-04 | Consistencia | Tickets inconsistentes | 0 |
| RNF-05 | Recovery Time | Detección worker muerto | < 90 segundos |
| RNF-06 | Disponibilidad | Uptime durante carga | 99.9% |
| RNF-07 | Recursos | Memory leak | 0 (estable 30 min) |

## 🚀 Inicio Rápido

### 1. Setup Inicial
```bash
# Configurar entorno
./scripts/setup-nfr-tests.sh

# Verificar que todo está listo
./scripts/utils/validate-consistency.sh
```

### 2. Ejecutar Pruebas
```bash
# Suite completa (recomendado)
./scripts/run-all-tests.sh

# Suite completa con soak test (30 min)
./scripts/run-all-tests.sh --full

# Pruebas individuales
./scripts/performance/load-test.sh
./scripts/concurrency/race-condition-test.sh
```

## 📁 Estructura de Archivos

```
scripts/
├── setup-nfr-tests.sh          # Setup inicial
├── run-all-tests.sh             # Ejecutor principal
├── README.md                    # Esta documentación
├── performance/                 # Pruebas de performance
│   ├── load-test.sh            # Load test sostenido
│   ├── spike-test.sh           # Spike test
│   └── soak-test.sh            # Soak test (memory leaks)
├── concurrency/                 # Pruebas de concurrencia
│   ├── race-condition-test.sh  # Race conditions
│   └── idempotency-test.sh     # Idempotencia
├── resilience/                  # Pruebas de resiliencia
│   ├── worker-crash-test.sh    # Recovery de workers
│   ├── rabbitmq-failure-test.sh # Fallas de RabbitMQ
│   └── graceful-shutdown-test.sh # Graceful shutdown
├── chaos/                       # Chaos engineering
│   ├── kill-worker.sh          # Matar workers
│   └── network-delay.sh        # Latencia de red
└── utils/                       # Utilidades
    ├── metrics-collector.sh    # Recolector de métricas
    └── validate-consistency.sh # Validador de consistencia
```

## 🧪 Escenarios de Prueba

### 📊 Performance (PERF)

#### PERF-01: Load Test Sostenido
- **Objetivo**: Validar throughput sostenido
- **Carga**: 100 tickets en 2 minutos (10 VUs)
- **Métricas**: Throughput ≥50/min, Latencia p95 <2s

#### PERF-02: Spike Test  
- **Objetivo**: Comportamiento bajo carga súbita
- **Carga**: 50 tickets simultáneos en 10s
- **Métricas**: Procesamiento completo <180s

#### PERF-03: Soak Test
- **Objetivo**: Detectar memory leaks
- **Carga**: 30 tickets/min durante 30 min
- **Métricas**: Incremento memoria <20%

### 🔄 Concurrencia (CONC)

#### CONC-01: Race Condition Test
- **Objetivo**: Validar SELECT FOR UPDATE
- **Escenario**: 1 asesor, 5 tickets simultáneos
- **Métricas**: 0 asignaciones dobles, 0 deadlocks

#### CONC-02: Idempotency Test
- **Objetivo**: Prevenir reprocesamiento
- **Escenario**: Simular redelivery de mensajes
- **Métricas**: No duplicación de procesamiento

### 🛡️ Resiliencia (RES)

#### RES-01: Worker Crash Test
- **Objetivo**: Auto-recovery de workers
- **Escenario**: Simular crash durante procesamiento
- **Métricas**: Detección <90s, recovery automático

#### RES-02: RabbitMQ Failure Test
- **Objetivo**: Outbox pattern bajo fallas
- **Escenario**: Detener RabbitMQ durante operación
- **Métricas**: 0 mensajes perdidos

## 📈 Métricas Capturadas

### Sistema
- CPU y memoria de contenedores
- Conexiones DB activas
- Mensajes en colas RabbitMQ

### Performance
- Throughput (tickets/minuto)
- Latencia (p50, p95, p99, max)
- Error rate
- Tiempo de procesamiento

### Consistencia
- Tickets en estado inconsistente
- Asesores BUSY sin ticket activo
- Tickets duplicados
- Deadlocks PostgreSQL

## 🔧 Configuración

### Variables de Entorno
```bash
# URL base de la API (default: http://localhost:8080)
export BASE_URL=http://localhost:8080

# Duración del soak test en minutos (default: 30)
export SOAK_DURATION=30

# Nivel de logging (default: INFO)
export LOG_LEVEL=INFO
```

### Dependencias
- Docker & Docker Compose
- curl
- bc (calculadora)
- K6 (opcional, para load testing avanzado)

## 📊 Interpretación de Resultados

### ✅ PASS - Criterios de Éxito
- **Throughput**: ≥50 tickets/minuto
- **Latencia p95**: <2000ms
- **Error rate**: <1%
- **Race conditions**: 0 detectadas
- **Memory leak**: Incremento <20%
- **Recovery time**: <90 segundos

### ❌ FAIL - Criterios de Falla
- Throughput insuficiente
- Latencia alta
- Errores frecuentes
- Race conditions detectadas
- Memory leaks
- Recovery lento

### ⚠️ WARN - Advertencias
- Performance degradada pero aceptable
- Recursos altos pero estables
- Recovery events frecuentes

## 🐛 Troubleshooting

### Problema: "Docker no disponible"
```bash
# Verificar Docker
docker --version
docker ps

# Iniciar Docker si está detenido
sudo systemctl start docker  # Linux
# o usar Docker Desktop en Windows/Mac
```

### Problema: "API no responde"
```bash
# Verificar contenedores
docker-compose ps

# Ver logs de la aplicación
docker-compose logs api

# Reiniciar si es necesario
docker-compose restart api
```

### Problema: "Tablas no existen"
```bash
# Ejecutar migraciones
docker-compose exec api ./mvnw flyway:migrate

# O recrear base de datos
docker-compose down -v
docker-compose up -d
```

### Problema: "Scripts no ejecutables"
```bash
# Dar permisos
chmod +x scripts/**/*.sh

# O usar el setup
./scripts/setup-nfr-tests.sh
```

## 📝 Logs y Resultados

### Ubicación de Archivos
```
results/
├── nfr-YYYYMMDD-HHMMSS/        # Resultados por ejecución
│   ├── test-summary.txt        # Resumen de resultados
│   ├── load-test-output.log    # Log detallado
│   └── metrics-*.csv           # Métricas del sistema
└── metrics/                    # Métricas históricas
```

### Formato de Métricas CSV
```csv
timestamp,cpu_app,mem_app_mb,cpu_postgres,mem_postgres_mb,db_connections,tickets_waiting,tickets_completed
2024-01-15 10:30:00,25.5,512,15.2,256,8,5,45
```

## 🚀 Extensiones Futuras

### Chaos Engineering
- Latencia de red variable
- Particiones de red
- Fallas de disco
- CPU throttling

### Monitoring Avanzado
- Integración con Prometheus
- Dashboards Grafana
- Alertas automáticas
- Métricas de negocio

### CI/CD Integration
- Ejecución automática en pipeline
- Thresholds configurables
- Reportes automáticos
- Regression testing

## 📞 Soporte

Para problemas o mejoras:
1. Revisar logs en `results/`
2. Verificar configuración con `setup-nfr-tests.sh`
3. Ejecutar validación: `validate-consistency.sh`
4. Consultar documentación en `docs/NFR-TEST-RESULTS.md`

---

**Versión**: 1.0  
**Última actualización**: Enero 2024  
**Mantenedor**: Performance Engineering Team