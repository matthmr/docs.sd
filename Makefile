include make/Html.mk

MD2HTML?=cmark
MD2ROFF?=marked-man

MAKEFILES:= \
	make/Html.mk

default: docs
help:
	@echo -e "[ targets available ] \n\
	  - docs: make html documentation \n\
	  - docs-man: make manpage documentation \n\
	  - clean: cleans working directory (*.html files) \n\
	  - clean-make: cleans make files \n\
	\n\
	[ variables available ] \n\
	  - MD2HML: markdown to html compiler \(${MD2HTML}\) \n\
	  - MD2ROFF: markdown to roff compiler \(${MD2ROFF}\)"

docs: index.html
docs-man: index.1

index.html: markdown/index.md
	@echo [ .. ] Compiling 'index.html'
	@${MD2HTML} markdown/index.md | awk -vheader=${HTML_HEADER} -vfooter=${HTML_FOOTER} -f scripts/headers.awk > index.html
index.1: markdown/index.md
	@echo [ .. ] Compiling 'index.1'
	${MD2ROFF} markdown/index.md > man/index.1

clean:
	@echo "[ .. ] Cleaning working directory"
	@find -type f -name '*.html' | xargs rm -rvf
clean-make:
	@echo "[ .. ] Cleaning make files"
	@rm -rfv ${MAKEFILES}
