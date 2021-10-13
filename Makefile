all:
	mkdir -p build
	acme -v9 --cpu m65 -o build/hello.prg -l build/hello.labels -I src src/hello.asm
	
clean:
	rm -rf build
