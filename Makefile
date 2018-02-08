CC = gcc
AR = ar
INSTALL = install
CFLAGS = -O3 -Wall -fPIC -fomit-frame-pointer
ARFLAGS = cr
LDFLAGS = -shared

ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif

LIBNAME = nistpqc
SHAREDLIBRARY = lib$(LIBNAME).so
STATICLIBRARY = lib$(LIBNAME).a

DIRS = newhope512cca kyber512 ntrulpr4591761 ntrukem443 sikep503

OBJDIR = .obj

BUILDDIRS = $(DIRS:%=build-%)
TESTDIRS  = $(DIRS:%=test-%)
CLEANDIRS = $(DIRS:%=clean-%)

all : $(BUILDDIRS) $(SHAREDLIBRARY) $(STATICLIBRARY)

$(DIRS) : $(BUILDDIRS)

$(BUILDDIRS) :
	$(MAKE) -C $(@:build-%=%)

$(SHAREDLIBRARY) : $(BUILDDIRS) $(foreach dir,$(DIRS),$(dir)/lib$(dir).a) $(patsubst %.c,$(OBJDIR)/%.o,$(wildcard *.c))
	$(CC) $(LDFLAGS) -Wl,-soname,$@ -o $@ -Wl,--whole-archive $(filter %.a,$^) -Wl,--no-whole-archive $(filter %.o,$^)

make-archive = "create $(1)\n $(foreach lib,$(2),addlib $(lib)\n) $(foreach obj,$(3),addmod $(obj)\n) save\n end\n"

$(STATICLIBRARY) : $(BUILDDIRS) $(foreach dir,$(DIRS),$(dir)/lib$(dir).a) $(patsubst %.c,$(OBJDIR)/%.o,$(wildcard *.c))
	echo $(call make-archive,$@,$(filter %.a,$^),$(filter %.o,$^)) | $(AR) -M

$(OBJDIR)/%.o : %.c mkdir
	$(CC) $(CFLAGS) -c -o $@ $<

install: $(STATICLIBRARY) $(SHAREDLIBRARY) 
	@echo "Installing static library $(STATICLIBRARY)"
	@$(INSTALL) -d $(PREFIX)/lib
	@$(INSTALL) -m 644 $(STATICLIBRARY) $(PREFIX)/lib/
	@echo "Installing shared library $(SHAREDLIBRARY)"	
	@$(INSTALL) -d $(PREFIX)/lib
	@$(INSTALL) -m 644 $(SHAREDLIBRARY) $(PREFIX)/lib/
	@echo "Installing header files"
	@$(INSTALL) -d $(PREFIX)/include
	@$(INSTALL) -m 644 nistpqc_api.h $(PREFIX)/include/
	@ldconfig $(PREFIX)

uninstall:
	@echo "Uninstalling libraries and header files"
	@rm -f $(PREFIX)/include/nistpqc_api.h
	@rm -f $(PREFIX)/lib/$(STATICLIBRARY)
	@rm -f $(PREFIX)/lib/$(SHAREDLIBRARY)

test : $(TESTDIRS) all
	$(MAKE) -C $(@:test-%=%) test

mkdir :
	@mkdir -p $(OBJDIR)

clean : $(CLEANDIRS) clean-library clean-dir 

$(CLEANDIRS) :
	$(MAKE) -C $(@:clean-%=%) clean
	$(MAKE) -C test clean

$(TESTCLEANDIRS) : $(TESTDIRS)
	$(MAKE) -C $(@:test-%=%) clean

clean-library :
	@rm -f $(SHAREDLIBRARY) $(STATICLIBRARY)

clean-dir :
	@rm -rf $(OBJDIR)

.PHONY : subdirs $(DIRS)
.PHONY : subdirs $(BUILDDIRS)
.PHONY : subdirs $(TESTDIRS)
.PHONY : subdirs $(CLEANDIRS)
.PHONY : all test install uninstall clean

