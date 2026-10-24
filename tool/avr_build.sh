#!/system/bin/sh
# NEXUS IDE on-phone Arduino build for ATmega328P boards (Uno, Nano); packed as avr/build.sh
# by build_android_toolchains.py. Run in the sketch folder after NEXUS writes build/sketch.cpp
# (arduino.ino + #include <Arduino.h> + prototypes, see sketchCpp in lib/core/arduino.dart).
# Usage: build.sh <variant> <board>    e.g. build.sh standard AVR_UNO
# No -flto (saves bundling lto1): sketches come out a little bigger than arduino-cli's.
set -e
A=${0%/*}
FLAGS="-mmcu=atmega328p -DF_CPU=16000000L -DARDUINO=10819 -DARDUINO_$2 -DARDUINO_ARCH_AVR -I$A/core -I$A/variants/$1 -Os -w -g0 -ffunction-sections -fdata-sections"
CXX="$A/bin/avr-c++ $FLAGS -std=gnu++11 -fpermissive -fno-exceptions -fno-threadsafe-statics -c"
CC="$A/bin/avr-gcc $FLAGS -std=gnu11 -c"
LIB=build/core-$1.a
if [ ! -f "$LIB" ]; then
  echo "Building the Arduino core (first time only, a few seconds)..."
  mkdir -p build/core
  rm -f build/core/*.o
  for f in "$A"/core/*.c "$A"/core/*.cpp "$A"/core/*.S; do
    o="build/core/${f##*/}.o"
    case $f in
      *.cpp) $CXX "$f" -o "$o" ;;
      *.c) $CC "$f" -o "$o" ;;
      *.S) $CC -x assembler-with-cpp "$f" -o "$o" ;;
    esac
  done
  "$A/avr/bin/ar" rcs "$LIB.tmp" build/core/*.o
  mv "$LIB.tmp" "$LIB"
fi
$CXX build/sketch.cpp -o build/sketch.o
"$A/bin/avr-gcc" -mmcu=atmega328p -Os -Wl,--gc-sections -o build/arduino.ino.elf build/sketch.o "$LIB" -lm
"$A/avr/bin/objcopy" -O ihex -R .eeprom build/arduino.ino.elf build/arduino.ino.hex
