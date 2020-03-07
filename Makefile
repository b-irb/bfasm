LD = ld
NASM = nasm

# assembler flags
NASMFLAGS = -felf64

# linker flags
LDFLAGS = 

# object files
OBJ := src/bfasm.o

.PHONY: all
all: bfasm

bfasm: $(OBJ)
	$(LD) $(LDFLAGS) $(OBJ) -o $@

%.o: %.s
	$(NASM) $(NASMFLAGS) $^ -o $@

.PHONY: clean
clean:
	find -name "*.o" -delete
	rm -f bfasm
