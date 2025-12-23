  Следующие шаги:

  Критически важно:

  1. Сгенерировать PLL IP core в Gowin IDE:
    - Input: 27 MHz
    - Output 1: 21.477272 MHz (NTSC master)
    - Output 2: 48 MHz (USB)
    - Output 3: 3.579545 MHz (NTSC pixel)
    - Сохранить в hdl/ip/pll.v
    - Обновить clock_manager.v:82 (раскомментировать PLL instantiation)
  2. Собрать DAC схему (8-bit R-2R ladder) для видео выхода
  3. Протестировать на CRT - должны отобразиться цветные полосы

  Для разработки:

  # Проверить зависимости
  ./tools/build.sh check

  # Запустить симуляцию
  make sim

  # После генерации PLL - собрать проект
  make all

  # Прошить FPGA
  make program

