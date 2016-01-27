.PHONY: test

all: html

library:
	coffee --output lib --compile src
	browserify src/index.coffee \
		--transform coffeeify \
		--extension=".coffee" \
		--standalone algebra \
		--debug \
		--outfile build/algebra.js

html:
	jade --hierarchy --pretty --out build src/assets

test:
	mocha test \
		--require should \
		--compilers coffee:coffee-script/register

server:
	serve ./build --reload --inject --target html --watch ./src/assets