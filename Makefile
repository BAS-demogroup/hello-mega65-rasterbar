.PHONY: test d81 testd81 clean

# Configurable Section
###########################################
PROJECT_NAME	:= hellorb
DIR_SRC		:= src
DIR_BUILD	:= build
MAIN_SRC_FILE	:= $(DIR_SRC)/main.asm

# Internal Variables
###########################################
TARGET_BASENAME	:= $(DIR_BUILD)/$(PROJECT_NAME)
TARGET		:= $(TARGET_BASENAME).prg
IMAGE_D81	:= $(TARGET_BASENAME).d81

PWD		:= $(shell pwd)

all: $(TARGET)

$(TARGET): $(MAIN_SRC_FILE)
	@mkdir -p $(dir $@)
	acme -v9 --cpu m65 -o $@ -f cbm -l $(TARGET_BASENAME).labels -I $(DIR_SRC) $<

test: $(TARGET)
	xmega65 -fullborders -besure -prgmode 65 -prg $<

$(IMAGE_D81): $(TARGET)
	c1541 -format diskname,id d81 $(PWD)/$@ -attach $(PWD)/$@ -write $(PWD)/$< $(PROJECT_NAME)

d81: $(IMAGE_D81)

testd81: $(IMAGE_D81)
	xmega65 -fullborders -besure -autoload -8 $<

clean:
	rm -rf $(DIR_BUILD)
