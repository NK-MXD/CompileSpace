cc = gcc
bis = bison
prom = expr2
deps = expr2.y
source = expr2.tab.c expr2.tab.h
in = expr2in
 
$(prom): $(source)
	$(cc) -o $(prom) $(source) -lm

$(source): $(deps)
	$(bis) -d $(deps)

clean:
	rm -rf $(source) $(prom)

test: $(prom)
	./$(prom) $(in)