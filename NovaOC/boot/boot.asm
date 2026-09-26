BITS 16
ORG 0x7C00

KERNEL_OFFSET equ 0x100000
KERNEL_SECTORS equ 64

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

    mov si, msg_boot
    call print_string_16

    call enable_a20

    mov si, msg_kernel
    call print_string_16

    call load_kernel

    mov si, msg_gdt
    call print_string_16

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG:protected_mode

print_string_16:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string_16
.done:
    ret

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

load_kernel:
    mov ax, KERNEL_OFFSET >> 4
    mov es, ax
    xor bx, bx

    mov ah, 0x02
    mov al, KERNEL_SECTORS
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00
    mov dl, [boot_drive]
    int 0x13

    jc .disk_error

    mov si, msg_kernel_ok
    call print_string_16
    ret

.disk_error:
    mov si, msg_disk_error
    call print_string_16
    cli
    hlt
    jmp .disk_error

BITS 32

protected_mode:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    mov esi, msg_protected
    call print_string_32

    jmp KERNEL_OFFSET

print_string_32:
    push eax
    push ebx
    push edi
    mov edi, [vga_offset]
    mov ebx, 0xB8000

.loop:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0F
    mov [ebx + edi], ax
    add edi, 2
    jmp .loop

.done:
    mov [vga_offset], edi
    pop edi
    pop ebx
    pop eax
    ret

vga_offset dd 0

gdt_start:
    dq 0x0000000000000000

gdt_code:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

boot_drive db 0

msg_boot        db "NovaOS booting...", 13, 10, 0
msg_kernel      db "Loading kernel...", 13, 10, 0
msg_kernel_ok   db "Kernel loaded OK", 13, 10, 0
msg_disk_error  db "DISK ERROR!", 13, 10, 0
msg_gdt         db "Loading GDT...", 13, 10, 0
msg_protected   db "Protected mode OK!", 0

times 510 - ($ - $$) db 0
dw 0xAA55
