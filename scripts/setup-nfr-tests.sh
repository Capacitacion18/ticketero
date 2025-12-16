#!/bin/bash
# =============================================================================
# TICKETERO - Setup de Pruebas No Funcionales
# =============================================================================
# Configura el entorno para ejecutar pruebas NFR
# Usage: ./scripts/setup-nfr-tests.sh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║           TICKETERO - SETUP PRUEBAS NFR                     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# =============================================================================
# 1. VERIFICAR DEPENDENCIAS
# =============================================================================
echo -e "${YELLOW}1. Verificando dependencias...${NC}"

# Docker
if command -v docker &> /dev/null; then
    echo "   ✅ Docker: $(docker --version | cut -d' ' -f3)"
else
    echo -e "   ${RED}❌ Docker no encontrado${NC}"
    exit 1
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "   ✅ Docker Compose: $(docker-compose --version | cut -d' ' -f3)"
else
    echo -e "   ${RED}❌ Docker Compose no encontrado${NC}"
    exit 1
fi

# curl
if command -v curl &> /dev/null; then
    echo "   ✅ curl: $(curl --version | head -1 | cut -d' ' -f2)"
else
    echo -e "   ${RED}❌ curl no encontrado${NC}"
    exit 1
fi

# bc (para cálculos)
if command -v bc &> /dev/null; then
    echo "   ✅ bc: disponible"
else
    echo -e "   ${YELLOW}⚠ bc no encontrado (instalando...)${NC}"
    # En sistemas diferentes, usar el gestor de paquetes apropiado
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y bc
    elif command -v yum &> /dev/null; then
        sudo yum install -y bc
    elif command -v brew &> /dev/null; then
        brew install bc
    else
        echo -e "   ${RED}❌ No se pudo instalar bc automáticamente${NC}"
        echo "   Instala bc manualmente: apt-get install bc / yum install bc / brew install bc"
        exit 1
    fi
fi

# K6 (opcional)
if command -v k6 &> /dev/null; then
    echo "   ✅ K6: $(k6 version | head -1)"
else
    echo -e "   ${YELLOW}⚠ K6 no encontrado (opcional)${NC}"
    echo "   Para instalar K6: https://k6.io/docs/getting-started/installation/"
fi

# =============================================================================
# 2. HACER SCRIPTS EJECUTABLES
# =============================================================================
echo -e "${YELLOW}2. Configurando permisos de scripts...${NC}"

find "$SCRIPT_DIR" -name "*.sh" -exec chmod +x {} \;
echo "   ✅ Permisos configurados"

# =============================================================================
# 3. CREAR DIRECTORIOS
# =============================================================================
echo -e "${YELLOW}3. Creando directorios de trabajo...${NC}"

mkdir -p "$PROJECT_ROOT/results"
mkdir -p "$PROJECT_ROOT/results/metrics"
mkdir -p "$PROJECT_ROOT/results/logs"

echo "   ✅ Directorios creados:"
echo "      - $PROJECT_ROOT/results"
echo "      - $PROJECT_ROOT/results/metrics"
echo "      - $PROJECT_ROOT/results/logs"

# =============================================================================
# 4. VERIFICAR DOCKER COMPOSE
# =============================================================================
echo -e "${YELLOW}4. Verificando configuración Docker...${NC}"

cd "$PROJECT_ROOT"

if [ ! -f "docker-compose.yml" ]; then
    echo -e "   ${RED}❌ docker-compose.yml no encontrado${NC}"
    exit 1
fi

# Verificar si los contenedores están corriendo
if docker-compose ps | grep -q "Up"; then
    echo "   ✅ Contenedores ya están corriendo"
else
    echo "   🚀 Iniciando contenedores..."
    docker-compose up -d
    
    # Esperar a que PostgreSQL esté listo
    echo "   ⏳ Esperando PostgreSQL..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker exec ticketero-db pg_isready -U dev -d ticketero &> /dev/null; then
            echo "   ✅ PostgreSQL listo"
            break
        fi
        sleep 2
        timeout=$((timeout - 2))
    done
    
    if [ $timeout -le 0 ]; then
        echo -e "   ${RED}❌ Timeout esperando PostgreSQL${NC}"
        exit 1
    fi
fi

# =============================================================================
# 5. VERIFICAR API
# =============================================================================
echo -e "${YELLOW}5. Verificando API...${NC}"

# Esperar a que la API esté disponible
timeout=60
while [ $timeout -gt 0 ]; do
    if curl -s http://localhost:8080/actuator/health &> /dev/null; then
        echo "   ✅ API disponible en http://localhost:8080"
        break
    fi
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo -e "   ${YELLOW}⚠ API no disponible (puede estar iniciando)${NC}"
    echo "   Verifica manualmente: curl http://localhost:8080/actuator/health"
fi

# =============================================================================
# 6. CREAR DATOS DE PRUEBA (si es necesario)
# =============================================================================
echo -e "${YELLOW}6. Configurando datos de prueba...${NC}"

# Verificar si existen tablas básicas
if docker exec ticketero-db psql -U dev -d ticketero -c "\dt" &> /dev/null; then
    echo "   ✅ Base de datos configurada"
    
    # Crear algunos asesores de prueba si no existen
    ADVISOR_COUNT=$(docker exec ticketero-db psql -U dev -d ticketero -t -c \
        "SELECT COUNT(*) FROM advisor;" 2>/dev/null | xargs || echo "0")
    
    if [ "$ADVISOR_COUNT" -eq 0 ]; then
        echo "   🔧 Creando asesores de prueba..."
        docker exec ticketero-db psql -U dev -d ticketero -c "
            INSERT INTO advisor (name, status, queue_type, total_tickets_served, recovery_count, last_heartbeat) VALUES
            ('Asesor Test 1', 'AVAILABLE', 'CAJA', 0, 0, NOW()),
            ('Asesor Test 2', 'AVAILABLE', 'PERSONAL', 0, 0, NOW()),
            ('Asesor Test 3', 'AVAILABLE', 'EMPRESAS', 0, 0, NOW()),
            ('Asesor Test 4', 'AVAILABLE', 'GERENCIA', 0, 0, NOW()),
            ('Asesor Test 5', 'AVAILABLE', 'CAJA', 0, 0, NOW());
        " &> /dev/null || echo "   ⚠ No se pudieron crear asesores (tabla no existe)"
    else
        echo "   ✅ Asesores existentes: $ADVISOR_COUNT"
    fi
else
    echo -e "   ${YELLOW}⚠ Tablas no existen aún (ejecutar migraciones primero)${NC}"
fi

# =============================================================================
# 7. RESUMEN
# =============================================================================
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    SETUP COMPLETADO                         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Entorno configurado para pruebas NFR${NC}"
echo ""
echo "📋 Comandos disponibles:"
echo "   ./scripts/run-all-tests.sh              # Ejecutar todas las pruebas"
echo "   ./scripts/performance/load-test.sh      # Solo load test"
echo "   ./scripts/utils/validate-consistency.sh # Validar consistencia"
echo ""
echo "📁 Resultados se guardarán en: $PROJECT_ROOT/results/"
echo ""
echo -e "${YELLOW}💡 Tip: Ejecuta primero un test individual para verificar que todo funciona${NC}"
echo "   Ejemplo: ./scripts/performance/load-test.sh"
echo ""