############################################################################
#    Copyright (C) 2011 by Martin Schmoelzer                               #
#    <martin.schmoelzer@student.tuwien.ac.at>                              #
#                                                                          #
#    This program is free software; you can redistribute it and/or modify  #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation; either version 2 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    This program is distributed in the hope that it will be useful,       #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with this program; if not, write to the                         #
#    Free Software Foundation, Inc.,                                       #
#    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
############################################################################

# Define the name of our tools. Some distributions (e. g. Fedora) prefix
# the SDCC executables, change this accordingly!
PREFIX =

# Small Device C Compiler: http://sdcc.sourceforge.net/
CC = $(PREFIX)-sdcc

# 8051 assembler, part of the SDCC software package.
AS = $(PREFIX)-sdas8051

# SDCC produces quite messy Intel HEX files. This tool is be used to re-format
# those files. It is not required for the firmware download functionality in
# the OpenOCD driver, but the resulting file is smaller.
PACKIHX = $(PREFIX)-packihx

# GNU binutils size. Used to print the size of the IHX file generated by SDCC.
SIZE = size

# Source and header directories.
SRC_DIR     = src
INCLUDE_DIR = include

CODE_SIZE = 0x1B00

# Starting address of __xdata variables. Since the OpenULINK firmware does not
# use any of the isochronous interrupts, we can use the isochronous buffer space
# as XDATA memory.
XRAM_LOC  = 0x2000
XRAM_SIZE = 0x0800

CFLAGS  = --std-sdcc99 --opt-code-size --model-small
LDFLAGS = --code-loc 0x0000 --code-size $(CODE_SIZE) --xram-loc $(XRAM_LOC) \
          --xram-size $(XRAM_SIZE) --iram-size 256 --model-small

# list of base object files
OBJECTS = main.rel usb.rel protocol.rel jtag.rel delay.rel USBJmpTb.rel
HEADERS = $(INCLUDE_DIR)/main.h         \
          $(INCLUDE_DIR)/usb.h          \
          $(INCLUDE_DIR)/protocol.h     \
          $(INCLUDE_DIR)/jtag.h         \
          $(INCLUDE_DIR)/delay.h        \
          $(INCLUDE_DIR)/reg_ezusb.h    \
          $(INCLUDE_DIR)/io.h           \
          $(INCLUDE_DIR)/msgtypes.h

# Disable all built-in rules.
.SUFFIXES:

# Targets which are executed even when identically named file is present.
.PHONY: all, clean

all: ulink_firmware.ihx
	$(SIZE) ulink_firmware.ihx

ulink_firmware.ihx: $(OBJECTS)
	$(CC) -mmcs51 $(LDFLAGS) -o $@ $^

# Rebuild every C module (there are only 5 of them) if any header changes.
%.rel: $(SRC_DIR)/%.c $(HEADERS)
	$(CC) -c $(CFLAGS) -mmcs51 -I$(INCLUDE_DIR) -o $@ $<

%.rel: $(SRC_DIR)/%.a51
	$(AS) -lsgo $@ $<

clean:
	rm -f *.asm *.lst *.rel *.rst *.sym *.ihx *.lnk *.map *.mem

hex: ulink_firmware.ihx
	$(PACKIHX) ulink_firmware.ihx > ulink_firmware.hex
