LATCH		= 11930
SCRN_SEL	= 0x18
TSS0_SEL	= 0x20
LDT0_SEL	= 0x28
TSS1_SEL	= 0x30
LDT1_SEL	= 0x38

	.section .text
	.global _start
_start:
	mov $0x10, %eax
	mov %ax, %ds
	lss init_stack, %esp
	
	call setup_idt
	call setup_gdt
	mov $0x10, %eax
	mov %ax, %ds
	mov %ax, %es
	mov %ax, %fs
	mov %ax, %gs
	lss init_stack, %esp
	
	mov $0x36, %al
	mov $0x43, %edx
	out %al, %dx
	mov $LATCH, %eax
	mov $0x40, %edx
	out %al, %dx
	mov %ah, %al
	out %al, %dx
	
	mov $0x00080000, %eax
	mov $timer_interrupt, %ax
	mov $0x8E00, %dx
	mov $0x08, %ecx
	lea idt(, %ecx, 8), %esi
	mov %eax, (%esi)
	mov %edx, 4(%esi)
	mov $system_interrupt, %ax
	mov $0xEF00, %dx
	mov $0x80, %ecx
	lea idt(, %ecx, 8), %esi
	mov %eax, (%esi)
	mov %edx, 4(%esi)

	mov $1024*5, %ecx
	xor %eax, %eax
	mov $0x2000, %edi
	cld
	rep stosl
	
	movl $pg0+7, pg_dir
	movl $pg1+7, pg_dir+4
	movl $pg2+7, pg_dir+8
	movl $pg3+7, pg_dir+12
	
	mov $pg3+4092, %edi
	mov $0xFFF007, %eax
	std
1:
	stosl
	sub $0x1000, %eax
	jge 1b
	mov $pg_dir, %eax
	mov %eax, %cr3
	mov %cr0, %eax
	or $0x80000000, %eax
	mov %eax, %cr0
	
	pushf
	andl $0xFFFFBFFF, (%esp)
	popf
	mov $TSS0_SEL, %eax
	ltr %ax
	mov $LDT0_SEL, %eax
	lldt %ax
	movl $0, current
	sti
	push $0x17
	push $init_stack
	pushf
	push $0x0F
	push $task0
	iret

setup_gdt:
	lgdt lgdt_opcode
	ret

setup_idt:
	lea ignore_int, %edx
	mov $0x00080000, %eax
	mov %dx, %ax
	mov $0x8E00, %dx
	lea idt, %edi
	mov $256, %ecx
rp_idt:
	mov %eax, (%edi)
	mov %edx, 4(%edi)
	add $0x8, %edi
	dec %ecx
	jne rp_idt
	lidt lidt_opcode
	ret

write_char:
	push %gs
	push %ebx
	mov $SCRN_SEL, %ebx
	mov %bx, %gs
	mov scr_loc, %bx
	shl $1, %ebx
	mov %al, %gs:(%ebx)
	shr $1, %ebx
	inc %ebx
	cmp $2000, %ebx
	jb 1f
	mov $0, %ebx
1:
	mov %ebx, scr_loc
	pop %ebx
	pop %gs
	ret

	.align 4
ignore_int:
	push %ds
	push %eax
	mov $0x10, %eax
	mov %ax, %ds
	mov $'C', %eax
	call write_char
	pop %eax
	pop %ds
	iret

	.align 4
timer_interrupt:
	push %ds
	push %eax
	mov $0x10, %eax
	mov %ax, %ds
	mov $0x20, %al
	out %al, $0x20
	cmp %eax, current
	je 1f
	mov %eax, current
	ljmp $TSS1_SEL, $0
	jmp 2f
1:
	movl $0, current
	ljmp $TSS0_SEL, $0
2:
	pop %eax
	pop %ds
	iret
	
	.align 4
system_interrupt:
	push %ds
	push %edx
	push %ecx
	push %ebx
	push %eax
	mov $0x10, %edx
	mov %dx, %ds
	call write_char
	pop %eax
	pop %ebx
	pop %ecx
	pop %edx
	pop %ds
	iret
	
current:
	.long 0
scr_loc:
	.long 0
	
	.align 4
lidt_opcode:
	.word 256*8-1
	.long idt
lgdt_opcode:
	.word (end_gdt-gdt)-1
	.long gdt

	.align 8
idt:
	.fill 256, 8, 0

gdt:
	.quad 0x0000000000000000
	.quad 0x00C09A00000007FF
	.quad 0x00C09200000007FF
	.quad 0x00C0920B80000002
	.word 0x68, tss0, 0xE900, 0x0
	.word 0x40, ldt0, 0xE200, 0x0
	.word 0x68, tss1, 0xE900, 0x0
	.word 0x40, ldt1, 0xE200, 0x0
end_gdt:

	.fill 128, 4, 0
init_stack:
	.long init_stack
	.word 0x10
	
	.align 8
ldt0:
	.quad 0x0000000000000000
	.quad 0x00C0FA00000003FF
	.quad 0x00C0F200000003FF
tss0:
	.long 0
	.long krn_stk0, 0x10
	.long 0, 0, 0, 0, 0x2000
	.long 0, 0, 0, 0, 0
	.long 0, 0, 0, 0, 0
	.long 0, 0, 0, 0, 0, 0
	.long LDT0_SEL, 0x08000000
	
	.fill 128, 4, 0
krn_stk0:

	.align 8
ldt1:
	.quad 0x0000000000000000
	.quad 0x00C0FA00000003FF
	.quad 0x00C0F200000003FF
tss1:
	.long 0
	.long krn_stk1, 0x10
	.long 0, 0, 0, 0, 0x2000
	.long task1, 0x0200
	.long 0, 0, 0, 0
	.long usr_stk1, 0, 0, 0
	.long 0x17, 0x0F, 0x17, 0x17, 0x17, 0x17
	.long LDT0_SEL, 0x08000000
	
	.fill 128, 4, 0
krn_stk1:

task0:
	mov $'A', %al
	int $0x80
	mov $0xFFF, %ecx
1:
	loop 1b
	jmp task0

task1:
	mov $'B', %al
	int $0x80
	mov $0xFFF, %ecx
1:
	loop 1b
	jmp task1
	
	.fill 128, 4, 0
usr_stk1:


	.org 0x2000
pg_dir:

	.org 0x3000
pg0:
	
	.org 0x4000
pg1:
	
	.org 0x5000
pg2:
	
	.org 0x6000
pg3:
	
	.org 0x7000
