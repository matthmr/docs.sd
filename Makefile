# Made by mH (https://github.com/matthmr)
MD2HTML?=cmark
MD2ROFF?=marked-man

default: docs
help:
	@echo \[\[ available targets \]\]
	@echo   - docs: make html documentation
	@echo   - docs-man: make manpage documentation
	@echo
	@echo \[\[ available variables \]\]
	@echo   - MD2HML: markdown to html compiler \(${MD2HTML}\)
	@echo   - MD2ROFF: markdown to roff compiler \(${MD2ROFF}\)

docs: index.html
docs-man: index.1

index.html: markdown/index.md
	@echo [ .. ] Compiling 'index.html'
	${MD2HTML} --unsafe markdown/index.md > index.html
index.1: markdown/index.md
	@echo [ .. ] Compiling 'index.1'
	${MD2ROFF} markdown/index.md > man/index.1
