#!/usr/bin/env python3
"""
Конвертер текстового списка публичных ключей в упакованный .bin для -binfile.

Форматы, которые понимает Collider (-binfile), — записи ФИКСИРОВАННОГО размера,
все одинаковые в пределах файла; размер определяется по первому байту:
  * 33 байта: сжатый ключ  = 02/03 + X(32)
  * 65 байт:  несжатый ключ = 04 + X(32) + Y(32)

Этот скрипт по умолчанию пишет самый компактный вариант — сжатые 33-байтные записи
(≈33 МБ на миллион ключей против ≈130 МБ у hex-текста), что важно для десятков
миллионов ключей.

Вход (по строке на ключ, регистр и префикс 0x/пробелы игнорируются):
  * 66 hex-символов  — сжатый (02/03 + X)
  * 130 hex-символов — несжатый с префиксом (04 + X + Y)
  * 128 hex-символов — X||Y без префикса

Примеры:
  python3 keys_txt_to_bin.py keys.txt keys.bin            # -> сжатые 33B
  python3 keys_txt_to_bin.py --uncompressed keys.txt keys.bin   # -> 65B
"""
import argparse
import sys


def parse_key(line):
    """Разбирает строку. Возвращает:
       ('C', x_bytes(32), parity_int)   — сжатый (Y задан только чётностью), или
       ('U', x_bytes(32), y_bytes(32))  — несжатый (Y известен полностью), или
       None для пустой строки.
    """
    s = line.strip().lower().replace(" ", "")
    if s.startswith("0x"):
        s = s[2:]
    if not s:
        return None
    if len(s) == 66 and s[:2] in ("02", "03"):
        return ("C", bytes.fromhex(s[2:]), 0 if s[:2] == "02" else 1)
    if len(s) == 130 and s[:2] == "04":
        s = s[2:]  # снять префикс -> X||Y
    if len(s) == 128:
        return ("U", bytes.fromhex(s[:64]), bytes.fromhex(s[64:]))
    raise ValueError(f"нераспознанный ключ: {line.strip()!r} (len={len(s)})")


def main():
    ap = argparse.ArgumentParser(description="txt список pubkey -> упакованный .bin")
    ap.add_argument("input", help="текстовый файл, по ключу на строку")
    ap.add_argument("output", help="выходной .bin")
    ap.add_argument("--uncompressed", action="store_true",
                    help="писать 65-байтные несжатые записи (по умолчанию 33-байтные сжатые)")
    args = ap.parse_args()

    n = 0
    with open(args.input, "r", encoding="utf-8", errors="replace") as fin, \
         open(args.output, "wb") as fout:
        for lineno, line in enumerate(fin, 1):
            try:
                parsed = parse_key(line)
            except ValueError as e:
                sys.exit(f"[строка {lineno}] {e}")
            if parsed is None:
                continue
            kind, x, extra = parsed

            if args.uncompressed:
                if kind != "U":
                    sys.exit(f"[строка {lineno}] сжатый ключ нельзя записать как несжатый "
                             f"без восстановления Y (EC). Уберите --uncompressed.")
                fout.write(b"\x04" + x + extra)  # extra = y_bytes
            else:
                if kind == "U":
                    parity = extra[-1] & 1     # extra = y_bytes
                else:
                    parity = extra             # extra = parity int
                fout.write(bytes([0x02 if parity == 0 else 0x03]) + x)
            n += 1

    rec = 65 if args.uncompressed else 33
    print(f"Готово: {n} ключей -> {args.output} ({rec} Б/запись, {n * rec} Б всего)")


if __name__ == "__main__":
    main()
