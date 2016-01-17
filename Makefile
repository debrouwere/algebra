all:
	coffee --output build --bare --compile src
	jade --out build src
	stylus --out build src

server:
	serve ./build --reload --inject --target --watch ./src