# Brainfuck implementation in x86_64 assembly

This is a very brittle implementation of the [Brainfuck language](http://www.muppetlabs.com/~breadbox/bf/). Brainfuck is an esolang which is solely a symbolic renaming of a Turing machine (with the addition of conditional expressions).

The interpreter is designed to use a dynamic dispatch table to improve performance compared to a switch ladder. The syscalls are somewhat unreliable as to what they clobber but I abused any preservation of registers to reduce the number of instructions.

Further development would involve:
- Expanding dispatch table
- Using a table based lookup for branches
- Reorganisation of code to improve performance with respect to alignment

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
