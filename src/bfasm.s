%define O_RDONLY 0
%define PROT_READ 1
%define PROT_WRITE 2

%define MAP_PRIVATE 2
%define MAP_ANON 32

section .data
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
    mov rsi, 0x800 ; 2K
    mov rdx, PROT_READ|PROT_WRITE
    mov r10, MAP_PRIVATE|MAP_ANON
    xor r8, r8
    call mmap_n
    xor r15, 1
    jnz .first_iter_mmap
    add rax, 0x800
    mov rsp, rax
    jmp .loop
    .first_iter_mmap:
    mov r13, rax
    jmp .mmap

    ; register usage
    ; r14   - code end pointer
    ; r13   - pointer
    ; r12   - code pointer
    ; r13   - cell pointer
    ; rsp   - call stack

    .loop:
        cmp r14, r12
        je short dispatch_return.loop_end

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
        jnz end

        mov rax, 1
        mov rdi, 1
        mov rsi, r13
        mov rdx, 1
        syscall

dispatch_return:
        inc r12
        jmp short _start.loop
    .loop_end:
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
    jmp dispatch_return

mov_ptr_right:
    inc r13
    jmp dispatch_return

inc_cell:
    mov al, [r13]
    inc al
    mov byte [r13], al
    jmp dispatch_return

dec_cell:
    mov al, [r13]
    dec al
    mov byte [r13], al
    jmp dispatch_return

replace_cell:
    xor eax, eax
    xor edi, edi
    mov rsi, r13
    mov rdx, 1
    syscall
    jmp dispatch_return

branch_forward:
    cmp byte [r13], 0
    jnz .advance

    xor r11, r11    ; nesting
    .loop:
        inc r12
        mov dl, byte [r12]
        .B1:
            cmp dl, '['
            jne .B2
            inc r11
            jmp .loop_rep
        .B2:
            cmp dl, ']'
            jne .loop_rep
            test r11, r11
            jz .exit
            dec r11
        .loop_rep:
            jmp .loop
    .advance:
    push r12
    .exit:
    jmp dispatch_return

branch_backward:
    cmp byte [r13], 0
    jz .advance
    pop r12
    dec r12
    jmp dispatch_return
    .advance:
    add rsp, 8
    jmp dispatch_return

mmap_n:
    xor rdi, rdi
    xor r9, r9
    mov rax, 9 ; sys_mmap
    syscall
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
