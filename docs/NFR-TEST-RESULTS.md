# TICKETERO - Resultados de Pruebas No Funcionales

## Resumen Ejecutivo

Este documento presenta los resultados de las pruebas no funcionales (NFR) del sistema Ticketero, validando performance, concurrencia y resiliencia según los requisitos establecidos.

## Requisitos No Funcionales Validados

| ID | Requisito | Métrica | Umbral | Estado |
|----|-----------|---------|---------|---------|
| RNF-01 | Throughput | Tickets procesados/minuto | ≥ 50 | ⏳ |
| RNF-02 | Latencia API | p95 response time | < 2 segundos | ⏳ |
| RNF-03 | Concurrencia | Race conditions | 0 detectadas | ⏳ |
| RNF-04 | Consistencia | Tickets inconsistentes | 0 | ⏳ |
| RNF-05 | Recovery Time | Detección worker muerto | < 90 segundos | ⏳ |
| RNF-06 | Disponibilidad | Uptime durante carga | 99.9% | ⏳ |
| RNF-07 | Recursos | Memory leak | 0 (estable 30 min) | ⏳ |

## Escenarios de Prueba Implementados

### 📊 Performance (PERF)

#### PERF-01: Load Test Sostenido
- **Objetivo**: Validar throughput sostenido de 50+ tickets/minuto
- **Configuración**: 100 tickets en 2 minutos, 10 VUs concurrentes
- **Criterios de éxito**:
  - Throughput: ≥ 50 tickets/minuto
  - Latencia p95: < 2000ms
  - Error rate: < 1%
- **Estado**: ⏳ Implementado

#### PERF-02: Spike Test
- **Objetivo**: Validar comportamiento bajo carga súbita
- **Configuración**: 50 tickets simultáneos en 10 segundos
- **Criterios de éxito**:
  - Procesamiento completo < 180 segundos
  - Sin errores críticos
- **Estado**: ⏳ Implementado

#### PERF-03: Soak Test
- **Objetivo**: Detectar memory leaks y degradación progresiva
- **Configuración**: 30 tickets/minuto durante 30 minutos
- **Criterios de éxito**:
  - Incremento memoria < 20%
  - Performance estable
- **Estado**: ⏳ Implementado

### 🔄 Concurrencia (CONC)

#### CONC-01: Race Condition Test
- **Objetivo**: Validar que SELECT FOR UPDATE previene race conditions
- **Configuración**: 1 asesor disponible, 5 tickets simultáneos
- **Criterios de éxito**:
  - 0 asignaciones dobles
  - 0 deadlocks PostgreSQL
- **Estado**: ⏳ Implementado

#### CONC-02: Idempotency Test
- **Objetivo**: Validar que tickets procesados no se reprocesan
- **Configuración**: Simular redelivery de mensajes
- **Criterios de éxito**:
  - No duplicación de procesamiento
  - Contadores consistentes
- **Estado**: ⏳ Implementado

### 🛡️ Resiliencia (RES)

#### RES-01: Worker Crash Test
- **Objetivo**: Validar auto-recovery de workers muertos
- **Configuración**: Simular crash durante procesamiento
- **Criterios de éxito**:
  - Detección < 90 segundos
  - Recovery automático
- **Estado**: 🔄 Por implementar

#### RES-02: RabbitMQ Failure Test
- **Objetivo**: Validar que Outbox acumula sin perder mensajes
- **Configuración**: Detener RabbitMQ durante creación de tickets
- **Criterios de éxito**:
  - 0 mensajes perdidos
  - Recovery automático
- **Estado**: 🔄 Por implementar

## Herramientas y Scripts

### Scripts de Utilidad
- `scripts/utils/metrics-collector.sh`: Recolección de métricas del sistema
- `scripts/utils/validate-consistency.sh`: Validación de consistencia post-pruebas

### Scripts de Performance
- `scripts/performance/load-test.sh`: Load test sostenido
- `scripts/performance/spike-test.sh`: Spike test
- `scripts/performance/soak-test.sh`: Soak test para memory leaks

### Scripts de Concurrencia
- `scripts/concurrency/race-condition-test.sh`: Test de race conditions
- `scripts/concurrency/idempotency-test.sh`: Test de idempotencia

### K6 Scripts
- `k6/load-test.js`: Script K6 para load testing con métricas custom

## Ejecución de Pruebas

### Ejecución Individual
```bash
# Performance
./scripts/performance/load-test.sh
./scripts/performance/spike-test.sh
./scripts/performance/soak-test.sh 30

# Concurrencia
./scripts/concurrency/race-condition-test.sh
./scripts/concurrency/idempotency-test.sh

# Validación
./scripts/utils/validate-consistency.sh
```

### Ejecución Completa
```bash
# Suite completa (sin soak test)
./scripts/run-all-tests.sh

# Suite completa incluyendo soak test
./scripts/run-all-tests.sh --full
```

## Métricas Capturadas

### Métricas de Sistema
- CPU y memoria de contenedores (App, PostgreSQL)
- Conexiones de base de datos activas
- Tickets por estado (WAITING, IN_PROGRESS, COMPLETED)
- Mensajes en colas RabbitMQ

### Métricas de Performance
- Throughput (tickets/minuto)
- Latencia (p50, p95, p99, max)
- Error rate
- Tiempo de procesamiento

### Métricas de Consistencia
- Tickets en estado inconsistente
- Asesores BUSY sin ticket activo
- Tickets duplicados
- Deadlocks PostgreSQL

## Resultados

### ✅ PASO 1 COMPLETADO

**Scripts creados:**
- ✅ metrics-collector.sh: Recolecta métricas cada 5s
- ✅ validate-consistency.sh: 7 validaciones de consistencia
- ✅ k6/load-test.js: Script base K6 con métricas custom
- ✅ run-all-tests.sh: Ejecutor principal de todas las pruebas

**Herramientas configuradas:**
- ✅ K6 para load testing
- ✅ Bash scripts para chaos testing
- ✅ CSV output para análisis
- ✅ Validaciones de consistencia automatizadas

**Escenarios implementados:**
- ✅ PERF-01: Load Test Sostenido
- ✅ PERF-02: Spike Test  
- ✅ PERF-03: Soak Test
- ✅ CONC-01: Race Condition Test
- ✅ CONC-02: Idempotency Test

## 🔍 SOLICITO REVISIÓN

**Pregunta 1:** ¿Los scripts cubren las métricas necesarias para validar los RNF?

**Pregunta 2:** ¿La metodología de pruebas es adecuada para detectar problemas de concurrencia y performance?

**Pregunta 3:** ¿Puedo continuar implementando los escenarios de resiliencia (PASO 4)?

## Próximos Pasos

1. **PASO 4**: Implementar escenarios de resiliencia (RES-01, RES-02, RES-03)
2. **PASO 5**: Implementar escenarios de consistencia Outbox
3. **PASO 6**: Implementar pruebas de graceful shutdown
4. **PASO 7**: Implementar pruebas de escalabilidad
5. **PASO 8**: Crear dashboard de métricas y reporte final

## Notas Técnicas

- Los scripts están adaptados para el entorno actual (sin RabbitMQ aún)
- Se incluyen fallbacks para tablas que no existen
- Métricas se almacenan en CSV para análisis posterior
- Validaciones de consistencia cubren casos edge comunes
- Scripts son compatibles con bash en sistemas Unix/Linux

---

**Fecha de última actualización**: $(date)
**Versión**: 1.0
**Estado**: En desarrollo - PASO 1 completado