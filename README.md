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

`bfasm` executed 1 billion Brainfuck operations in 5.06 seconds. Benchmarking included modifying `bfasm` (example benchmark stub shown below) to limit each process to 1 billion operations, and removing the syscall to `sys_write` as IO operations are not deterministic/challenging to benchmark meaningfully.

```diff
--- a/src/bfasm.s
+++ b/src/bfasm.s
@@ -331,6 +331,7 @@ _start:
     ; r13   - cell pointer
     ; rsp   - call stack

+    xor r15, r15
     .loop:
         cmp r14, r12
         je short dispatch_return.loop_end
@@ -341,6 +342,9 @@ _start:
         jmp [rax] ; dispatch table
 dispatch_return:
         inc r12
+        cmp r15, 1000000000
+        jg end
+        inc r15
         jmp short _start.loop
     .loop_end:
 end:
@@ -381,7 +385,7 @@ output_cell:
     mov rdi, 1
     mov rsi, r13
     mov rdx, 1
-    syscall
+    ; syscall
     jmp dispatch_return

 replace_cell:
```

Once patched and assembled with `make`, the below command was ran.

`sudo perf stat -a -B -o perf_report --table -r 10 ./bfasm tests/fib.bf`

Overall, the report evaluates to 197,424,284 Brainfuck operations a second (note: the elapsed execution time includes process startup and exit).
