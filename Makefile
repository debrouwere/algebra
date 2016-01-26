.PHONY: test

all:
	coffee --output lib --compile src
	coffee --output build --compile src/interface.coffee
	browserify src/interface.coffee \
		--transform coffeeify \
		--extension=".coffee" \
		--debug \
		--outfile build/algebra.js
	jade --out build src
	stylus --out build src

test:
	mocha test \
		--require should \
		--compilers coffee:coffee-script/register

server:
	serve ./build --reload --inject --target --watch ./src