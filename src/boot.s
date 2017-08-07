BOOTSEG	= 0x07C0
SYSSEG	= 0X1000
SYSLEN	= 38

	.code16
	.section .text
	.global _start
_start:
	ljmp $BOOTSEG, $go
go:
	mov %cs, %ax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	mov %ax, %ss
	mov $0x400, %sp
	
	mov %dl, cur_disk
	
	mov $0, %eax		/* appended code */
	mov $0, %ebx
	mov $0, %ecx
	mov $0, %edx
	mov $0, %esi
	mov $0, %edi
	mov $0, %ebp

	mov $0x0003, %ax	/* Init VGA mode */
	int $0x10
	
load_system:
	mov cur_disk, %dl
	mov $0x0002, %cx
	mov $SYSSEG, %ax
	mov %ax, %es
	xor %bx, %bx
	mov $0x200+SYSLEN, %ax
	int $0x13
	jnc ok_load
die:
	jmp die


ok_load:
	cli
	mov $SYSSEG, %ax
	mov %ax, %ds
	xor %ax, %ax
	mov %ax, %es
	mov $0x3800, %ecx
	sub %si, %si
	sub %di, %di
	rep movsw
	
	mov $BOOTSEG, %ax
	mov %ax, %ds
	lidt idt_48
	lgdt gdt_48
	
	mov $0x0001, %ax
	lmsw %ax
	
	ljmp $0x8, $0x0

gdt:
	.word 0x0, 0x0, 0x0, 0x0
	
	.word 0x07FF
	.word 0x0000
	.word 0x9A00
	.word 0x00C0
	
	.word 0x07FF
	.word 0x0000
	.word 0x9200
	.word 0x00C0

idt_48:
	.word 0x0
	.word 0x0, 0x0
gdt_48:
	.word 0x07FF
	.word 0x7C00+gdt, 0
	
cur_disk:
	.byte 0x0
	
	.org 510
	.word 0xAA55
