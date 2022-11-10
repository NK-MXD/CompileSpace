cc = gcc
bis = bison
prom = expr1
deps = expr1.y
source = expr1.tab.c expr1.tab.h
in = expr1in
 
$(prom): $(source)
	$(cc) -o $(prom) $(source) -lm

$(source): $(deps)
	$(bis) -d $(deps)

clean:
	rm -rf $(source) $(prom)

test: $(prom)
	./$(prom) $(in)
