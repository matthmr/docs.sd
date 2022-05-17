# Made by mH (https://github.com/matthmr)

CMARK?=cmark

default: docs

help:
	@echo \[\[ available targets \]\]
	@echo   - docs: make docs
	@echo
	@echo \[\[ available variables \]\]
	@echo   - CMARK: markdown compiler \(${CMARK}\)

docs: index.html

index.html: markdown/index.md
	@echo [ .. ] Compiling 'index.html'
	${CMARK} --unsafe markdown/index.md > index.html
