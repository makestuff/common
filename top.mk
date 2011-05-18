# Determine platform:
ifeq ($(OS),Windows_NT)
	PLATFORM := win32
	OBJ      := obj
	DLL      := dll
else
	PLATFORM := $(shell uname | tr [A-Z] [a-z])
	OBJ      := o
	DLL      := so
endif

# Config-agnostic defines:
ROOT      := $(realpath $(ROOT))
CWD       := $(realpath .)
LOCALNAME := $(notdir $(CWD))
INCLUDES  := -I$(ROOT)/common $(shell for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/incs.txt); do cat $$i; done)
CC_SRCS   := $(wildcard *.c) $(foreach ESD,$(EXTRA_SRC_DIRS),$(wildcard $(ESD)/*.c))
CPP_SRCS  := $(wildcard *.cpp) $(foreach ESD,$(EXTRA_SRC_DIRS),$(wildcard $(ESD)/*.cpp))
GENINCS   := echo -I$(CWD)

# Release config defines:
OUTDIR_REL    := $(PLATFORM)/rel
OBJDIR_REL    := $(OUTDIR_REL)/.build
EXTRA_OBJ_REL := $(foreach ESD,$(EXTRA_SRC_DIRS),$(OBJDIR_REL)/$(ESD))
OBJS_REL      := $(CC_SRCS:%.c=$(OBJDIR_REL)/%.$(OBJ)) $(CPP_SRCS:%.cpp=$(OBJDIR_REL)/%.$(OBJ))
GENDEPS_REL   := for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/rel/libs.txt); do cat $$i; done
DLLS_REL      := $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.$(DLL)))

# Platform-specific stuff:
ifeq ($(PLATFORM),linux)
	CFLAGS         = -c -Wall -Wextra -Wstrict-prototypes -Wundef -std=c99 -pedantic-errors -Wno-missing-field-initializers $(INCLUDES) -MMD -MP -MF $@.d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
	CPPFLAGS       = -c -Wall -Wextra -Wundef -std=c++98 -pedantic-errors $(INCLUDES) -MMD -MP -MF $@.d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
	ifeq ($(TYPE),lib)
		TARGET      := $(LOCALNAME).a
		GENLIBS_REL := (echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%); $(GENDEPS_REL))
		LINK_REL    := ar cr $(OUTDIR_REL)/$(TARGET) $(OBJS_REL); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = gcc -fPIC -O3 $(CFLAGS)
		CPP_REL      = g++ -fPIC -O3 $(CPPFLAGS)
	else ifeq ($(TYPE),dll)
		TARGET      := $(LOCALNAME).so
		GENLIBS_REL := echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%)
		LINK_REL    := gcc -shared -Wl,-soname,$(TARGET) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(shell $(GENDEPS_REL)); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = gcc -fPIC -O3 $(CFLAGS)
		CPP_REL      = g++ -fPIC -O3 $(CPPFLAGS)
	else ifeq ($(TYPE),exe)
		ifeq ($(LOCALNAME),tests)
			TESTINCS     := $(shell cat ../$(PLATFORM)/incs.txt 2> /dev/null) -I$(ROOT)/libs/libutpp
			TESTOBJS_REL := $(patsubst %/main.$(OBJ),,$(wildcard ../$(OBJDIR_REL)/*.$(OBJ))) $(ROOT)/libs/libutpp/$(OUTDIR_REL)/libutpp.a
			TESTEXE_REL  := LD_LIBRARY_PATH=$(OUTDIR_REL) $(OUTDIR_REL)/tests
		else
			TESTINCS     :=
			TESTOBJS_REL :=
			TESTEXE_REL  :=
		endif
		TARGET      := $(LOCALNAME)
		GENLIBS_REL := $(GENDEPS_REL)
		LINK_REL    := g++ -Wl,--relax -Wl,--gc-sections -Wl,-Map=$(OBJDIR_REL)/$(TARGET).map,--cref -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENDEPS_REL)); strip $(OUTDIR_REL)/$(TARGET); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = gcc -O3 $(TESTINCS) $(CFLAGS)
		CPP_REL      = g++ -O3 $(TESTINCS) $(CPPFLAGS)
	endif
endif

# Config-agnostic rules:
all: $(PLATFORM)/incs.txt rel
	@for i in $(SUBDIRS); do make -C $$i; done

$(PLATFORM)/incs.txt: $(PLATFORM)
	$(GENINCS) > $@

clean: FORCE
	@for i in $(SUBDIRS); do make -C $$i clean; done
	rm -rf $(PLATFORM)

FORCE:


# Release config rules:
rel: $(OUTDIR_REL)/libs.txt $(OBJDIR_REL) $(EXTRA_OBJ_REL) $(OUTDIR_REL)/$(TARGET)
	$(TESTEXE_REL)

$(OUTDIR_REL)/libs.txt: $(OUTDIR_REL)
	($(GENLIBS_REL); $(GENEXTRALIBS_REL)) > $@

$(PLATFORM) $(OBJDIR_REL) $(OUTDIR_REL) $(EXTRA_OBJ_REL):
	mkdir -p $@

$(OUTDIR_REL)/$(TARGET): $(OBJDIR_REL) $(OBJS_REL)
	$(LINK_REL)

$(OBJDIR_REL)/%.$(OBJ) : %.c
	$(CC_REL)

$(OBJDIR_REL)/%.$(OBJ) : %.cpp
	$(CPP_REL)
