; boot/boot.asm
BITS 16
ORG 0x7C00

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
    call print_string

    call enable_a20

    mov si, msg_gdt
    call print_string

    cli
    lgdt [gdt_descriptor]

    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG:protected_mode

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    jmp print_string
.done:
    ret

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

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

    call 0x10000

    jmp $

print_string_32:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0F
    mov [0xB8000], ax
    add dword [vga_offset], 2
    mov edi, [vga_offset]
    mov byte [0xB8000 + edi], 0
    jmp print_string_32
.done:
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

msg_boot db "NovaOS booting...", 0
msg_gdt  db "Loading GDT...", 0
msg_protected db "Protected mode OK!", 0

times 510 - ($ - $$) db 0
dw 0xAA55