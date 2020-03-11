# Brainfuck implementation in x86_64 assembly

This is an implementation of the [Brainfuck language](https://github.com/brain-lang/brainfuck/blob/master/brainfuck.md). Brainfuck is an esolang which is closely resembles a Turing machine (with the addition of bulit-in conditional expressions).

The syscalls are somewhat unreliable as to what they clobber but I abused any preservation of registers to reduce the number of instructions.

Further development would involve:
- Code alignment improvement
- Ordering of operations to reduce port load
- Reorganisation of branches to improve branch predictor

Installation and build instructions:
```
$ git clone https://github.com/birb007/bfasm.git
$ cd bfasm
$ make
```

A `bfasm` executable should then be present in the main repository directory. To use the interpreter, specify a sourcefile in the command line arguments.
```
usage: ./bfasm <filename>
```

All testing code was found online and is not my own work. A demonstration of the interpreter using [Daniel B. Cristofani's](http://www.hevanet.com/cristofd/brainfuck/) Fibonacci implementation.

![example usage](https://raw.githubusercontent.com/birb007/bfasm/master/demo/demo.png)

## Performance

`bfasm` executed 10,521,107,970 Brainfuck operations in 69.1 seconds (152,243,737.5/s).

`sudo perf stat -a -B -o perf_report --table -r 10 ./bfasm tests/mandelbrot.bf`

Note: the elapsed time includes process initialisation and destruction.
