SRC_PATH ?= src
INC_PATH += include
BUILD_PATH ?= build
TEST_PATH ?= test
OBJ_PATH ?= $(BUILD_PATH)/obj
BINARY ?= $(BUILD_PATH)/compiler
SYSLIB_PATH ?= sysyruntimelibrary

INC = $(addprefix -I, $(INC_PATH))
SRC = $(shell find $(SRC_PATH)  -name "*.cpp")
CFLAGS = -O0 -g -Wall -Werror $(INC)
FLEX ?= $(SRC_PATH)/zmlexer.l
LEXER ?= $(addsuffix .cpp, $(basename $(FLEX)))
BISON ?= $(SRC_PATH)/zmparser.y
PARSER ?= $(addsuffix .cpp, $(basename $(BISON)))
SRC += $(LEXER)
SRC += $(PARSER)
OBJ = $(SRC:$(SRC_PATH)/%.cpp=$(OBJ_PATH)/%.o)
PARSERH ?= $(INC_PATH)/$(addsuffix .h, $(notdir $(basename $(PARSER))))
TEST ?= $(shell find test/TA -name "*.sy")

BINARY_LABFOUR ?= $(BUILD_PATH)/zmlexer
TEST_LABFOUR ?= $(shell find test/lab3 -name "*.sy")
TEST_LEVEL2 ?= $(shell find test/level2 -name "*.sy")
TEST_LEVEL1 ?= $(shell find test/level1 -name "*.sy")

.phony:app run gdb clean test

$(LEXER):$(FLEX)
	@flex -o $@ $<

$(PARSER):$(BISON)
	@bison -o $@ $< --warnings=error=all --defines=$(PARSERH)

$(OBJ_PATH)/%.o:$(SRC_PATH)/%.cpp
	@mkdir -p $(OBJ_PATH)
	@g++ $(CFLAGS) -c -o $@ $<

$(BINARY):$(OBJ)
	@g++ -O0 -g -o $@ $^

app:$(LEXER) $(PARSER) $(BINARY)

run:app
	@$(BINARY) -o example.out example.sy

gdb:app
	@gdb $(BINARY)

$(OBJ_PATH)/lexer.o:$(SRC_PATH)/zmlexer.cpp
	@mkdir -p $(OBJ_PATH)
	@g++ $(CFLAGS) -c -o $@ $<

$(BINARY_LABFOUR):$(OBJ_PATH)/zmlexer.o
	@g++ -O0 -g -o $@ $^

.ONESHELL:
testlabthree:$(LEXER) $(BINARY_LABFOUR)
	@mkdir -p $(TEST_PATH)/lab3
	for file in $(TEST_LABFOUR)
	do
		out=$${file##*/}
		out=$(TEST_PATH)/lab3/$${out%.sy}.out
		$(BINARY_LABFOUR) <$${file} >$${out} --lab3
	done

testlevel1:$(LEXER) $(BINARY_LABFOUR)
	@mkdir -p $(TEST_PATH)/level1
	for file in $(TEST_LEVEL1)
	do
		out=$${file##*/}
		out=$(TEST_PATH)/level1/$${out%.sy}.out
		$(BINARY_LABFOUR) <$${file} >$${out}
	done

testlevel2:$(LEXER) $(BINARY_LABFOUR)
	@mkdir -p $(TEST_PATH)/level2
	for file in $(TEST_LEVEL2)
	do
		out=$${file##*/}
		out=$(TEST_PATH)/level2/$${out%.sy}.out
		$(BINARY_LABFOUR) <$${file} >$${out} 
	done

clean:
	@rm -rf $(BUILD_PATH) $(PARSER) $(LEXER) $(PARSERH) ./example.out

cleanlabthree:
	@rm -rf $(BUILD_PATH) $(LEXER) $(TEST_PATH)/lab3/*.out ./example.out