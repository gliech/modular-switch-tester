PRESET_FILES = $(wildcard *.json)
getpresets = $(addprefix $(basename $(1))_, $(shell jq  \
             '.parameterSets|keys|join(" ")' $(1) --raw-output))
notlastpart = $(subst $() $(),_,$(wordlist 1,$(shell expr $(words $(subst _, ,\
              $(1))) - 1),$(subst _, ,$(1))))
STLS = $(addsuffix .stl, $(foreach a, $(PRESET_FILES), $(call getpresets,$a)))

all: $(STLS)

.SECONDEXPANSION:
$(STLS): %.stl: $$(foreach s, json scad, $$(call notlastpart,%).$$s)
	openscad -o $@ -P $(lastword $(subst _, ,$*)) -p $^
