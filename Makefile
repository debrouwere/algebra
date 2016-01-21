all:
	coffee --output build --bare --compile src
	jade --out build src
	stylus --out build src

test:
	mocha test \
		--require should \
		--compilers coffee:coffee-script/register

server:
	serve ./build --reload --inject --target --watch ./src