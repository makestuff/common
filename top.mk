unexport SUBDIRS
unexport TYPE
unexport CC_SRCS
unexport CPP_SRCS
unexport DEPS
RUNTESTS_REL =
RUNTESTS_DBG =
DEPCLEAN = $(DEPS:%=$(ROOT)/libs/lib%/.depclean)
INCLUDES = -I$(ROOT)/common $(DEPS:%=-I$(ROOT)/libs/lib%)
LOCALNAME = $(notdir $(realpath .))
DEPDIRS = $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM))
OUTDIR_REL = $(PLATFORM)/rel
OUTDIR_DBG = $(PLATFORM)/dbg
OBJDIR_REL = $(OUTDIR_REL)/.build
OBJDIR_DBG = $(OUTDIR_DBG)/.build
ifeq ($(CC_SRCS),)
	CC_SRCS = $(shell ls *.c 2>/dev/null)
endif
ifeq ($(CPP_SRCS),)
	CPP_SRCS = $(shell ls *.cpp 2>/dev/null)
endif
OBJS_REL = $(CC_SRCS:%.c=$(OBJDIR_REL)/%.$(OBJ)) $(CPP_SRCS:%.cpp=$(OBJDIR_REL)/%.$(OBJ))
OBJS_DBG = $(CC_SRCS:%.c=$(OBJDIR_DBG)/%.$(OBJ)) $(CPP_SRCS:%.cpp=$(OBJDIR_DBG)/%.$(OBJ))
CONFIGS = dbg rel

