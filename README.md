# Brainfuck implementation in x86_64 assembly

This is a very brittle implementation of the [Brainfuck language](https://github.com/brain-lang/brainfuck/blob/master/brainfuck.md). Brainfuck is an esolang which is solely a symbolic renaming of a Turing machine (with the addition of conditional expressions).

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

`bfasm` executed 100 million Brainfuck operations in 11 seconds. Below is the command used to benchmark `bfasm` (a counter was added inside `bfasm` to exit after 100 million loops). The benchmark included IO which does make the results variable with respect to process environment.

`sudo perf stat -a -B -o perf_report ./bfasm tests/fib.bf`

```
# started on Sat Mar  7 16:59:56 2020


 Performance counter stats for 'system wide':

         22,143.71 msec cpu-clock                 #    2.000 CPUs utilized
         3,079,079      context-switches          #    0.139 M/sec
             3,205      cpu-migrations            #    0.145 K/sec
             3,014      page-faults               #    0.136 K/sec
    58,240,353,009      cycles                    #    2.630 GHz                      (83.33%)
    24,991,483,732      stalled-cycles-frontend   #   42.91% frontend cycles idle     (83.34%)
     4,934,886,849      stalled-cycles-backend    #    8.47% backend cycles idle      (33.33%)
    45,220,683,689      instructions              #    0.78  insn per cycle
                                                  #    0.55  stalled cycles per insn  (50.00%)
    11,859,974,814      branches                  #  535.591 M/sec                    (66.66%)
       321,981,384      branch-misses             #    2.71% of all branches          (83.32%)

      11.072156640 seconds time elapsed
```

This evaluates to 9,031,664 operations a second (note: the elapsed execution time includes process startup and exit).
