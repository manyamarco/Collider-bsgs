@echo off
REM Watchdog для Collider-BSGS (Windows).
REM Перезапускает программу при сбое/закрытии и подхватывает currentwork.txt через -wl.
REM Настройте BIN и ARGS под свою задачу и запускайте ТОЛЬКО этот .bat.

setlocal enabledelayedexpansion
cd /d "%~dp0..\x64"

set "BIN=Collider.exe"

REM --- Ваши параметры запуска (без -wl; watchdog добавит его сам) ---------------
REM Пример под RTX 3080 (10 ГБ). Подставьте свои -pb / -pk / -pke.
set "ARGS=-d 0 -t 512 -b 68 -w 29 -htsz 28 -wt 600"
REM   -wt 600 = автосохранение каждые 10 минут
REM   добавьте: -pb <pubkey>  или  -pk <start> -pke <end>
REM -----------------------------------------------------------------------------

set "RECOVERY=currentwork.txt"

:loop
if exist "%RECOVERY%" (
  echo [watchdog] Найден %RECOVERY% — возобновляю с чекпоинта.
  set "RUN=%ARGS% -wl %RECOVERY%"
) else (
  echo [watchdog] Чекпоинта нет — запуск с нуля.
  set "RUN=%ARGS%"
)

echo [watchdog] %date% %time%  %BIN% !RUN!
"%BIN%" !RUN!
set "code=%errorlevel%"

echo [watchdog] Программа завершилась с кодом !code!.
if "!code!"=="0" (
  echo [watchdog] Штатное завершение — watchdog остановлен.
  goto :eof
)
echo [watchdog] Перезапуск через 5 секунд... (Ctrl+C чтобы прервать)
timeout /t 5 /nobreak >nul
goto loop
