#
# Copyright (C) 2011 Chris McClelland
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Determine platform:
ifeq ($(OS),Windows_NT)
	PLATFORM := win32
	OBJ      := obj
	DLL      := dll
	EXE      := .exe
else
	PLATFORM := $(shell uname | tr [A-Z] [a-z])
	OBJ      := o
	EXE      := 
	ifeq ($(PLATFORM),darwin)
		DLL  := dylib
	else
		MACHINE := $(shell uname -m)
		ifeq ($(MACHINE),x86_64)
			ARCHFLAGS := -m64 -DBYTE_ORDER=1234
			PLATFORM := $(PLATFORM).$(MACHINE)
		else ifeq ($(MACHINE),i686)
			ARCHFLAGS := -m32 -DBYTE_ORDER=1234
			PLATFORM := $(PLATFORM).$(MACHINE)
		else ifneq (,$(findstring armv,$(MACHINE)))
			ARCHFLAGS := -DBYTE_ORDER=1234
			PLATFORM := $(PLATFORM).armel
		else ifeq ($(MACHINE),ppc)
			ARCHFLAGS := -DBYTE_ORDER=4321
			PLATFORM := $(PLATFORM).$(MACHINE)
		endif
		DLL  := so
	endif
endif

# Config-agnostic defines:
CWD       := $(realpath .)
LOCALNAME := $(notdir $(CWD))
INCLUDES  := -I$(ROOT)/common $(EXTRA_INCS) $(shell for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/incs.txt); do cat $$i 2>/dev/null; done)
ifeq ($(strip $(CC_SRCS)),)
	CC_SRCS   := $(wildcard *.c) $(foreach ESD,$(EXTRA_SRC_DIRS),$(wildcard $(ESD)/*.c)) $(EXTRA_CC_SRCS)
endif
ifeq ($(strip $(CPP_SRCS)),)
	CPP_SRCS  := $(wildcard *.cpp) $(foreach ESD,$(EXTRA_SRC_DIRS),$(wildcard $(ESD)/*.cpp)) $(EXTRA_CPP_SRCS)
endif
GENINCS   := echo -I$(CWD) $(EXTRA_INCS)
DEPDIRS   := $(DEPS:%=$(ROOT)/libs/lib%)
ifeq ($(strip $(CONFIGS)),)
	CONFIGS = dbg rel
endif

# Release config defines:
OUTDIR_REL    := $(PLATFORM)/rel
OBJDIR_REL    := $(OUTDIR_REL)/.build
EXTRA_OBJ_REL := $(foreach ESD,$(EXTRA_SRC_DIRS),$(OBJDIR_REL)/$(ESD)) $(sort $(foreach ESD,$(EXTRA_CC_SRCS) $(EXTRA_CPP_SRCS),$(OBJDIR_REL)/$(dir $(ESD))))
OBJS_REL      := $(CC_SRCS:%.c=$(OBJDIR_REL)/%.$(OBJ)) $(CPP_SRCS:%.cpp=$(OBJDIR_REL)/%.$(OBJ))
GENDEPS_REL   := for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/rel/libs.txt); do cat $$i 2>/dev/null; done
DLLS_REL      := $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.$(DLL)))

# Debug config defines:
OUTDIR_DBG    := $(PLATFORM)/dbg
OBJDIR_DBG    := $(OUTDIR_DBG)/.build
EXTRA_OBJ_DBG := $(foreach ESD,$(EXTRA_SRC_DIRS),$(OBJDIR_DBG)/$(ESD)) $(sort $(foreach ESD,$(EXTRA_CC_SRCS) $(EXTRA_CPP_SRCS),$(OBJDIR_DBG)/$(dir $(ESD))))
OBJS_DBG      := $(CC_SRCS:%.c=$(OBJDIR_DBG)/%.$(OBJ)) $(CPP_SRCS:%.cpp=$(OBJDIR_DBG)/%.$(OBJ))
GENDEPS_DBG   := for i in $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM)/dbg/libs.txt); do cat $$i 2>/dev/null; done
DLLS_DBG      := $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/*.$(DLL)))

# Platform-specific stuff:
ifneq (,$(findstring linux,$(PLATFORM)))
	ifeq ($(strip $(CFLAGS)),)
		CFLAGS := -c $(ARCHFLAGS) -Wall -Wextra -Wundef -pedantic-errors -std=c99 -Wstrict-prototypes -Wno-missing-field-initializers -Wstrict-aliasing=3 -fstrict-aliasing $(EXTRA_CFLAGS) -I.
	endif
	CLINE = $(CFLAGS) $(INCLUDES) -MMD -MP -MF $@.d -Wa,-adhlns=$@.lst $< -o $@
	ifeq ($(strip $(CPPFLAGS)),)
		CPPFLAGS := -c $(ARCHFLAGS) -Wall -Wextra -Wundef -pedantic-errors -Wstrict-aliasing=3 -fstrict-aliasing -std=c++98 $(EXTRA_CPPFLAGS) -I.
	endif
	CPPLINE = $(CPPFLAGS) $(INCLUDES) -MMD -MP -MF $@.d -Wa,-adhlns=$@.lst $< -o $@
	ifeq ($(TYPE),lib)
		TARGET      := $(LOCALNAME).a
		GENLIBS_REL := (echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%); $(GENDEPS_REL))
		LINK1_REL   := ar cr $(OUTDIR_REL)/$(TARGET) $(OBJS_REL)
		LINK2_REL   := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK3_REL   := 
		CC_REL       = gcc -fPIC -O3 $(CLINE)
		CPP_REL      = g++ -fPIC -O3 $(CPPLINE)
		GENLIBS_DBG := (echo -L$(CWD)/$(OUTDIR_DBG) -l$(LOCALNAME:lib%=%); $(GENDEPS_DBG))
		LINK1_DBG   := ar cr $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG)
		LINK2_DBG   := for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		LINK3_DBG   := 
		CC_DBG       = gcc -fPIC -g $(CLINE)
		CPP_DBG      = g++ -fPIC -g $(CPPLINE)
	else ifeq ($(TYPE),dll)
		TARGET      := $(LOCALNAME).so
		GENLIBS_REL := echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%)
		LINK1_REL   := gcc -shared $(ARCHFLAGS) -Wl,-soname,$(TARGET) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(shell $(GENDEPS_REL)) $(LINK_EXTRALIBS_REL)
		LINK2_REL   := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK3_REL   := 
		CC_REL       = gcc -fPIC -O3 $(CLINE)
		CPP_REL      = g++ -fPIC -O3 $(CPPLINE)
		GENLIBS_DBG := echo -L$(CWD)/$(OUTDIR_DBG) -l$(LOCALNAME:lib%=%)
		LINK1_DBG   := gcc -shared $(ARCHFLAGS) -Wl,-soname,$(TARGET) -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG) $(shell $(GENDEPS_DBG)) $(LINK_EXTRALIBS_DBG)
		LINK2_DBG   := for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		LINK3_DBG   := 
		CC_DBG       = gcc -fPIC -g $(CLINE)
		CPP_DBG      = g++ -fPIC -g $(CPPLINE)
	else ifeq ($(TYPE),exe)
		ifneq (,$(findstring tests,$(LOCALNAME)))
			TESTINCS     := $(shell cat ../$(PLATFORM)/incs.txt 2>/dev/null) -I$(ROOT)/libs/libutpp
			ifneq ($(notdir $(realpath ..)),libutpp)
				PRE_BUILD    := $(ROOT)/libs/libutpp/$(PLATFORM) $(PRE_BUILD)
			endif
			TESTOBJS_REL := $(patsubst %/main.$(OBJ),,$(shell find ../$(OBJDIR_REL) -name "*.$(OBJ)" 2>/dev/null)) $(ROOT)/libs/libutpp/$(OUTDIR_REL)/libutpp.a
			TESTEXE_REL  := $(OUTDIR_REL)/$(LOCALNAME)
			TESTOBJS_DBG := $(patsubst %/main.$(OBJ),,$(shell find ../$(OBJDIR_DBG) -name "*.$(OBJ)" 2>/dev/null)) $(ROOT)/libs/libutpp/$(OUTDIR_DBG)/libutpp.a
			TESTEXE_DBG  := $(OUTDIR_DBG)/$(LOCALNAME)
		else
			TESTINCS     :=
			TESTOBJS_REL :=
			TESTEXE_REL  :=
			TESTOBJS_DBG :=
			TESTEXE_DBG  :=
		endif
		TARGET      := $(LOCALNAME)
		GENLIBS_REL := $(GENDEPS_REL)
		LINK1_REL   := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK2_REL   := $(if $(strip $(CPP_SRCS)),g++,gcc) $(ARCHFLAGS) -Wl,--relax,--gc-sections,-Map=$(OBJDIR_REL)/$(TARGET).map,--cref,-rpath,\$$ORIGIN,-rpath-link,$(OUTDIR_REL) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENDEPS_REL)) $(LINK_EXTRALIBS_REL)
		LINK3_REL   := strip $(OUTDIR_REL)/$(TARGET)
		CC_REL       = gcc -O3 $(TESTINCS) $(CLINE)
		CPP_REL      = g++ -O3 $(TESTINCS) $(CPPLINE)
		GENLIBS_DBG := $(GENDEPS_DBG)
		LINK1_DBG   := for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		LINK2_DBG   := $(if $(strip $(CPP_SRCS)),g++,gcc) $(ARCHFLAGS) -Wl,--relax,--gc-sections,-Map=$(OBJDIR_DBG)/$(TARGET).map,--cref,-rpath,\$$ORIGIN,-rpath-link,$(OUTDIR_DBG) -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG) $(TESTOBJS_DBG) $(shell $(GENDEPS_DBG)) $(LINK_EXTRALIBS_DBG)
		LINK3_DBG   := 
		CC_DBG       = gcc -g $(TESTINCS) $(CLINE)
		CPP_DBG      = g++ -g $(TESTINCS) $(CPPLINE)
	endif
else ifeq ($(PLATFORM),darwin)
	ifeq ($(strip $(CFLAGS)),)
		CFLAGS := -c -arch i386 -arch x86_64 -DBYTE_ORDER=1234 -Wall -Wextra -Wundef -pedantic-errors -std=c99 -Wstrict-prototypes -Wno-missing-field-initializers -Wstrict-aliasing=3 -fstrict-aliasing $(EXTRA_CFLAGS) -I.
	endif
	CLINE = $(CFLAGS) $(INCLUDES) -o $@ $<
	ifeq ($(strip $(CPPFLAGS)),)
		CPPFLAGS := -c -arch i386 -arch x86_64 -DBYTE_ORDER=1234 -Wall -Wextra -Wundef -pedantic-errors -Wstrict-aliasing=3 -fstrict-aliasing -std=c++98 $(EXTRA_CPPFLAGS) -I.
	endif
	CPPLINE = $(CPPFLAGS) $(INCLUDES) -o $@ $<
	ifeq ($(TYPE),lib)
		TARGET      := $(LOCALNAME).a
		GENLIBS_REL := (echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%); $(GENDEPS_REL))
		LINK1_REL   := libtool -static -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL)
		LINK2_REL   := for i in $(DLLS_REL); do cp $$i $(OUTDIR_REL); done
		LINK3_REL   := 
		CC_REL       = gcc -fPIC -O3 $(CLINE)
		CPP_REL      = g++ -fPIC -O3 $(CPPLINE)
		GENLIBS_DBG := (echo -L$(CWD)/$(OUTDIR_DBG) -l$(LOCALNAME:lib%=%); $(GENDEPS_DBG))
		LINK1_DBG   := libtool -static -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG)
		LINK2_DBG   := for i in $(DLLS_DBG); do cp $$i $(OUTDIR_DBG); done
		LINK3_DBG   := 
		CC_DBG       = gcc -fPIC -gstabs+ $(CLINE)
		CPP_DBG      = g++ -fPIC -gstabs+ $(CPPLINE)
	else ifeq ($(TYPE),dll)
		TARGET      := $(LOCALNAME).dylib
		GENLIBS_REL := echo -L$(CWD)/$(OUTDIR_REL) -l$(LOCALNAME:lib%=%)
		LINK1_REL   := gcc -dynamiclib -arch i386 -arch x86_64 -Wl,-install_name,@rpath/$(TARGET) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(shell $(GENDEPS_REL)) $(LINK_EXTRALIBS_REL)
		LINK2_REL   := for i in $(DLLS_REL); do cp $$i $(OUTDIR_REL); done
		LINK3_REL   := 
		CC_REL       = gcc -fPIC -O3 $(CLINE)
		CPP_REL      = g++ -fPIC -O3 $(CPPLINE)
		GENLIBS_DBG := echo -L$(CWD)/$(OUTDIR_DBG) -l$(LOCALNAME:lib%=%)
		LINK1_DBG   := gcc -dynamiclib -arch i386 -arch x86_64 -Wl,-install_name,@rpath/$(TARGET) -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG) $(shell $(GENDEPS_DBG)) $(LINK_EXTRALIBS_DBG)
		LINK2_DBG   := for i in $(DLLS_DBG); do cp $$i $(OUTDIR_DBG); done
		LINK3_DBG   := 
		CC_DBG       = gcc -fPIC -gstabs+ $(CLINE)
		CPP_DBG      = g++ -fPIC -gstabs+ $(CPPLINE)
	else ifeq ($(TYPE),exe)
		ifneq (,$(findstring tests,$(LOCALNAME)))
			TESTINCS     := $(shell cat ../$(PLATFORM)/incs.txt 2>/dev/null) -I$(ROOT)/libs/libutpp
			ifneq ($(notdir $(realpath ..)),libutpp)
				PRE_BUILD    := $(ROOT)/libs/libutpp/$(PLATFORM) $(PRE_BUILD)
			endif
			TESTOBJS_REL := $(patsubst %/main.$(OBJ),,$(shell find ../$(OBJDIR_REL) -name "*.$(OBJ)" 2>/dev/null)) $(ROOT)/libs/libutpp/$(OUTDIR_REL)/libutpp.a
			TESTEXE_REL  := $(OUTDIR_REL)/$(LOCALNAME)
			TESTOBJS_DBG := $(patsubst %/main.$(OBJ),,$(shell find ../$(OBJDIR_DBG) -name "*.$(OBJ)" 2>/dev/null)) $(ROOT)/libs/libutpp/$(OUTDIR_DBG)/libutpp.a
			TESTEXE_DBG  := $(OUTDIR_DBG)/$(LOCALNAME)
		else
			TESTINCS     :=
			TESTOBJS_REL :=
			TESTEXE_REL  :=
			TESTOBJS_DBG :=
			TESTEXE_DBG  :=
		endif
		TARGET      := $(LOCALNAME)
		GENLIBS_REL := $(GENDEPS_REL)
		LINK1_REL   := for i in $(DLLS_REL); do cp $$i $(OUTDIR_REL); done
		LINK2_REL   := $(if $(strip $(CPP_SRCS)),g++,gcc) -arch i386 -arch x86_64 -Wl,-rpath,@loader_path/ -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENDEPS_REL)) $(LINK_EXTRALIBS_REL)
		LINK3_REL   := strip $(OUTDIR_REL)/$(TARGET)
		CC_REL       = gcc -O3 $(TESTINCS) $(CLINE)
		CPP_REL      = g++ -O3 $(TESTINCS) $(CPPLINE)
		GENLIBS_DBG := $(GENDEPS_DBG)
		LINK1_DBG   := for i in $(DLLS_DBG); do cp $$i $(OUTDIR_DBG); done
		LINK2_DBG   := $(if $(strip $(CPP_SRCS)),g++,gcc) -arch i386 -arch x86_64 -Wl,-rpath,@loader_path/ -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG) $(TESTOBJS_DBG) $(shell $(GENDEPS_DBG)) $(LINK_EXTRALIBS_DBG)
		LINK3_DBG   := 
		CC_DBG       = gcc -gstabs+ $(TESTINCS) $(CLINE)
		CPP_DBG      = g++ -gstabs+ $(TESTINCS) $(CPPLINE)
	endif
else ifeq ($(PLATFORM),win32)
	ifeq ($(strip $(CFLAGS)),)
		CFLAGS := -DBYTE_ORDER=1234 -DWIN32 -D_CRT_SECURE_NO_WARNINGS -EHsc -W4 -nologo -c -errorReport:prompt  $(EXTRA_CFLAGS) -I.
	endif
	CLINE := $(CFLAGS) $(INCLUDES)
	ifeq ($(TYPE),lib)
		TARGET      := $(LOCALNAME).lib
		GENLIBS_REL := (echo $(CWD)/$(OUTDIR_REL)/$(LOCALNAME).lib; $(GENDEPS_REL))
		LINK1_REL   := lib -nologo -out:$(OUTDIR_REL)/$(TARGET) -ltcg $(OBJS_REL)
		LINK2_REL   := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK3_REL   := 
		CC_REL       = cl -O2 -Oi $(CLINE) -DNDEBUG -D_LIB -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/$(LOCALNAME).pdb $<
		CPP_REL      = $(CC_REL)
		GENLIBS_DBG := (echo $(CWD)/$(OUTDIR_DBG)/$(LOCALNAME).lib; $(GENDEPS_DBG))
		LINK1_DBG   := lib -nologo -out:$(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG)
		LINK2_DBG   := for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		LINK3_DBG   := 
		CC_DBG       = cl -Od $(CLINE) -D_DEBUG -D_LIB -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/$(LOCALNAME).pdb $<
		CPP_DBG      = $(CC_DBG)
	else ifeq ($(TYPE),dll)
		TARGET      := $(LOCALNAME).dll
		LOCALNAMEUPPER = $(shell echo $(LOCALNAME) | tr [a-z] [A-Z])
		GENLIBS_REL := echo $(CWD)/$(OUTDIR_REL)/$(LOCALNAME).lib
		LINK1_REL   := link -OUT:$(OUTDIR_REL)/$(TARGET) -INCREMENTAL:NO -NOLOGO -DLL -MANIFEST -MANIFESTFILE:$(OUTDIR_REL)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_REL)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT $(OBJS_REL) $(shell $(GENDEPS_REL)) kernel32.lib user32.lib $(LINK_EXTRALIBS_REL)
		LINK2_REL   := mt.exe -nologo -manifest $(OUTDIR_REL)/$(TARGET).intermediate.manifest "-outputresource:$(OUTDIR_REL)/$(TARGET);\#2"
		LINK3_REL   := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = cl -O2 -Oi $(CLINE) -DNDEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -GL -FD -MD -Gy -Zi -Fo$@ -Fd$(OUTDIR_REL)/$(LOCALNAME).pdb $<
		CPP_REL      = $(CC_REL)
		GENLIBS_DBG := echo $(CWD)/$(OUTDIR_DBG)/$(LOCALNAME).lib
		LINK1_DBG   := link -OUT:$(OUTDIR_DBG)/$(TARGET) -INCREMENTAL -NOLOGO -DLL -MANIFEST -MANIFESTFILE:$(OUTDIR_DBG)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -DEBUG -PDB:$(OUTDIR_DBG)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT $(OBJS_DBG) $(shell $(GENDEPS_DBG)) kernel32.lib user32.lib $(LINK_EXTRALIBS_DBG)
		LINK2_DBG   := mt.exe -nologo -manifest $(OUTDIR_DBG)/$(TARGET).intermediate.manifest "-outputresource:$(OUTDIR_DBG)/$(TARGET);\#2"
		LINK3_DBG   := for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		CC_DBG       = cl -Od $(CLINE) -D_DEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/$(LOCALNAME).pdb $<
		CPP_DBG      = $(CC_DBG)
	else ifeq ($(TYPE),exe)
		ifneq (,$(findstring tests,$(LOCALNAME)))
			TESTINCS     := $(shell cat ../$(PLATFORM)/incs.txt 2>/dev/null) -I$(ROOT)/libs/libutpp
			ifneq ($(notdir $(realpath ..)),libutpp)
				PRE_BUILD    := $(ROOT)/libs/libutpp/$(PLATFORM) $(PRE_BUILD)
			endif
			TESTOBJS_REL := $(patsubst %/main.$(OBJ),,$(wildcard ../$(OBJDIR_REL)/*.$(OBJ))) $(ROOT)/libs/libutpp/$(OUTDIR_REL)/libutpp.lib
			TESTEXE_REL  := $(OUTDIR_REL)/$(LOCALNAME)
			TESTOBJS_DBG := $(patsubst %/main.$(OBJ),,$(wildcard ../$(OBJDIR_DBG)/*.$(OBJ))) $(ROOT)/libs/libutpp/$(OUTDIR_DBG)/libutpp.lib
			TESTEXE_DBG  := $(OUTDIR_DBG)/$(LOCALNAME)
		else
			TESTINCS     :=
			TESTOBJS_REL :=
			TESTEXE_REL  :=
			TESTOBJS_DBG :=
			TESTEXE_DBG  :=
		endif
		TARGET      := $(LOCALNAME).exe
		GENLIBS_REL := $(GENDEPS_REL)
		LINK1_REL   := link -OUT:$(OUTDIR_REL)/$(TARGET) -INCREMENTAL:NO -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_REL)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_REL)/$(LOCALNAME).pdb -SUBSYSTEM:CONSOLE -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENDEPS_REL)) kernel32.lib user32.lib $(LINK_EXTRALIBS_REL)
		LINK2_REL   := mt.exe -nologo -manifest $(OUTDIR_REL)/$(TARGET).intermediate.manifest "-outputresource:$(OUTDIR_REL)/$(TARGET);\#1"
		LINK3_REL   := for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		CC_REL       = cl -O2 -Oi $(TESTINCS) $(CLINE) -DNDEBUG -D_CONSOLE -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/$(LOCALNAME).pdb $<
		CPP_REL      = $(CC_REL)
		GENLIBS_DBG := $(GENDEPS_DBG)
		LINK1_DBG   := link -OUT:$(OUTDIR_DBG)/$(TARGET) -INCREMENTAL -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_DBG)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -DEBUG -PDB:$(OUTDIR_DBG)/$(LOCALNAME).pdb -SUBSYSTEM:CONSOLE -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT $(OBJS_DBG) $(TESTOBJS_DBG) $(shell $(GENDEPS_DBG)) kernel32.lib user32.lib $(LINK_EXTRALIBS_DBG)
		LINK2_DBG   := mt.exe -nologo -manifest $(OUTDIR_DBG)/$(TARGET).intermediate.manifest "-outputresource:$(OUTDIR_DBG)/$(TARGET);\#1"
		LINK3_DBG   := for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		CC_DBG       = cl -Od $(TESTINCS) $(CLINE) -D_DEBUG -D_CONSOLE -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/$(LOCALNAME).pdb $<
		CPP_DBG      = $(CC_DBG)
	endif
endif

# Config-agnostic rules:
all: $(PRE_BUILD) $(CONFIGS) $(POST_BUILD)
	@for i in $(SUBDIRS); do make -C $$i; done

$(PLATFORM)/incs.txt: $(PLATFORM)
	$(GENINCS) > $@

clean: FORCE
	@for i in $(SUBDIRS) $(EXTRA_CLEAN_DIRS); do make -C $$i clean; done
	rm -rf $(PLATFORM) $(EXTRA_CLEAN)

FORCE:


deps: $(DEPDIRS:%=%/$(PLATFORM))
	make

depclean: $(DEPDIRS) clean
	@for i in $(DEPDIRS); do make -C $$i clean; done

# All-config rules
$(PLATFORM) $(OBJDIR_REL) $(OUTDIR_REL) $(EXTRA_OBJ_REL) $(OBJDIR_DBG) $(OUTDIR_DBG) $(EXTRA_OBJ_DBG):
	mkdir -p $@


# Release config rules:
rel: $(PLATFORM)/incs.txt $(OUTDIR_REL)/libs.txt $(OBJDIR_REL) $(EXTRA_OBJ_REL) $(OUTDIR_REL)/$(TARGET)
	$(TESTEXE_REL)

$(OUTDIR_REL)/libs.txt: $(OUTDIR_REL)
	($(GENLIBS_REL); $(GENEXTRALIBS_REL)) > $@

$(OUTDIR_REL)/$(TARGET): $(OBJDIR_REL) $(OBJS_REL)
	$(LINK1_REL)
	$(LINK2_REL)
	$(LINK3_REL)

$(OBJDIR_REL)/%.$(OBJ) : %.c
	$(CC_REL)

$(OBJDIR_REL)/%.$(OBJ) : %.cpp
	$(CPP_REL)


# Debug config rules:
dbg: $(PLATFORM)/incs.txt $(OUTDIR_DBG)/libs.txt $(OBJDIR_DBG) $(EXTRA_OBJ_DBG) $(OUTDIR_DBG)/$(TARGET)
	$(TESTEXE_DBG)

$(OUTDIR_DBG)/libs.txt: $(OUTDIR_DBG)
	($(GENLIBS_DBG); $(GENEXTRALIBS_DBG)) > $@

$(OUTDIR_DBG)/$(TARGET): $(OBJDIR_DBG) $(OBJS_DBG)
	$(LINK1_DBG)
	$(LINK2_DBG)
	$(LINK3_DBG)

$(OBJDIR_DBG)/%.$(OBJ) : %.c
	$(CC_DBG)

$(OBJDIR_DBG)/%.$(OBJ) : %.cpp
	$(CPP_DBG)

$(ROOT)/3rd/fx2lib:
	wget -O fx2lib.tgz --no-check-certificate https://github.com/mulicheng/fx2lib/tarball/master
	tar xvzf fx2lib.tgz
	rm fx2lib.tgz
	mv mulicheng-fx2lib-* $(ROOT)/3rd/fx2lib

$(ROOT)/3rd/libusb-win32-bin-%:
	wget -O libusb-win32.zip --no-check-certificate 'http://sourceforge.net/projects/libusb-win32/files/libusb-win32-releases/$(patsubst libusb-win32-bin-%,%,$(@F))/$(@F).zip/download'
	unzip libusb-win32.zip
	rm libusb-win32.zip
	mv $(@F) $(ROOT)/3rd/

$(ROOT)/libs/lib%/Makefile:
	@echo Fetching $(notdir $(@D)) from GitHub...
	wget -O $(notdir $(@D)).tgz --no-check-certificate https://github.com/makestuff/$(notdir $(@D))/tarball/master
	tar xvzf $(notdir $(@D)).tgz
	rm $(notdir $(@D)).tgz
	mv makestuff-$(notdir $(@D))-* $(ROOT)/libs/$(notdir $(@D))

$(ROOT)/libs/lib%/$(PLATFORM): $(ROOT)/libs/lib%/Makefile
	make -C $(dir $<) deps

.PRECIOUS: $(ROOT)/libs/lib%/Makefile
