all: caster_wvfm_asm

caster_wvfm_asm: main.c ini.c csv.c fread_csv_line.c split.c
	gcc -O1 -g $^ -o caster_wvfm_asm

clean:
	rm -f caster_wvfm_asm
