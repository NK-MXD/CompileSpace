cc = g++
bis = bison
prom = expr3
deps = expr3.y
source = expr3.tab.c expr3.tab.h
in = expr3in 

$(prom): $(source)
	$(cc) -o $(prom) $(source) -lm

$(source): $(deps)
	$(bis) -d $(deps)

clean:
	rm -rf $(source) $(prom)

test: $(prom)
	./$(prom) $(in)