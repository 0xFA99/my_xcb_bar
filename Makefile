SOURCES = $(wildcard *.asm)
OBJECTS = $(SOURCES:.asm=.o)

BIN = mochiwm

LDFLAGS = -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lxcb -lc -g

all: $(BIN)

$(BIN): $(OBJECTS)
	ld -o $@ $(OBJECTS) $(LDFLAGS)

%.o: %.asm
	fasm $< $@

clean:
	rm -rf *.o $(BIN)

run:
	./$(BIN)

debug:
	gdb ./$(BIN)

.PHONY: all clean all debug

