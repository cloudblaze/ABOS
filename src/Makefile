all:	Image

Image:	boot head
	dd if=/dev/zero of=Image bs=10321920 count=1
	dd if=boot of=Image bs=512 count=1 conv=notrunc
	dd if=head of=Image bs=512 seek=1 conv=notrunc

boot: boot.o
	ld -m elf_i386 --oformat binary -Ttext=0x0 -o $@ $^
boot.o:	boot.s
	as --32 -o $@ $<

head: head.o
	ld -m elf_i386 --oformat binary -Ttext=0x0 -Map head.map -o $@ $^
head.o:	head.s
	as --32 -o $@ $<

clean:
	rm -f boot.o head.o boot head head.map Image
