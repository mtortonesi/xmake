# architecture makefile configure

# prefix & suffix
BIN_PREFIX			=
BIN_SUFFIX			= .b

OBJ_PREFIX			=
OBJ_SUFFIX			= .o

LIB_PREFIX			= lib
LIB_SUFFIX			= .a

DLL_PREFIX			=
DLL_SUFFIX			= .dylib

ASM_SUFFIX			= .S

# cpu bits
BITS				:= $(if $(findstring x86_64,$(BUILD_ARCH)),64,$(BITS))
BITS				:= $(if $(findstring arm64,$(BUILD_ARCH)),64,$(BITS))
BITS				:= $(if $(findstring i386,$(BUILD_ARCH)),32,$(BITS))
BITS				:= $(if $(BITS),$(BITS),$(shell getconf LONG_BIT))

# prefix
PRE_				:= $(if $(BIN),$(BIN)/$(PRE),xcrun -sdk macosx )

# cc
CC					= $(PRE_)clang
ifeq ($(CXFLAGS_CHECK),)
CC_CHECK			= ${shell if $(CC) $(1) -S -o /dev/null -xc /dev/null > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi }
ifeq ($(BUILD_ARCH),arm64)
#CXFLAGS_CHECK		:= $(call CC_CHECK,-mfpu=neon,)
endif
ifeq ($(BUILD_ARCH),x86_64)
# it will crash on ci
#CXFLAGS_CHECK		:= $(call CC_CHECK,-msse -msse2 -msse3 -mavx -mavx2,)
endif
export CXFLAGS_CHECK
endif

# ld
LD					= $(PRE_)clang
ifeq ($(LDFLAGS_CHECK),)
LD_CHECK			= ${shell if $(LD) $(1) -S -o /dev/null -xc /dev/null > /dev/null 2>&1; then echo "$(1)"; else echo "$(2)"; fi }
LDFLAGS_CHECK		:=
export LDFLAGS_CHECK
endif

# tool
MM					= $(PRE_)clang
AR					= $(PRE_)ar
STRIP				= $(PRE_)strip
RANLIB				= $(PRE_)ranlib
AS					= $(PRE_)clang
RM					= rm -f
RMDIR				= rm -rf
CP					= cp
CPDIR				= cp -r
MKDIR				= mkdir -p
MAKE				= make -r

# cxflags: .c/.cc/.cpp files, @note luajit cannot use -Oz, because it will panic
CXFLAGS_RELEASE		= -Os -fvisibility=hidden -fvisibility-inlines-hidden -flto
CXFLAGS_DEBUG		= -g -D__tb_debug__
CXFLAGS				= -m$(BITS) -c -Wall -Werror -Wno-error=deprecated-declarations -Qunused-arguments $(CXFLAGS_CHECK)
CXFLAGS-I			= -I
CXFLAGS-o			= -o

# prof
ifeq ($(PROF),y)
CXFLAGS				+= -g -fno-omit-frame-pointer
else
CXFLAGS_RELEASE		+= -fomit-frame-pointer
CXFLAGS_DEBUG		+= -fno-omit-frame-pointer
endif

# cflags: .c files
CFLAGS_RELEASE		=
CFLAGS_DEBUG		=
CFLAGS				= \
					-std=c99 \
					-D_GNU_SOURCE=1 -D_REENTRANT \
					-fno-math-errno -fno-tree-vectorize

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE		=
CCFLAGS_DEBUG		=
CCFLAGS				= \
					-D_ISOC99_SOURCE -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE \
					-D_POSIX_C_SOURCE=200112 -D_XOPEN_SOURCE=600

# mxflags: .m/.mm files
MXFLAGS_RELEASE		= -Os -fvisibility=hidden -fvisibility-inlines-hidden -flto
MXFLAGS_DEBUG		= -g -D__tb_debug__
MXFLAGS				= \
					-m$(BITS) -c -Wall -Werror -Wno-error=deprecated-declarations -Qunused-arguments \
					-mssse3 $(ARCH_CXFLAGS) -fmessage-length=0 -pipe -fpascal-strings \
					"-DIBOutlet=__attribute__((iboutlet))" \
					"-DIBOutletCollection(ClassName)=__attribute__((iboutletcollection(ClassName)))" \
					"-DIBAction=void)__attribute__((ibaction)"
MXFLAGS-I			= -I
MXFLAGS-o			= -o

# opti
ifeq ($(SMALL),y)
MXFLAGS_RELEASE		+= -Os
else
MXFLAGS_RELEASE		+= -O3
endif

# prof
ifeq ($(PROF),y)
MXFLAGS				+= -g -fno-omit-frame-pointer
else
MXFLAGS_RELEASE		+= -fomit-frame-pointer
MXFLAGS_DEBUG		+= -fno-omit-frame-pointer
endif

# mflags: .m files
MFLAGS_RELEASE		=
MFLAGS_DEBUG		=
MFLAGS				= -std=c99

# mmflags: .mm files
MMFLAGS_RELEASE		=
MMFLAGS_DEBUG		=
MMFLAGS				=

# ldflags
LDFLAGS_ARCH		:= $(if $(findstring arm64,$(BUILD_ARCH)),,-pagezero_size 10000 -image_base 100000000)
LDFLAGS_RELEASE		= -flto
LDFLAGS_DEBUG		=
LDFLAGS				= -m$(BITS) -all_load $(LDFLAGS_ARCH) -mmacosx-version-min=10.7 -framework CoreFoundation -framework CoreServices
LDFLAGS-L			= -L
LDFLAGS-l			= -l
LDFLAGS-f			=
LDFLAGS-o			= -o

# prof
ifeq ($(PROF),y)
else
LDFLAGS_RELEASE		+= -s
LDFLAGS_DEBUG		+= -ftrapv
endif

# asflags
ASFLAGS_RELEASE		=
ASFLAGS_DEBUG		=
ASFLAGS				= -m$(BITS) -c -Wall
ASFLAGS-I			= -I
ASFLAGS-o			= -o

# arflags
ARFLAGS_RELEASE		=
ARFLAGS_DEBUG		=
ARFLAGS				= -cr
ARFLAGS-o			=

# shflags
SHFLAGS_RELEASE		= -s
SHFLAGS				= $(ARCH_LDFLAGS) -dynamiclib -mmacosx-version-min=10.7

# include directory
INC_DIR				+= /usr/include /usr/local/include

# library directory
LIB_DIR				+= /usr/lib /usr/local/lib

# config
include				$(PLAT_DIR)/config.mak


