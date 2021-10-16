.PHONY: test clean

DIR_SRC		:= src
DIR_BUILD	:= build

MAIN_SRC_FILE	:= $(DIR_SRC)/hello.asm

TARGET_BASENAME	:= $(DIR_BUILD)/$(notdir $(basename $(MAIN_SRC_FILE)))
TARGET		:= $(TARGET_BASENAME).prg

all: $(TARGET)

$(TARGET): $(MAIN_SRC_FILE)
	@mkdir -p $(dir $@)
	acme -v9 --cpu m65 -o $@ -l $(TARGET_BASENAME).labels -I $(DIR_SRC) $<

test: $(TARGET)
	xmega65 -besure -prgmode 65 -prg $<

clean:
	rm -rf $(DIR_BUILD)
