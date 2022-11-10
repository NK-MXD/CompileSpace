cc = gcc
bis = bison
prom = format1
deps = format1.y
source = format1.tab.c format1.tab.h
in = format1in 
 
$(prom): $(source)
	$(cc) -o $(prom) $(source)

$(source): $(deps)
	$(bis) -d $(deps)

clean:
	rm -rf $(source) $(prom)

test: $(prom)
	./$(prom) $(in)
