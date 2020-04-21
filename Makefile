
all: dbank.bin dstream.bin vag2wav.bin

dbank.bin: dbank/dbank.c dbank/dbank.h
	cc -o $@ $<

dstream.bin: dstream/dstream.c dstream/dstream.h
	cc -o $@ $<

vag2wav.bin: vag2wav/vag2wav.c vag2wav/endian.c
	cc -o $@ $<

clean:
	rm -f dbank.bin dstream.bin vag2wav.bin
