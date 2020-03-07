%define O_RDONLY 0
%define PROT_READ 1
%define PROT_WRITE 2

%define MAP_PRIVATE 2
%define MAP_ANON 32

section .data
usage_str: db "usage: ./bfasm <filename>",0xa
usage_str_len equ $-usage_str
dispatch:
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
    dq inc_cell
    dq replace_cell
    dq dec_cell
    dq output_cell
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
    dq mov_ptr_left
	dq end
    dq mov_ptr_right
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
    dq branch_forward
	dq end
    dq branch_backward
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end
	dq end

section .bss
buffer: resb 256

section .text
global _start

_start:
    ; mmap a file
    xor rbp, rbp
    mov rdx, [rsp]
    cmp rdx, 2
    jl usage

    mov rdi, [rsp+16] ; argv[1]
    xor rdx, rdx
    mov rsi, O_RDONLY
    mov rax, 2
    syscall ; sys_open
    mov r8, rax

    lea rsi, [buffer]
    mov rax, 4
    syscall ; sys_stat

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
        lea rax, [rsi * 8 + dispatch]
        jmp [rax] ; dispatch table
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
    mov al, byte [r13]
    inc al
    mov byte [r13], al
    jmp dispatch_return

dec_cell:
    mov al, byte [r13]
    dec al
    mov byte [r13], al
    jmp dispatch_return

output_cell:
    mov rax, 1
    mov rdi, 1
    mov rsi, r13
    mov rdx, 1
    syscall
    jmp dispatch_return

replace_cell:
    xor eax, eax
    xor edi, edi
    mov rsi, r13
    mov rdx, 1
    syscall
    jmp dispatch_return

branch_forward:
    mov bl, byte [r13]
    test bl, bl
    jnz .advance

    mov rsi, 1
    xor r11, r11    ; nesting
    .loop:
        mov dl, byte[r12 + rsi]
        .B1:
            cmp dl, '['
            jne .B2
            inc r11
            jmp .loop_rep
        .B2:
            cmp dl, ']'
            jne .loop_rep
            test r11, r11
            jz .loop_exit
            dec r11
        .loop_rep:
            inc rsi
            jmp .loop
    .loop_exit:
    add r12, rsi
    jmp dispatch_return
    .advance:
    push r12
    jmp dispatch_return

branch_backward:
    mov bl, byte [r13]
    test bl, bl
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
    ret
