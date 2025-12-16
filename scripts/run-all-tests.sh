#!/bin/bash
# =============================================================================
# TICKETERO - Ejecutor de Todas las Pruebas No Funcionales
# =============================================================================
# Ejecuta todos los tests de performance, concurrencia y resiliencia
# Usage: ./scripts/run-all-tests.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              TICKETERO - SUITE DE PRUEBAS NFR                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Crear directorio de resultados con timestamp
RESULTS_DIR="$PROJECT_ROOT/results/nfr-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Archivo de resumen
SUMMARY_FILE="$RESULTS_DIR/test-summary.txt"
echo "TICKETERO - RESUMEN DE PRUEBAS NO FUNCIONALES" > "$SUMMARY_FILE"
echo "Ejecutado: $(date)" >> "$SUMMARY_FILE"
echo "=========================================" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Función para ejecutar test
run_test() {
    local test_name="$1"
    local test_script="$2"
    local category="$3"
    
    echo -e "${CYAN}[$category] Ejecutando: $test_name${NC}"
    echo "----------------------------------------"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if bash "$test_script" 2>&1 | tee "$RESULTS_DIR/${test_name,,}-output.log"; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        echo "✅ $test_name: PASSED" >> "$SUMMARY_FILE"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        echo "❌ $test_name: FAILED" >> "$SUMMARY_FILE"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo ""
    sleep 2
}

# =============================================================================
# PASO 1: VALIDACIÓN INICIAL
# =============================================================================
echo -e "${YELLOW}PASO 1: Validación inicial del sistema${NC}"
echo ""

# Verificar que Docker está corriendo
if ! docker ps > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker no está disponible${NC}"
    exit 1
fi

# Verificar contenedores
if ! docker ps | grep -q "ticketero"; then
    echo -e "${YELLOW}⚠ Contenedores no están corriendo. Iniciando...${NC}"
    cd "$PROJECT_ROOT"
    docker-compose up -d
    sleep 30
fi

echo -e "${GREEN}✅ Sistema listo para pruebas${NC}"
echo ""

# =============================================================================
# PASO 2: PRUEBAS DE PERFORMANCE
# =============================================================================
echo -e "${YELLOW}PASO 2: Pruebas de Performance${NC}"
echo ""

run_test "Load Test Sostenido" "$SCRIPT_DIR/performance/load-test.sh" "PERFORMANCE"
run_test "Spike Test" "$SCRIPT_DIR/performance/spike-test.sh" "PERFORMANCE"

# Soak test solo si se especifica (toma mucho tiempo)
if [ "$1" = "--full" ]; then
    run_test "Soak Test" "$SCRIPT_DIR/performance/soak-test.sh 5" "PERFORMANCE"
fi

# =============================================================================
# PASO 3: PRUEBAS DE CONCURRENCIA
# =============================================================================
echo -e "${YELLOW}PASO 3: Pruebas de Concurrencia${NC}"
echo ""

run_test "Race Condition Test" "$SCRIPT_DIR/concurrency/race-condition-test.sh" "CONCURRENCY"
run_test "Idempotency Test" "$SCRIPT_DIR/concurrency/idempotency-test.sh" "CONCURRENCY"

# =============================================================================
# PASO 4: VALIDACIÓN FINAL
# =============================================================================
echo -e "${YELLOW}PASO 4: Validación Final de Consistencia${NC}"
echo ""

if bash "$SCRIPT_DIR/utils/validate-consistency.sh"; then
    echo -e "${GREEN}✅ Consistencia Final: PASSED${NC}"
    echo "✅ Consistencia Final: PASSED" >> "$SUMMARY_FILE"
else
    echo -e "${RED}❌ Consistencia Final: FAILED${NC}"
    echo "❌ Consistencia Final: FAILED" >> "$SUMMARY_FILE"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# =============================================================================
# RESUMEN FINAL
# =============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    RESUMEN FINAL                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Total de pruebas: $TOTAL_TESTS"
echo "Exitosas: $PASSED_TESTS"
echo "Fallidas: $FAILED_TESTS"
echo ""

# Escribir resumen al archivo
echo "" >> "$SUMMARY_FILE"
echo "=========================================" >> "$SUMMARY_FILE"
echo "RESUMEN:" >> "$SUMMARY_FILE"
echo "Total: $TOTAL_TESTS | Exitosas: $PASSED_TESTS | Fallidas: $FAILED_TESTS" >> "$SUMMARY_FILE"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 TODAS LAS PRUEBAS PASARON${NC}"
    echo "🎉 TODAS LAS PRUEBAS PASARON" >> "$SUMMARY_FILE"
    SUCCESS_RATE=100
else
    echo -e "${RED}⚠ $FAILED_TESTS PRUEBAS FALLARON${NC}"
    echo "⚠ $FAILED_TESTS PRUEBAS FALLARON" >> "$SUMMARY_FILE"
    SUCCESS_RATE=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc -l)
fi

echo ""
echo "Tasa de éxito: ${SUCCESS_RATE}%"
echo "Resultados en: $RESULTS_DIR"
echo ""

# Exit code basado en resultados
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi