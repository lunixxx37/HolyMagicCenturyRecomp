TARGET = patches.elf

CC      ?= clang
LD      ?= ld.lld
# Headers: libultra 2.0H and game headers from the Quest 64 decomp, extended GBI from rt64.
DECOMP_DIR ?= ../lib/quest64-decomp
RT64_DIR   ?= ../lib/rt64

CFLAGS   := -target mips -mips2 -mabi=32 -O2 -G0 -mno-abicalls -mno-odd-spreg -mno-check-zero-division \
			-fomit-frame-pointer -ffast-math -fno-unsafe-math-optimizations -fno-builtin-memset \
			-Wall -Wextra -Wno-incompatible-library-redeclaration -Wno-unused-parameter -Wno-unknown-pragmas -Wno-unused-variable -Wno-unused-but-set-variable -Wno-missing-braces -Wno-unsupported-floating-point-opt -Wno-switch
# Same include order and defines as the decomp's own build (configure.py).
CPPFLAGS := -nostdinc -D_LANGUAGE_C -DF3DEX_GBI -DNDEBUG -DMIPS \
			-I $(DECOMP_DIR)/include -I $(DECOMP_DIR)/include/2.0H -I $(DECOMP_DIR)/include/2.0H/PR -I $(DECOMP_DIR)/src \
			-I $(RT64_DIR)/include
LDFLAGS  := -nostdlib -T patches.ld -T syms.ld -Map patches.map --unresolved-symbols=ignore-all --emit-relocs

C_SRCS := $(wildcard *.c)
C_OBJS := $(C_SRCS:.c=.o)
C_DEPS := $(C_SRCS:.c=.d)

$(TARGET): $(C_OBJS) patches.ld syms.ld
	$(LD) $(C_OBJS) $(LDFLAGS) -o $@

$(C_OBJS): %.o : %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $< -MMD -MF $(@:.o=.d) -c -o $@

clean:
	rm -rf $(C_OBJS) $(TARGET) $(C_DEPS)

-include $(C_DEPS)

.PHONY: clean
