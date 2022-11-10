cc = g++
bis = bison
prom = format2
deps = format2.y
source = format2.tab.c format2.tab.h
in = format2in
 
$(prom): $(source)
	$(cc) -o $(prom) $(source)

$(source): $(deps)
	$(bis) -d $(deps)

clean:
	rm -rf $(source) $(prom)

test: $(prom)
	./$(prom) $(in)

