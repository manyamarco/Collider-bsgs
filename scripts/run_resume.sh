#!/bin/bash
# Watchdog для Collider-BSGS (Linux).
# Запускает программу и АВТОМАТИЧЕСКИ перезапускает её при сбое/аварийном закрытии,
# подхватывая последнее состояние из currentwork.txt через флаг -wl.
#
# Важно: сама программа НЕ возобновляется сама по себе — при рестарте нужно
# передать -wl currentwork.txt И те же самые параметры запуска (иначе проверка
# конфигурации settingsFingerPrint прервёт старт). Этот скрипт делает это за вас.
#
# Настройте BIN и ARGS под свою задачу и запускайте ТОЛЬКО этот скрипт.

set -u
cd "$(dirname "$0")/../x64" || exit 1

BIN="./Collider_Linux"

# --- Ваши параметры запуска (без -wl; watchdog добавит его сам) ---------------
# Пример конфигурации под RTX 3080 (10 ГБ). Подставьте свои -pb / -pk / -pke.
ARGS=(
  -d 0            # GPU #0
  -t 512          # потоков
  -b 68           # блоков (= число SM у RTX 3080)
  -w 29           # baby-steps 2^29  (~8 ГБ VRAM, влезает в 10 ГБ)
  -htsz 28        # hash table 2^28
  -wt 600         # автосохранение каждые 600 c = 10 минут
  # -pb <compressed_pubkey>
  # -pk <hex_range_start> -pke <hex_range_end>
)
# -----------------------------------------------------------------------------

RECOVERY_FILE="currentwork.txt"
RESTART_DELAY=5

while true; do
  RUN_ARGS=("${ARGS[@]}")
  if [ -f "$RECOVERY_FILE" ]; then
    echo "[watchdog] Найден $RECOVERY_FILE — возобновляю с чекпоинта."
    RUN_ARGS+=(-wl "$RECOVERY_FILE")
  else
    echo "[watchdog] Чекпоинта нет — запуск с нуля."
  fi

  echo "[watchdog] $(date '+%F %T')  $BIN ${RUN_ARGS[*]}"
  "$BIN" "${RUN_ARGS[@]}"
  code=$?

  echo "[watchdog] Программа завершилась с кодом $code."
  # Код 0 обычно означает штатное завершение (ключ найден / диапазон пройден).
  if [ "$code" -eq 0 ]; then
    echo "[watchdog] Штатное завершение — watchdog остановлен."
    break
  fi
  echo "[watchdog] Перезапуск через ${RESTART_DELAY}c... (Ctrl+C чтобы прервать)"
  sleep "$RESTART_DELAY"
done
