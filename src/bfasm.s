%define O_RDONLY 0
%define PROT_READ 1
%define PROT_WRITE 2

%define MAP_PRIVATE 2
%define MAP_ANON 32
%define TAPE_LENGTH 0xa000

%define CACHE_SIZE 32

%macro retn_loop 0
    inc r12
    jmp _start.loop
%endmacro

%macro do_syscall 0
    push r14
    push r13
    push r12
    push r11
    syscall
    pop r11
    pop r12
    pop r13
    pop r14
%endmacro

section .data
cache: times CACHE_SIZE db 0

usage_str: db "usage: ./bfasm <filename>",0xa
usage_str_len equ $-usage_str
mmap_err_str: db "failed to allocate memory",0xa
mmap_err_str_len equ $-mmap_err_str
open_err_str: db "unable to open file",0xa
open_err_str_len equ $-open_err_str
stat_err_str: db "unable to stat file",0xa
stat_err_str_len equ $-stat_err_str

section .bss
buffer: resb 256

section .text
global _start

_start:
    xor rbp, rbp
    mov rdx, [rsp]
    cmp rdx, 2
    jl usage

    mov rdi, [rsp+16] ; argv[1]
    xor rdx, rdx
    mov rsi, O_RDONLY
    mov rax, 2
    syscall ; sys_open
    cmp rax, 0
    jl open_error
    mov r8, rax

    lea rsi, [buffer]
    mov rax, 4
    syscall ; sys_stat
    cmp rax, 0
    jl stat_error

    mov rsi, [buffer + 48] ; st_size
    mov rdx, PROT_READ
    mov r10, MAP_PRIVATE
    call mmap_n
    mov r12, rax        ; addr of file
    lea r14, [rsi + r12]; size of file

    xor r15, r15

    .mmap:
    mov rsi, TAPE_LENGTH
    mov rdx, PROT_READ|PROT_WRITE
    mov r10, MAP_PRIVATE|MAP_ANON
    xor r8, r8
    call mmap_n
    xor r15, 1
    jnz .first_iter_mmap
    add rax, TAPE_LENGTH
    mov rsp, rax
    jmp .loop_init
    .first_iter_mmap:
    mov r13, rax
    jmp .mmap

    ; zero program memory
    mov rbx, r13
    lea rcx, [r13 + TAPE_LENGTH]
    .zero:
        add qword [rbx], 0
        add rbx, 8
        cmp rbx, rcx
        jl .zero

    ; register usage
    ; r14   - code end pointer
    ; r13   - cell pointer
    ; r12   - code pointer
    ; r11   - cache ptr
    ; rsp   - call stack

    .loop_init:
        mov r11, cache

    .loop:
        cmp r14, r12
        je dispatch_return.loop_end

        xor rsi, rsi
        mov sil, byte [r12]
        cmp sil, '+'
        jz inc_cell
        cmp sil, '>'
        jz mov_ptr_right
        cmp sil, '<'
        jz mov_ptr_left
        cmp sil, '-'
        jz dec_cell
        cmp sil, '['
        jz branch_forward
        cmp sil, ']'
        jz branch_backward
        cmp sil, ','
        jz replace_cell
        cmp sil, '.'
        jnz dispatch_return

        ; add byte to cache
        mov dl, byte [r13]
        mov byte [r11], dl
        inc r11

        cmp r11, cache + CACHE_SIZE - 1
        jne short dispatch_return

        .flush_cache:
            mov rax, 1
            mov rdi, 1
            mov rsi, cache
            mov rdx, CACHE_SIZE
            do_syscall

            ; reset cache offset
            mov r11, cache

dispatch_return:
        inc r12
        jmp _start.loop
    .loop_end:
    .dump_io_cache:
        mov rax, 1
        mov rdi, 1
        mov rsi, cache
        mov rdx, r11
        sub rdx, rsi
        syscall
end:
    xor rdi, rdi
    mov rax, 60 ; sys_exit
    syscall

usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, usage_str
    mov rdx, usage_str_len
    syscall ; sys_write
    jmp end

mov_ptr_left:
    dec r13
    retn_loop

mov_ptr_right:
    inc r13
    retn_loop

inc_cell:
    mov al, [r13]
    inc al
    mov byte [r13], al
    retn_loop

dec_cell:
    mov al, [r13]
    dec al
    mov byte [r13], al
    retn_loop

replace_cell:
    xor eax, eax
    xor edi, edi
    mov rsi, r13
    mov rdx, 1
    do_syscall
    retn_loop

branch_forward:
    cmp byte [r13], 0
    jnz .advance

    xor r8, r8    ; nesting
    .loop:
        inc r12
        mov dl, byte [r12]
        .B1:
            cmp dl, '['
            jne .B2
            inc r8
            jmp .loop_rep
        .B2:
            cmp dl, ']'
            jne .loop_rep
            test r8, r8
            jz .exit
            dec r8
        .loop_rep:
            jmp .loop
    .advance:
    push r12
    .exit:
    retn_loop

branch_backward:
    cmp byte [r13], 0
    jz .advance
    pop r12
    dec r12
    retn_loop
    .advance:
    add rsp, 8
    retn_loop

mmap_n:
    xor rdi, rdi
    xor r9, r9
    mov rax, 9 ; sys_mmap
    do_syscall
    cmp rax, 0
    jl mmap_error
    ret

mmap_error:
    mov rsi, mmap_err_str
    mov rdx, mmap_err_str_len
    jmp error

stat_error:
    mov rsi, stat_err_str
    mov rdx, stat_err_str_len
    jmp error

open_error:
    mov rsi, open_err_str
    mov rdx, open_err_str_len

error:
    push rax
    mov rax, 1
    mov rdi, 1
    syscall ; sys_write
    pop rdi
    jmp end+3
