# Brainfuck implementation in x86_64 assembly

This is an implementation of the [Brainfuck language](https://github.com/brain-lang/brainfuck/blob/master/brainfuck.md). Brainfuck is an esolang which is closely resembles a Turing machine (with the addition of bulit-in conditional expressions).

The interpreter is designed to use a dynamic dispatch table to improve performance compared to a switch ladder. The syscalls are somewhat unreliable as to what they clobber but I abused any preservation of registers to reduce the number of instructions.

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

`bfasm` executed 1 billion Brainfuck operations in 5.59 seconds. Benchmarking included modifying `bfasm` to limit each process to 1 billion operations, and removing the syscall to `sys_write` as IO operations are not deterministic/challenging to benchmark meaningfully.

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

```
# started on Sat Mar  7 18:02:22 2020


 Performance counter stats for 'system wide' (10 runs):

         11,170.47 msec cpu-clock                 #    1.999 CPUs utilized            ( +-  0.30% )
             3,427      context-switches          #    0.307 K/sec                    ( +-  5.21% )
                27      cpu-migrations            #    0.002 K/sec                    ( +- 31.48% )
             4,253      page-faults               #    0.381 K/sec                    ( +- 53.76% )
    17,826,817,126      cycles                    #    1.596 GHz                      ( +-  3.13% )  (81.67%)
    24,164,307,344      stalled-cycles-frontend   #  135.55% frontend cycles idle     ( +-  1.24% )  (83.32%)
       439,029,540      stalled-cycles-backend    #    2.46% backend cycles idle      ( +- 48.67% )  (35.01%)
    16,091,252,177      instructions              #    0.90  insn per cycle
                                                  #    1.50  stalled cycles per insn  ( +-  4.51% )  (51.68%)
     5,650,682,525      branches                  #  505.859 M/sec                    ( +-  1.87% )  (66.68%)
       147,064,553      branch-misses             #    2.60% of all branches          ( +-  0.67% )  (83.34%)

            # Table of individual measurements:
            5.6708 (+0.0836) #
            5.6877 (+0.1004) #
            5.6195 (+0.0322) #
            5.5508 (-0.0365) #
            5.5541 (-0.0332) #
            5.5467 (-0.0406) #
            5.5465 (-0.0408) #
            5.5996 (+0.0123) #
            5.5509 (-0.0363) #
            5.5461 (-0.0412) #

            # Final result:
            5.5873 +- 0.0173 seconds time elapsed  ( +-  0.31% )
```

This evaluates to 178,977,324 Brainfuck operations a second (note: the elapsed execution time includes process startup and exit).
