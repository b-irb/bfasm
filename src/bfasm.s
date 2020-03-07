%define O_RDONLY 0
%define PROT_READ 1
%define PROT_WRITE 2

%define MAP_PRIVATE 2
%define MAP_ANON 32

section .data
usage_str: db "usage: ./bfasm <filename>",0xa
usage_str_len equ $-usage_str
; dispatch table
dispatch:
    dq inc_cell
	dq replace_cell
    dq dec_cell
    dq output_cell
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq mov_ptr_left
	dq dummy
	dq mov_ptr_right
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
	dq dummy
    dq jmp_cellz
	dq dummy
    dq jmp_cellnz
	dq dummy

section .bss
stat_struc: resb 144

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

    lea rsi, [stat_struc]
    mov rax, 4
    syscall ; sys_stat

    mov rsi, [stat_struc + 48] ; st_size
    mov rdx, PROT_READ
    mov r10, MAP_PRIVATE
    call mmap_n
    mov r12, rax        ; addr of file
    lea r14, [rsi + r12]; size of file

    mov rsi, 0x800 ; 2K
    mov rdx, PROT_READ|PROT_WRITE
    mov r10, MAP_PRIVATE|MAP_ANON
    xor r8, r8
    call mmap_n
    mov r13, rax

    ; register usage
    ; r14   - code end pointer
    ; r13   - pointer
    ; r12   - code pointer
    ; r13   - cell pointer
    ; r9    - level of nesting

    ; use the stack to store branch entry points

    .loop:
        cmp r14, r12
        je short dispatch_return.loop_end

        xor rsi, rsi
        mov sil, byte [r12]
        sub sil, '+'
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
jmp_cellz:
    xor esi, esi
    mov bl, byte [r13]
    test bl, bl
    jnz .advance
    add esi, 1
    xor r9, r9
    .loop:
        mov dl, byte [r12 + rsi]
        .B1:
            cmp dl, '['
            jne .B2
            inc r9
            jmp .loop_end
        .B2:
            cmp dl, ']'
            jne .loop_end
            test r9, r9
            jz .end
            dec r9
    .loop_end:
        inc rsi
        jmp .loop
    .end:
    add r12, rsi
    jmp dispatch_return
    .advance:
    push r12
    jmp dispatch_return
jmp_cellnz:
    mov bl, byte [r13]
    test bl, bl
    jz .end
    pop r12
    dec r12 ; account for inc
    jmp dispatch_return
    .end:
    add rsp, 8
    jmp dispatch_return

dummy:
    ; dummy entry for dispatch table, should never be invoked
    jmp end

mmap_n:
    xor rdi, rdi
    xor r9, r9
    mov rax, 9 ; sys_mmap
    syscall
    ret
