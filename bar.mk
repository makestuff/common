unexport SUBDIRS
unexport TYPE
unexport CC_SRCS
unexport CPP_SRCS
unexport DEPS
LOCALNAME = $(notdir $(realpath .))
RUNTESTS_REL =
RUNTESTS_DBG =
DEPCLEAN = $(DEPS:%=$(ROOT)/libs/lib%/.depclean)
DEPDIRS = $(DEPS:%=$(ROOT)/libs/lib%/$(PLATFORM))
DEPGETS = $(DEPS:%=$(ROOT)/libs/lib%)
OUTDIR_REL = $(PLATFORM)/rel
OUTDIR_DBG = $(PLATFORM)/dbg
OBJDIR_REL = $(OUTDIR_REL)/.build
OBJDIR_DBG = $(OUTDIR_DBG)/.build
ifeq ($(LOCALNAME),tests)
	INCLUDES = $(EXTRA_INCS) -I.. -I$(ROOT)/common -I$(ROOT)/libs/libutpp $(DEPS:%=-I$(ROOT)/libs/lib%)
	TESTOBJS_REL = $(wildcard ../$(OBJDIR_REL)/*.$(OBJ))
	TESTOBJS_DBG = $(wildcard ../$(OBJDIR_DBG)/*.$(OBJ))
	DEPS += utpp
else
	INCLUDES = $(EXTRA_INCS) -I$(ROOT)/common $(DEPS:%=-I$(ROOT)/libs/lib%)
	TESTOBJS_REL =
	TESTOBJS_DBG =
endif
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
		CFLAGS = -DWIN32 -D_CRT_SECURE_NO_WARNINGS -EHsc -W4 -nologo -c -errorReport:prompt $(INCLUDES)
	endif
	DLLS_REL = $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.dll))
	DLLS_DBG = $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/*.dll))
	ifeq ($(TYPE), dll)
		LOCALNAMEUPPER = $(shell echo $(LOCALNAME) | tr [a-z] [A-Z])
		TARGET = $(LOCALNAME).dll
		CC_REL = cl -O2 -Oi $(CFLAGS) -DNDEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -GL -FD -MD -Gy -Zi -Fo$@ -Fd$(OUTDIR_REL)/ $<
		CC_DBG = cl -Od $(CFLAGS) -D_DEBUG -D_WINDOWS -D_USRDLL -D$(LOCALNAMEUPPER)_EXPORTS -D_WINDLL -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/ $<
		CPP_REL = $(CC_REL)
		CPP_DBG = $(CC_DBG)
		LINK_REL = link -OUT:$@ -INCREMENTAL:NO -NOLOGO -DLL -DEBUG -MANIFEST -MANIFESTFILE:$@.intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_REL)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.lib)) $(OBJS_REL); mt.exe -nologo -manifest $@.intermediate.manifest "-outputresource:$@;\#2"; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK_DBG = link -OUT:$@ -INCREMENTAL -NOLOGO -DLL -MANIFEST -MANIFESTFILE:$@.intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -PDB:$(OUTDIR_DBG)/$(LOCALNAME).pdb -SUBSYSTEM:WINDOWS -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/*.lib)) $(OBJS_DBG); mt.exe -nologo -manifest $@.intermediate.manifest "-outputresource:$@;\#2"; for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
	else ifeq ($(TYPE), lib)
		TARGET = $(LOCALNAME).lib
		CC_REL = cl -O2 -Oi $(CFLAGS) -DNDEBUG -D_LIB -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/$(LOCALNAME).pdb $<
		CC_DBG = cl -Od $(CFLAGS) -D_DEBUG -D_LIB -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/$(LOCALNAME).pdb $<
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
		CC_REL = cl -O2 -Oi $(CFLAGS) -DNDEBUG -D_CONSOLE -FD -MD -Gy -GL -Zi -Fo$@ -Fd$(OUTDIR_REL)/ $<
		CC_DBG = cl -Od $(CFLAGS) -D_DEBUG -D_CONSOLE -Gm -RTC1 -MDd -ZI -Fo$@ -Fd$(OUTDIR_DBG)/ $<
		CPP_REL = $(CC_REL)
		CPP_DBG = $(CC_DBG)
		LINK_REL = link -OUT:$@ -INCREMENTAL:NO -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_REL)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -DEBUG -PDB:$(OUTDIR_REL)/$(TARGET).pdb -SUBSYSTEM:CONSOLE -OPT:REF -OPT:ICF -LTCG -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL)/*.lib)) $(OBJS_REL) $(TESTOBJS_REL); mt.exe -nologo -manifest $@.intermediate.manifest "-outputresource:$@;\#1"; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
		LINK_DBG = link -OUT:$@ -INCREMENTAL -NOLOGO -MANIFEST -MANIFESTFILE:$(OUTDIR_DBG)/$(TARGET).intermediate.manifest -MANIFESTUAC:"level='asInvoker' uiAccess='false'" -DEBUG -PDB:$(OUTDIR_DBG)/$(TARGET).pdb -SUBSYSTEM:CONSOLE -DYNAMICBASE -NXCOMPAT -MACHINE:X86 -ERRORREPORT:PROMPT kernel32.lib user32.lib $(foreach DEP,$(DEPS),$(wildcard $(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG)/*.lib)) $(OBJS_DBG) $(TESTOBJS_DBG); mt.exe -nologo -manifest $@.intermediate.manifest "-outputresource:$@;\#1"; for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
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
		GENLIBDEPS = for i in $(DEPS:%=$(realpath $(ROOT))/libs/lib%/$(dir $@)/libs.txt); do cat $$i; done
		ifeq ($(TYPE), dll)
			TARGET = $(LOCALNAME).so
			LIBDEPS_DBG = $(PLATFORM)/dbg/libs.txt
			LIBDEPS_REL = $(PLATFORM)/rel/libs.txt
			CC_REL = gcc -fPIC -O3 $(CFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CC_DBG = gcc -fPIC -g $(CFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			CPP_REL = g++ -fPIC -O3 $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CPP_DBG = g++ -fPIC -g $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			LINK_REL = gcc -shared -Wl,-soname,$(TARGET) -o $(OUTDIR_REL)/$(TARGET) $(OBJS_REL) $(foreach DEP,$(DEPS),-L$(ROOT)/libs/lib$(DEP)/$(OUTDIR_REL) -l$(DEP)); for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
			LINK_DBG = gcc -shared -Wl,-soname,$(TARGET) -o $(OUTDIR_DBG)/$(TARGET) $(OBJS_DBG) $(foreach DEP,$(DEPS),-L$(ROOT)/libs/lib$(DEP)/$(OUTDIR_DBG) -l$(DEP)); for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		else ifeq ($(TYPE), lib)
			TARGET = $(LOCALNAME).a
			LIBDEPS_DBG = $(PLATFORM)/dbg/libs.txt
			LIBDEPS_REL = $(PLATFORM)/rel/libs.txt
			GENLIBSALL = (echo -L$(realpath .)/$(dir $@) -l$(LOCALNAME:lib%=%); $(GENLIBDEPS))
			CC_REL = gcc -fPIC -O3 $(CFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CC_DBG = gcc -fPIC -g $(CFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			CPP_REL = g++ -fPIC -O3 $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CPP_DBG = g++ -fPIC -g $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			LINK_REL = ar cr $@ $(OBJS_REL)
			LINK_DBG = ar cr $@ $(OBJS_DBG)
		else ifeq ($(TYPE), exe)
			TARGET = $(LOCALNAME)
			LIBDEPS_DBG =
			LIBDEPS_REL =
			ifeq ($(LOCALNAME),tests)
				RUNTESTS_REL = cd $(OUTDIR_REL); LD_LIBRARY_PATH=. ./$(TARGET)
				RUNTESTS_DBG = cd $(OUTDIR_DBG); LD_LIBRARY_PATH=. ./$(TARGET)
			endif
			CC_REL = gcc -O3 $(CFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CC_DBG = gcc -g $(CFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			CPP_REL = g++ -O3 $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_REL)/$(@F).d -Wa,-adhlns=$(OBJDIR_REL)/$<.lst $< -o $@
			CPP_DBG = g++ -g $(CPPFLAGS) -MMD -MP -MF $(OBJDIR_DBG)/$(@F).d -Wa,-adhlns=$(OBJDIR_DBG)/$<.lst $< -o $@
			LINK_REL = g++ -Wl,--relax -Wl,--gc-sections -Wl,-Map=$(OBJDIR_REL)/$(TARGET).map,--cref -o $@ $(OBJS_REL) $(TESTOBJS_REL) $(shell $(GENLIBDEPS)); strip $@; for i in $(DLLS_REL); do cp -rp $$i $(OUTDIR_REL); done
			LINK_DBG = g++ -Wl,--relax -Wl,--gc-sections -Wl,-Map=$(OBJDIR_DBG)/$(TARGET).map,--cref -o $@ $(OBJS_DBG) $(TESTOBJS_DBG) $(shell $(GENLIBDEPS)); for i in $(DLLS_DBG); do cp -rp $$i $(OUTDIR_DBG); done
		endif
	else
		TARGET = $(PLATFORM)
	endif
endif

all: $(EXTRAS) $(PLATFORM)/incs.txt $(CONFIGS)
	@for i in $(SUBDIRS); do make -C $$i; done


$(PLATFORM):
	mkdir -p $@

$(PLATFORM)/incs.txt: $(PLATFORM)
	echo -I$(realpath .) > $@

$(PLATFORM)/rel/libs.txt $(PLATFORM)/dbg/libs.txt:
	$(GENLIBSALL) > $@

foo:
	@echo $(GENLIBDEPS)
	#@echo $(shell (echo -L/home/chris/src/libs/liba1/linux/rel -lliba1; cat $(DEPS:%=$(realpath $(ROOT))/libs/lib%/$(PLATFORM)/rel/libs.txt)) | sort | uniq)


dbg: $(DEPGETS) $(DEPDIRS) $(OBJDIR_DBG) $(LIBDEPS_DBG) $(OUTDIR_DBG)/$(TARGET)
	$(RUNTESTS_DBG)

rel: $(DEPGETS) $(DEPDIRS) $(OBJDIR_REL) $(LIBDEPS_REL) $(OUTDIR_REL)/$(TARGET)
	$(RUNTESTS_REL)

$(DEPDIRS):
	make -C $(dir $@)

$(SUBDIRS):
	make -C $@

$(DEPCLEAN): $(dir $@)
	make -C $(dir $@) depclean

$(OBJDIR_REL) $(OBJDIR_DBG) $(OUTDIR_REL) $(OUTDIR_DBG):
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

$(ROOT)/libs/%:
	cd $(ROOT)/libs; wget --no-check-certificate -O $(notdir $@).tar.gz https://github.com/makestuff/$(notdir $@)/tarball/master; tar zxf $(notdir $@).tar.gz; mv makestuff-$(notdir $@)-* $(notdir $@)
