#!/bin/bash

# Script para diagnosticar Google Sign-In en Release
# Ejecuta verificaciones automáticas y captura logs

set -e

PROJECT_DIR="/Volumes/Datos/dts-app-ecommerce/flutter-driver"
APK_PATH="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
PACKAGE_NAME="com.osedhelu.dtsdriver"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$PROJECT_DIR/debug_logs"

mkdir -p "$LOG_DIR"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============ TIMEOUT PORTÁTIL (macOS no incluye GNU timeout) ============
run_with_timeout() {
    local seconds="$1"; shift
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
    else
        # Implementación portable: corre en background y lo mata a los N segundos
        "$@" &
        local pid=$!
        (
            sleep "$seconds"
            kill "$pid" 2>/dev/null
        ) &
        local killer_pid=$!
        wait "$pid" 2>/dev/null || true
        kill "$killer_pid" 2>/dev/null || true
    fi
}


echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  DIAGNÓSTICO: Google Sign-In Release${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# ============ VERIFICACIÓN 1: APK ============
echo -e "${YELLOW}[1/6] Verificando APK...${NC}"
if [ ! -f "$APK_PATH" ]; then
    echo -e "${RED}✗ APK no encontrado${NC}"
    echo "  Ejecuta: flutter build apk --release"
    exit 1
fi
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "${GREEN}✓ APK encontrado: $APK_SIZE${NC}"
echo ""

# ============ VERIFICACIÓN 2: google-services.json ============
echo -e "${YELLOW}[2/6] Verificando google-services.json...${NC}"
GSJ_PATH="$PROJECT_DIR/android/app/google-services.json"
if [ ! -f "$GSJ_PATH" ]; then
    echo -e "${RED}✗ google-services.json no encontrado${NC}"
    exit 1
fi

ANDROID_CERT_DEBUG=$(grep -o '"69f247b9d146aa5268ac8c6e863bcf14a853ffa4"' "$GSJ_PATH" | head -1)
ANDROID_CERT_RELEASE=$(grep -o '"aa4df0b8df3de533188ad4d5d5bec021cb4a61ec"' "$GSJ_PATH" | head -1)

if [ -z "$ANDROID_CERT_DEBUG" ]; then
    echo -e "${RED}✗ SHA-1 DEBUG no encontrado en google-services.json${NC}"
else
    echo -e "${GREEN}✓ SHA-1 DEBUG presente${NC}"
fi

if [ -z "$ANDROID_CERT_RELEASE" ]; then
    echo -e "${RED}✗ SHA-1 RELEASE no encontrado en google-services.json${NC}"
else
    echo -e "${GREEN}✓ SHA-1 RELEASE presente${NC}"
fi
echo ""

# ============ VERIFICACIÓN 3: Conectividad ADB ============
echo -e "${YELLOW}[3/6] Verificando ADB...${NC}"
if ! adb devices | grep -q "device"; then
    echo -e "${RED}✗ Dispositivo no conectado${NC}"
    echo "  Conecta un dispositivo Android con USB Debugging habilitado"
    exit 1
fi
DEVICE=$(adb devices | grep "device" | grep -v "devices" | awk '{print $1}' | head -1)
echo -e "${GREEN}✓ Dispositivo conectado: $DEVICE${NC}"
echo ""

# ============ VERIFICACIÓN 4: Instalar APK ============
echo -e "${YELLOW}[4/6] Instalando APK...${NC}"
adb uninstall "$PACKAGE_NAME" 2>/dev/null || true
if ! adb install "$APK_PATH" > /tmp/adb_install.log 2>&1; then
    echo -e "${RED}✗ Error al instalar APK${NC}"
    cat /tmp/adb_install.log
    exit 1
fi
echo -e "${GREEN}✓ APK instalado${NC}"
echo ""

# ============ VERIFICACIÓN 5: Verificar instalación ============
echo -e "${YELLOW}[5/6] Verificando que la app está instalada...${NC}"
if ! adb shell pm list packages | grep -q "$PACKAGE_NAME"; then
    echo -e "${RED}✗ App no está instalada${NC}"
    exit 1
fi
echo -e "${GREEN}✓ App instalada correctamente${NC}"

# Ver versión instalada
APP_VERSION=$(adb shell dumpsys package "$PACKAGE_NAME" | grep versionName | head -1 | awk '{print $NF}')
echo -e "  Versión: $APP_VERSION"
echo ""

# ============ VERIFICACIÓN 6: Capturar logs ============
echo -e "${YELLOW}[6/6] Preparando captura de logs...${NC}"
adb logcat --clear
LOG_FILE="$LOG_DIR/google_signin_${TIMESTAMP}.log"
echo -e "${GREEN}✓ Logs se guardarán en: $LOG_FILE${NC}"
echo ""

# ============ RESUMEN ============
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ VERIFICACIONES COMPLETADAS${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
echo ""
echo "1. La app se abrirá automáticamente en unos segundos"
echo "2. En tu dispositivo:"
echo "   • Espera a que cargue la pantalla de login"
echo "   • Presiona el botón 'Iniciar sesión con Google'"
echo "   • Observa si aparece el selector de cuentas o si da error"
echo ""
echo "3. La captura dura 30 segundos (solo procesos de tu app + GMS)"
echo ""
echo -e "${YELLOW}INICIANDO CAPTURA DE LOGS...${NC}"

# Abrir la app automáticamente
adb shell am start -n "$PACKAGE_NAME/.MainActivity" > /dev/null 2>&1 || true
sleep 5

# Obtener PIDs de la app y de Google Play Services (donde ocurren los errores de auth)
# NOTA: en algunos dispositivos (MIUI/Xiaomi) `logcat --pid` no acepta listas con coma
# y `--uid` no filtra. Solución portable: grep por la columna de PID de cada línea.
APP_PIDS=$(adb shell pidof "$PACKAGE_NAME" 2>/dev/null | tr -d '\r' | tr ' ' '|')
GMS_PIDS=$(adb shell pidof com.google.android.gms 2>/dev/null | tr -d '\r' | tr ' ' '|')
PID_FILTER="${APP_PIDS}|${GMS_PIDS}"

echo ""
echo "📱 Capturando SOLO estos procesos: $(echo "$PID_FILTER" | tr '|' ' ')"
echo "   (app + Google Play Services — nada de otras apps)"
echo "   Toca 'Iniciar sesión con Google' ahora..."
echo ""
echo "------- LOGS DE FIREBASE / GOOGLE -------"

# Capturar solo las líneas cuyo PID coincide con la app o GMS
run_with_timeout 30 adb logcat 2>&1 | grep -E "^[0-9]{2}-[0-9]{2} [0-9:.]+ +($PID_FILTER) " | tee "$LOG_FILE" | grep --line-buffered -i -E 'firebase|google|auth|error|blocked|exception' &
CAPTURE_PID=$!

# Esperar a que termine o usuario presione Ctrl+C
wait $CAPTURE_PID 2>/dev/null || true

echo ""
echo "------- FIN DE CAPTURA -------"
echo ""

# ============ ANÁLISIS DE LOGS ============
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}ANALIZANDO LOGS...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Buscar errores críticos
if grep -q -i "blocked" "$LOG_FILE"; then
    echo -e "${RED}⚠️  ERROR ENCONTRADO: 'blocked'${NC}"
    grep -i "blocked" "$LOG_FILE" | head -3
    echo ""
fi

if grep -q -i "firebase.*error\|error.*firebase" "$LOG_FILE"; then
    echo -e "${RED}⚠️  ERRORES FIREBASE DETECTADOS${NC}"
    grep -i "firebase.*error\|error.*firebase" "$LOG_FILE" | head -3
    echo ""
fi

if grep -q -i "google.*exception\|exception.*google" "$LOG_FILE"; then
    echo -e "${RED}⚠️  EXCEPCIONES DE GOOGLE${NC}"
    grep -i "google.*exception\|exception.*google" "$LOG_FILE" | head -3
    echo ""
fi

if grep -q -i "successfully\|success\|authenticated" "$LOG_FILE"; then
    echo -e "${GREEN}✓ LOG DE ÉXITO DETECTADO${NC}"
    grep -i "successfully\|success\|authenticated" "$LOG_FILE" | head -3
    echo ""
fi

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}LOGS COMPLETOS GUARDADOS EN:${NC}"
echo -e "${GREEN}$LOG_FILE${NC}"
echo ""
echo "Para análisis posterior, ejecuta:"
echo "  cat $LOG_FILE | grep -i 'firebase\\|google\\|auth'"
echo -e "${BLUE}════════════════════════════════════════${NC}"