ifeq ($(OS), Windows_NT)
	PLATFORM = win32
	OBJ = obj
	ifeq ($(CFLAGS),)
		CFLAGS = -DWIN32 -D_CRT_SECURE_NO_WARNINGS -EHsc -W4 -nologo -c -TP -errorReport:prompt $(INCLUDES)
	endif
	DLLS_REL = $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.dll))
	DLLS_DBG = $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/*.dll))
	ifeq ($(TYPE), dll)
		LOCALNAMEUPPER = $(shell echo $(LOCALNAME) | tr [a-z] [A-Z])
		TARGET = $(LOCALNAME).dll
		CC_REL = cl -O2 -Oi $(CFLAGS) -DNDEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -GL -FD -MD -Gy -Zi -Fo$@ -Fd$(OUTDIR_REL)/ $< >/dev/null
		CC_DBG = cl -Od $(CFLAGS) -D_DEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/ $< >/dev/null
		CPP_REL = $(CC_REL)
		CPP_DBG = $(CC_DBG)
		LINK_REL = link -OUT:$@ -INCREMENTAL:NO -NOLOGO -DLL -DEBUG -MANIFEST -MANIFESTFILE:$@.intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_REL)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/lib$(DEP).lib) $(OBJS_REL); mt.exe -manifest $@.intermediate.manifest "-outputresource:$@;\#2"; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK_DBG = link -OUT:$@ -INCREMENTAL -NOLOGO -DLL -MANIFEST -MANIFESTFILE:$@.intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_DBG)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/lib$(DEP).lib) $(OBJS_DBG); mt.exe -manifest $@.intermediate.manifest "-outputresource:$@;\#2"; for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
	else ifeq ($(TYPE), lib)
		TARGET = $(LOCALNAME).lib
		CC_REL = cl -O2 -Oi $(CFLAGS) -DNDEBUG -D_LIB -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/$(LOCALNAME).pdb $< >/dev/null
		CC_DBG = cl -Od $(CFLAGS) -D_DEBUG -D_LIB -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/$(LOCALNAME).pdb $< >/dev/null
		CPP_REL = $(CC_REL)
		CPP_DBG = $(CC_DBG)
		LINK_REL = lib -nologo -out:$@ -ltcg $(OBJS_REL)
		LINK_DBG = lib -nologo -out:$@ $(OBJS_DBG)
	else ifeq ($(TYPE), exe)
		TARGET = $(LOCALNAME).exe
		ifeq ($(LOCALNAME),tests)
			RUNTESTS_REL = $(OUTDIR_REL)/$(TARGET)
			RUNTESTS_DBG = $(OUTDIR_DBG)/$(TARGET)
		endif
		CC_REL = cl -O2 -Oi $(CFLAGS) -DNDEBUG -D_CONSOLE -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/ $< >/dev/null
		CC_DBG = cl -Od $(CFLAGS) -D_DEBUG -D_CONSOLE -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/ $< >/dev/null
		CPP_REL = $(CC_REL)
		CPP_DBG = $(CC_DBG)
		LINK_REL = link -OUT:$@ -INCREMENTAL:NO -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_REL)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -DEBUG -PDB:$(OUTDIR_REL)/$(TARGET).pdb -SUBSYSTEM:CONSOLE -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/lib$(DEP).lib) $(OBJS_REL); mt.exe -manifest $@.intermediate.manifest "-outputresource:$@;\#1"; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK_DBG = link -OUT:$@ -INCREMENTAL -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_DBG)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -DEBUG -PDB:$(OUTDIR_DBG)/$(TARGET).pdb -SUBSYSTEM:CONSOLE -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/lib$(DEP).lib) $(OBJS_DBG); mt.exe -manifest $@.intermediate.manifest "-outputresource:$@;\#1"; for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
	endif
else
	PLATFORM = $(shell uname | tr [A-Z] [a-z])
	ifeq ($(PLATFORM), linux)
		OBJ = o
		ifeq ($(CFLAGS),)
			CFLAGS = -c -Wall -Wextra -Wstrict-prototypes -Wundef -std=c99 -pedantic-errors -Wno-missing-field-initializers $(INCLUDES)
		endif
		ifeq ($(CPPFLAGS),)
			CPPFLAGS = -c -Wall -Wextra -Wundef -std=c++98 -pedantic-errors $(INCLUDES)
		endif
		DLLS_REL = $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.so))
		DLLS_DBG = $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/*.so))
		ifeq ($(TYPE), dll)
			TARGET = $(LOCALNAME).so
			CC_REL = gcc -fPIC -O3 $(CFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CC_DBG = gcc -fPIC -g $(CFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			CPP_REL = g++ -fPIC -O3 $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CPP_DBG = g++ -fPIC -g $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			LINK_REL = gcc -shared -Wl,-soname,$(TARGET) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(foreach DEP,$(DEPS),-L$(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL) -l$(DEP)); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
			LINK_DBG = gcc -shared -Wl,-soname,$(TARGET) -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG) $(foreach DEP,$(DEPS),-L$(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG) -l$(DEP)); for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		else ifeq ($(TYPE), lib)
			TARGET = $(LOCALNAME).a
			CC_REL = gcc -fPIC -O3 $(CFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CC_DBG = gcc -fPIC -g $(CFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			CPP_REL = g++ -fPIC -O3 $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CPP_DBG = g++ -fPIC -g $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			LINK_REL = ar cr $@ $(OBJS_REL)
			LINK_DBG = ar cr $@ $(OBJS_DBG)
		else ifeq ($(TYPE), exe)
			TARGET = $(LOCALNAME)
			ifeq ($(LOCALNAME),tests)
				RUNTESTS_REL = $(OUTDIR_REL)/$(TARGET)
				RUNTESTS_DBG = $(OUTDIR_DBG)/$(TARGET)
			endif
			CC_REL = gcc -O3 $(CFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CC_DBG = gcc -g $(CFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			CPP_REL = g++ -O3 $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CPP_DBG = g++ -g $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			LINK_REL = g++ -Wl,--relax -Wl,--gc-sections -Wl,-Map=$(OBJDIR_REL)/$(TARGET).map,--cref -o $@ $(OBJS_REL) $(foreach DEP,$(DEPS),-L$(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL) -l$(DEP)); strip $@; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
			LINK_DBG = g++ -Wl,--relax -Wl,--gc-sections -Wl,-Map=$(OBJDIR_DBG)/$(TARGET).map,--cref -o $@ $(OBJS_DBG) $(foreach DEP,$(DEPS),-L$(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG) -l$(DEP)); for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		endif
	else
		TARGET = $(PLATFORM)
	endif
endif

all: $(CONFIGS)
	@for i in $(SUBDIRS); do make -C $$i; done

dlls:
	@echo DLLS = $(DLLS)
	@echo DEPS = $(DEPS)

dbg: $(DEPDIRS) $(OBJDIR_DBG) $(OUTDIR_DBG)/$(TARGET)
	$(RUNTESTS_DBG)

rel: $(DEPDIRS) $(OBJDIR_REL) $(OUTDIR_REL)/$(TARGET)
	$(RUNTESTS_REL)

$(DEPDIRS):
	make -C $(dir $@)

$(SUBDIRS):
	make -C $@

$(DEPCLEAN):
	make -C $(dir $@) depclean

$(OBJDIR_REL) $(OBJDIR_DBG):
	mkdir -p $@

$(OUTDIR_REL)/$(TARGET): $(OBJDIR_REL) $(OBJS_REL)
	$(LINK_REL)

$(OUTDIR_DBG)/$(TARGET): $(OBJDIR_DBG) $(OBJS_DBG)
	$(LINK_DBG)

$(OBJDIR_REL)/%.$(OBJ) : %.c
	@mkdir -p $(dir $@)
	$(CC_REL)

$(OBJDIR_DBG)/%.$(OBJ) : %.c
	@mkdir -p $(dir $@)
	$(CC_DBG)

$(OBJDIR_REL)/%.$(OBJ) : %.cpp
	@mkdir -p $(dir $@)
	$(CPP_REL)

$(OBJDIR_DBG)/%.$(OBJ) : %.cpp
	@mkdir -p $(dir $@)
	$(CPP_DBG)

clean: FORCE
	rm -rf $(PLATFORM)
	@for i in $(SUBDIRS); do make -C $$i clean; done

depclean: clean $(DEPCLEAN)

FORCE:

#-include $(ROOT)/common/$(PLATFORM).mk
