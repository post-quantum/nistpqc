#
# 'make' to build the native static library and shared library
# 'make test' to build the test suite
# 'make android' to build static library for Android apps
#


default: native

LIBNAME = nistpqc
VERSION = 0.1

# The cipher directories which will each be built separately and later combined
DIRS = newhope512cca kyber512 ntrulpr4591761 ntrukem443 sikep503 ledakem128sln02

# Some cipher-specific options
sikep503_SOURCES = sikep503/P503.c sikep503/generic/fp_generic.c sikep503/sha3/fips202.c scripts/aux_api.c
sikep503_DEFINES = -D _OPTIMIZED_GENERIC_ -D _AMD64_ -D __LINUX__
ledakem128sln02_DEFINES = -DCATEGORY=1 -DN0=2

# If building for Android then we use a special 'standalone' toolchain rather than the system one for
# native builds. The Android NDK will build this toolchain for us
ifeq ($(MAKECMDGOALS),android)
ifndef ANDROID_SDK
$(error Please set ANDROID_SDK to point to your Android SDK)
endif
ifndef OPENSSL
$(error Please set OPENSSL to point to your BoringSSL or OpenSSL source as per https://wiki.strongswan.org/projects/strongswan/wiki/AndroidVPNClientBuild#The-openssl-Directory)
endif
	BUILDDIR:=build/android
	TOOLCHAIN:=$(BUILDDIR)/toolchain
	target_host=aarch64-linux-android
	export AR=$(target_host)-ar
	export AS=$(target_host)-clang
	export CC=$(target_host)-clang
	export CXX=$(target_host)-clang++
	export LD=$(target_host)-ld
	export NM=$(target_host)-nm
	export OBJCOPY=$(target_host)-objcopy
	export RANLIB=$(target_host)-ranlib
	export PATH:=$(PATH):$(TOOLCHAIN)/bin
	export CFLAGS=-fPIE -fPIC -I$(OPENSSL)/include
	export LDFLAGS=-pie

$(TOOLCHAIN):
	$(ANDROID_SDK)/ndk-bundle/build/tools/make_standalone_toolchain.py --arch arm64 --api 26 --install-dir=$(TOOLCHAIN)

else
	BUILDDIR:=build/native
	export NM=nm
	export OBJCOPY=objcopy
	export RANLIB=ranlib
	LIBTOOL=libtool
	UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
	  OPENSSL = /usr/local/opt/openssl
	  OPENSSLLIBDIR = $(OPENSSL)/lib
	  LDFLAGS += -dynamiclib -Wl,-undefined,dynamic_lookup
	  LDFLAGS += -current_version $(VERSION) -compatibility_version $(VERSION)
	  SHAREDLIB = $(BUILDDIR)/lib$(LIBNAME).A.dylib
else ifeq ($(UNAME),Linux)
	  LDFLAGS += -shared
	  SHAREDLIB = $(BUILDDIR)/lib$(LIBNAME).so.$(VERSION)
	  SONAME = lib$(LIBNAME).so.$(shell echo $(VERSION) | cut -f1 -d'.')
else
		$(error Unsupported platform $(UNAME))
endif
endif




CFLAGS += -O3 -Wall -fPIC -fomit-frame-pointer -Icommon -I/usr/local/opt/openssl/include

OBJDIR = $(BUILDDIR)/.obj
STATICLIB = $(BUILDDIR)/lib$(LIBNAME).a

android: $(TOOLCHAIN) $(STATICLIB)


ARCHIVES = $(foreach dir,$(DIRS),$(BUILDDIR)/lib$(dir).a)
OBJECTS = $(patsubst %.c,$(OBJDIR)/%.o,$(wildcard *.c)) $(OBJDIR)/rng.o

native : $(SHAREDLIB) $(STATICLIB)

$(SHAREDLIB) : $(ARCHIVES) $(OBJECTS)
ifeq ($(UNAME),Darwin)
		$(CC) $(LDFLAGS) -o $@ $(filter %.a,$^) $(filter %.o,$^) -L$(OPENSSLLIBDIR) -lcrypto
else ifeq ($(UNAME),Linux)
		$(CC) -shared $(LDFLAGS) -Wl,-soname,$(SONAME) -o $@ -Wl,--whole-archive $(filter %.a,$^) -Wl,--no-whole-archive $(filter %.o,$^) -lcrypto
else
		@echo "Unsupported platform $(UNAME)"
		@exit -1
endif


$(STATICLIB) : $(ARCHIVES) $(OBJECTS)
ifeq ($(UNAME),Darwin)
	$(LIBTOOL) -static -o $@ $(filter %.a,$^) $(filter %.o,$^)
else ifeq ($(UNAME),Linux)
  make-archive = "create $(1)\n $(foreach lib,$(2),addlib $(lib)\n) $(foreach obj,$(3),addmod $(obj)\n) save\n end\n"
	echo $(call make-archive,$@,$(filter %.a,$^),$(filter %.o,$^)) | $(AR) -M
else
		@echo "Unsupported platform $(UNAME)"
		@exit -1
endif

$(OBJDIR)/%.o : %.c | makedir
	$(CC) $(CFLAGS) -c -o $@ $<

$(OBJDIR)/rng.o : common/rng.c | makedir
	$(CC) $(CFLAGS) -c -o $@ $<


# Function that generates the targets for one cipher subdirectory
define build_archive
$(1)_ARCHIVE=$(BUILDDIR)/lib$(1).a
$(1)_OBJDIR=$(OBJDIR)/$(1)
ifndef $(1)_SOURCES
$(1)_SOURCES=$(wildcard $(1)/*.c) scripts/aux_api.c
endif
$(1)_OBJS = $$(patsubst %.c,$$($(1)_OBJDIR)/%.o, $$($(1)_SOURCES))

$$($(1)_ARCHIVE) : $$($(1)_OBJS)
ifeq ($(UNAME),Linux)
		$(AR) cr $$@ $$^
		$(RANLIB) $$@
else ifeq ($(UNAME),Darwin)
		$(LIBTOOL) -static -o $$@ $$^
endif
		bash ./scripts/update_library.sh $(1) $$@

$$($(1)_OBJS) : $$($(1)_OBJDIR)/%.o : %.c
	@mkdir -p $$(dir $$@)
	$$(CC) $$(CFLAGS) $$($(1)_DEFINES) -I$(1) -c -o $$@ $$<


endef

# Generate targets for all the cipher subdirectories
$(foreach cipher,$(DIRS),$(eval $(call build_archive,$(cipher))))



TEST_EXE = $(BUILDDIR)/nistpqc_test
ifeq ($(UNAME),Darwin)
	TEST_LIBS = $(STATICLIB) -L$(OPENSSLLIBDIR) -lcrypto
else
	TEST_LIBS = $(STATICLIB) -lcrypto
endif

test: $(STATICLIB) test/nistpqc_test.c
	$(CC) $(CFLAGS) $(INCLUDE) -I. -c -o $(OBJDIR)/nistpqc_test.o test/nistpqc_test.c
	$(CC) -o $(TEST_EXE) $(OBJDIR)/nistpqc_test.o $(TEST_LIBS)




INSTALL = install

ifeq ($(PREFIX),)
	PREFIX := /usr/local
endif


install: $(STATICLIB) $(SHAREDLIB)
	@echo "Installing static library $(notdir $(STATICLIB))"
	@$(INSTALL) -d $(PREFIX)/lib
	@$(INSTALL) -m 644 $(STATICLIB) $(PREFIX)/lib/
ifeq ($(UNAME),Darwin)
		@ln -sf $(PREFIX)/lib/$(notdir $(SHAREDLIB)) $(PREFIX)/lib/lib$(LIBNAME).dylib
else ifeq ($(UNAME),Linux)
		@ln -sf $(PREFIX)/lib/$(notdir $(SHAREDLIB)) $(PREFIX)/lib/$(SONAME)
		@ln -sf $(PREFIX)/lib/$(notdir $(SHAREDLIB)) $(PREFIX)/lib/lib$(LIBNAME).so
else
		@echo "Unsupported platform $(UNAME)"
		@exit -1
endif
	@echo "Installing shared library $(notdir $(SHAREDLIB))"
	@$(INSTALL) -d $(PREFIX)/lib
	@$(INSTALL) -m 644 $(SHAREDLIB) $(PREFIX)/lib/
	@echo "Installing header files"
	@$(INSTALL) -d $(PREFIX)/include/nistpqc
	@$(INSTALL) -m 644 nistpqc_api.h $(PREFIX)/include/nistpqc/api.h
ifeq ($(UNAME),Linux)
	@ldconfig $(PREFIX)
endif

uninstall:
	@echo "Uninstalling libraries and header files"
	@rm -f $(PREFIX)/include/nistpqc_api.h
	@rm -f $(PREFIX)/lib/$(notdir $(STATICLIB))
	@rm -f $(PREFIX)/lib/$(notdir $(SHAREDLIB))
ifeq ($(UNAME),Darwin)
	@rm -f $(PREFIX)/lib/lib$(LIBNAME).dylib
else ifeq ($(UNAME),Linux)
	@rm -f $(PREFIX)/lib/$(SONAME)
	@rm -f $(PREFIX)/lib/lib$(LIBNAME).so
endif

makedir :
	@mkdir -p $(OBJDIR)

clean :
	@rm -rf build



.PHONY : subdirs $(DIRS)
.PHONY : subdirs $(TESTDIRS)
.PHONY : all test install uninstall clean
