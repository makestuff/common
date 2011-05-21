# Determine platform:
ifeq ($(OS),Windows_NT)
	PLATFORM := win32
	OBJ      := obj
	DLL      := dll
	EXE      := .exe
else
	PLATFORM := $(shell uname | tr [A-Z] [a-z])
	OBJ      := o
	DLL      := so
	EXE      := 
endif

# Config-agnostic defines:
CWD       := $(realpath .)
LOCALNAME := $(notdir $(CWD))
INCLUDES  := -I$(ROOT)/common $(EXTRA_INCS) $(shell for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/incs.txt); do cat $$i 2> /dev/null; done)
CC_SRCS   := $(wildcard *.c) $(foreach ESD,$(EXTRA_SRC_DIRS),$(wildcard $(ESD)/*.c)) $(EXTRA_CC_SRCS)
CPP_SRCS  := $(wildcard *.cpp) $(foreach ESD,$(EXTRA_SRC_DIRS),$(wildcard $(ESD)/*.cpp)) $(EXTRA_CPP_SRCS)
GENINCS   := echo -I$(CWD) $(EXTRA_INCS)

# Release config defines:
OUTDIR_REL    := $(PLATFORM)/rel
OBJDIR_REL    := $(OUTDIR_REL)/.build
EXTRA_OBJ_REL := $(foreach ESD,$(EXTRA_SRC_DIRS),$(OBJDIR_REL)/$(ESD)) $(sort $(foreach ESD,$(EXTRA_CC_SRCS) $(EXTRA_CPP_SRCS),$(OBJDIR_REL)/$(dir $(ESD))))
OBJS_REL      := $(CC_SRCS:%.c=$(OBJDIR_REL)/%.$(OBJ)) $(CPP_SRCS:%.cpp=$(OBJDIR_REL)/%.$(OBJ))
GENDEPS_REL   := for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/rel/libs.txt); do cat $$i 2> /dev/null; done
DLLS_REL      := $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.$(DLL)))

# Platform-specific stuff:
ifeq ($(PLATFORM),linux)
	ifeq ($(strip $(CFLAGS)),)
		CFLAGS := -c -Wall -Wextra -Wundef -pedantic-errors -std=c99 -Wstrict-prototypes -Wno-missing-field-initializers
	endif
	CLINE = $(CFLAGS) $(INCLUDES) -MMD -MP -MF $@.d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
	ifeq ($(strip $(CPPFLAGS)),)
		CPPFLAGS := -c -Wall -Wextra -Wundef -pedantic-errors -std=c++98
	endif
	CPPLINE = $(CPPFLAGS) $(INCLUDES) -MMD -MP -MF $@.d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
	ifeq ($(TYPE),lib)
		TARGET      := $(LOCALNAME).a
		GENLIBS_REL := (echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%); $(GENDEPS_REL))
		LINK_REL    := ar cr $(OUTDIR_REL)/$(TARGET) $(OBJS_REL); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = gcc -fPIC -O3 $(CLINE)
		CPP_REL      = g++ -fPIC -O3 $(CPPLINE)
	else ifeq ($(TYPE),dll)
		TARGET      := $(LOCALNAME).so
		GENLIBS_REL := echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%)
		LINK_REL    := gcc -shared -Wl,-soname,$(TARGET) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(shell $(GENDEPS_REL)); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = gcc -fPIC -O3 $(CLINE)
		CPP_REL      = g++ -fPIC -O3 $(CPPLINE)
	else ifeq ($(TYPE),exe)
		ifeq ($(LOCALNAME),tests)
			TESTINCS     := $(shell cat ../$(PLATFORM)/incs.txt 2> /dev/null) -I$(ROOT)/libs/libutpp
			TESTOBJS_REL := $(patsubst %/main.$(OBJ),,$(wildcard ../$(OBJDIR_REL)/*.$(OBJ))) $(ROOT)/libs/libutpp/$(OUTDIR_REL)/libutpp.a
			TESTEXE_REL  := $(OUTDIR_REL)/tests
		else
			TESTINCS     :=
			TESTOBJS_REL :=
			TESTEXE_REL  :=
		endif
		TARGET      := $(LOCALNAME)
		GENLIBS_REL := $(GENDEPS_REL)
		LINK_REL    := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done; $(if $(strip $(CPP_SRCS)),g++,gcc) -Wl,--relax,--gc-sections,-Map=$(OBJDIR_REL)/$(TARGET).map,--cref,-rpath,\$$ORIGIN,-rpath-link,$(OUTDIR_REL) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENDEPS_REL)) #; strip $(OUTDIR_REL)/$(TARGET)
		CC_REL       = gcc -O3 $(TESTINCS) $(CLINE)
		CPP_REL      = g++ -O3 $(TESTINCS) $(CPPLINE)
	endif
else ifeq ($(PLATFORM),win32)
	ifeq ($(strip $(CFLAGS)),)
		CFLAGS := -DWIN32 -D_CRT_SECURE_NO_WARNINGS -EHsc -W4 -nologo -c -errorReport:prompt
	endif
	CLINE := $(CFLAGS) $(INCLUDES)
	ifeq ($(TYPE),lib)
		TARGET      := $(LOCALNAME).lib
		GENLIBS_REL := (echo $(CWD)/$(OUTDIR_REL)/$(LOCALNAME).lib; $(GENDEPS_REL))
		LINK_REL    := lib -nologo -out:$(OUTDIR_REL)/$(TARGET) -ltcg $(OBJS_REL); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = cl -O2 -Oi $(CLINE) -DNDEBUG -D_LIB -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/$(LOCALNAME).pdb $<
		CPP_REL      = $(CC_REL)
	else ifeq ($(TYPE),dll)
		TARGET      := $(LOCALNAME).dll
		GENLIBS_REL := echo $(CWD)/$(OUTDIR_REL)/$(LOCALNAME).lib
		LINK_REL    := link -OUT:$(OUTDIR_REL)/$(TARGET) -INCREMENTAL:NO -NOLOGO -DLL -MANIFEST -MANIFESTFILE:$(OUTDIR_REL)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_REL)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT $(OBJS_REL) $(shell $(GENDEPS_REL)) kernel32.lib user32.lib; mt.exe -nologo -manifest $(OUTDIR_REL)/$(TARGET).intermediate.manifest "-outputresource:$(OUTDIR_REL)/$(TARGET);\#2"; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = cl -O2 -Oi $(CLINE) -DNDEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -GL -FD -MD -Gy -Zi -Fo$@ -Fd$(OUTDIR_REL)/ $<
		CPP_REL      = $(CC_REL)
	else ifeq ($(TYPE),exe)
		ifeq ($(LOCALNAME),tests)
			TESTINCS     := $(shell cat ../$(PLATFORM)/incs.txt 2> /dev/null) -I$(ROOT)/libs/libutpp
			TESTOBJS_REL := $(patsubst %/main.$(OBJ),,$(wildcard ../$(OBJDIR_REL)/*.$(OBJ))) $(ROOT)/libs/libutpp/$(OUTDIR_REL)/libutpp.lib
			TESTEXE_REL  := $(OUTDIR_REL)/tests
		else
			TESTINCS     :=
			TESTOBJS_REL :=
			TESTEXE_REL  :=
		endif
		TARGET      := $(LOCALNAME).exe
		GENLIBS_REL := $(GENDEPS_REL)
		LINK_REL    := link -OUT:$(OUTDIR_REL)/$(TARGET) -INCREMENTAL:NO -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_REL)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_REL)/$(TARGET).pdb -SUBSYSTEM:CONSOLE -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENDEPS_REL)) kernel32.lib user32.lib; mt.exe -nologo -manifest $(OUTDIR_REL)/$(TARGET).intermediate.manifest "-outputresource:$(OUTDIR_REL)/$(TARGET);\#1"; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = cl -O2 -Oi $(TESTINCS) $(CLINE) -DNDEBUG -D_CONSOLE -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/ $<
		CPP_REL      = $(CC_REL)
	endif
endif

# Config-agnostic rules:
all: $(PRE_BUILD) rel
	@for i in $(SUBDIRS); do make -C $$i; done

$(PLATFORM)/incs.txt: $(PLATFORM)
	$(GENINCS) > $@

clean: FORCE
	@for i in $(SUBDIRS); do make -C $$i clean; done
	rm -rf $(PLATFORM) $(EXTRA_CLEAN)

FORCE:


# Release config rules:
rel: $(PLATFORM)/incs.txt $(OUTDIR_REL)/libs.txt $(OBJDIR_REL) $(EXTRA_OBJ_REL) $(OUTDIR_REL)/$(TARGET)
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
