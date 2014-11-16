NAME=trinload
DEPS=

.PHONY: clean

$(NAME).dsk: $(NAME).asm $(DEPS)
	pyz80.py -s length -I samdos2 --mapfile=%NAME%.map $(NAME).asm

run: $(NAME).dsk
	open $(NAME).dsk

clean:
	rm -f $(NAME).dsk $(NAME).map
