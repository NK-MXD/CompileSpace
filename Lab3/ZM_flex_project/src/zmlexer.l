%option noyywrap
/*lex提供的行号,需要使用option声明,否则会一直为1*/
%option yylineno 
%{
    /*
    * You will need to comment this line in lab4.
    */
    #define ONLY_FOR_LEX
    
    #ifdef ONLY_FOR_LEX
    #else
    #define YYSTYPE void *
    #include "parser.h"
    #endif

    #define YY_NO_UNPUT
    #define YY_NO_INPUT
    #include <string>

    #ifdef ONLY_FOR_LEX
    #include <iostream>
    #include <ostream>
    #include <fstream>
    #include <utility>
    #include<unordered_map>
    #include<iomanip>
    #include <utility>
    #include<vector>
    using namespace std;
    extern FILE *yyin; 
    extern FILE *yyout;
    /*NODE:表示当前作用域*/
    int nowscope = 0;
    /*NODE:表示历史作用域*/
    int funcscope = 0;
    vector<int> scope(1,0);
    /*NODE:表示历史作用域中的指针*/
    int curScope = 0;
    /*定义一个scope变量用于标识作用域*/
    struct symbol
    {
	    int row;
	    int col;
        int scope;
        string name;
        unsigned long int addr;
    };
    /*定义所有作用域的符号表*/
    unordered_map<int,unordered_map<string,symbol>> allTab;

    /*NODE:增加列号的定义*/
    int column = 0;
    int newcolumn = 0;
    /*NODE:定义更新列号的函数,在每次识别出一个字符时调用*/
    void update_loc(){
        column = newcolumn;
        newcolumn = column + strlen(yytext);
    }
    /*NODE:重新定义debug函数:将其按照C++格式输出 注: 更改makefile中62行	$(BINARY_LABFOUR) <$${file} >$${out} --lab4*/
    /*输出格式:token   lexeme   lineno   offset  pointer_to_scope*/
    void DEBUG_FOR_LAB4(std::string token,std::string lexeme){
        // std::string DEBUG_INFO = "[DEBUG LAB4]: \t" + token + "\t" + lexeme + "\n";
        // fputs(DEBUG_INFO.c_str(), yyout);
        if(token == "ID"){
            unordered_map<string,symbol> nowTab;
            char temp[20];
            if(allTab.find(nowscope)!=allTab.end()){
                nowTab = allTab.find(nowscope)->second;
                if(nowTab.find(lexeme)!=nowTab.end()){
                    sprintf(temp, "0x%lx", (long unsigned int)(nowTab[lexeme].addr));
                    cout<<std::setw(10)<<token<<std::setw(10)<<lexeme<<std::setw(10)<<yylineno<<std::setw(10)<<column<<std::setw(10)<<nowTab[lexeme].scope<<std::setw(20)<<&(allTab.find(nowscope)->second)<<std::setw(20)<<temp<<std::endl;
                    return;
                }
            }
        }else{
            cout<<std::setw(10)<<token<<std::setw(10)<<lexeme<<std::setw(10)<<yylineno<<std::setw(10)<<column<<std::endl;
        }
    }
    #endif
    #define YY_USER_ACTION update_loc();  
    /*通过改写这个lex提供的宏，来每次识别列号函数定位*/
    /*宏YY_USER_ACTION可以被定义为提供一个总是在匹配规则的动作之前执行的动作。*/
%}

/*以下部分为定义正则表达式*/

/*QUES:1. 这里的浮点数有符号吗? 2. ([0-9]+[eE][+-]?[0-9]+))[fLlL]?这个部分浮点数开头可为0?*/
DECIMAL_FLOAT ((([0-9]*[.][0-9]*([eE][+-]?[0-9]+)?)|([0-9]+[eE][+-]?[0-9]+))[fLlL]?)
/*QUES:16进制的浮点数的指数是十进制?*/
HEXADECIMAL_FLOAT (0[xX](([0-9A-Fa-f]*[.][0-9A-Fa-f]*([pP][+-]?[0-9]+)?)|([0-9A-Fa-f]+[pP][+-]?[0-9]+))[fLlL]?)

DECIMIAL ([1-9][0-9]*|0)
OCTAL (0[0-7]+)
HEXADECIMAL (0[x|X][0-9A-Fa-f]+)

BLOCKCOMMENTBEGIN \/\*
BLOCKCOMMENTELEMENT .
BLOCKCOMMENTEND \*\/
LINECOMMENT \/\/[^\n]*

/*以下定义了一些符号*/
SEMICOLON ";"
LPAREN "("
RPAREN ")"
LBRACE "{"
RBRACE "}"
COMMA ","

/*以下定义的是各种算术运算符*/
ASSIGN "="
PLUS  "+"
MINUS "-"
MUL  "*"
DIV   "/"
MOD   "%"
PLUSASSIGN "+="
MINUSASSIGN "-="
MULASSIGN "*="
DIVASSIGN "/="
/*以下定义的是各种关系运算符*/
EQUAL "=="
GREATEQUAL ">="
GREAT ">"
LESS "<"
LESSEQUAL "<="
NOTEQUAL "!="
/*以下定义的是各种逻辑运算符*/
AND "&&"
OR "||"
NOT "!"

    /*注:这里的正则表达式中的[:alpha:]表示[a-zA-Z]*/
ID [[:alpha:]_][[:alpha:][:digit:]_]*  
    /*注: 这里代表的是换行符*/     
EOL (\r\n|\n|\r) 
    /*注: 这里代表的是空格或制表符*/                           
WHITE [\t ]          

%x BLOCKCOMMENT

%%

"int" {
    /*
    * Questions: 
    *   Q1: Why we need to return INT in further labs?在后续的语法分析器中我们需要识别终结符
    *   Q2: What is "INT" actually?
    */
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("INT","int");
    #else
        return INT;
    #endif
}

"float" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("FLOAT","float");
    #else
        return FLOAT;
    #endif
}

"void" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("VOID","void");
    #else
        return VOID;
    #endif 
}
"if" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("IF","if");
    #else
        return IF;
    #endif
}
"else" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("ELSE","else");
    #else
        return ELSE;
    #endif
}
"return" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RETURN","return");
    #else
        return RETURN;
    #endif
}
"while" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("WHILE","while");
    #else
        return WHILE;
    #endif
}
"break" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("BREAK","break");
    #else
        return BREAK;
    #endif
}
"continue" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("CONTINUE","continue");
    #else
        return CONTINUE;
    #endif
}

"const" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("CONST","const");
    #else
        return CONST;
    #endif
}

{ASSIGN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("ASSIGN","=");
    #else
        return ASSIGN;
    #endif
}

{PLUS} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("PLUS","+");
    #else
        return PLUS;
    #endif
}

{MINUS} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MINUS","-");
    #else
        return MINUS;
    #endif
}

{MUL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MUL","*");
    #else
        return MUL;
    #endif
}

{DIV} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("DIV","/");
    #else
        return DIV;
    #endif
}
{MOD} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MOD","%");
    #else
        return MOD;
    #endif
}

{PLUSASSIGN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("PLUSASSIGN","+=");
    #else
        return PLUSASSIGN;
    #endif
}

{MINUSASSIGN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MINUSASSIGN","-=");
    #else
        return MINUSASSIGN;
    #endif
}

{MULASSIGN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MULASSIGN","*=");
    #else
        return MULASSIGN;
    #endif
}

{DIVASSIGN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("DIVASSIGN","*/=");
    #else
        return DIVASSIGN;
    #endif
}

{EQUAL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("EQUAL","==");
    #else
        return EQUAL;
    #endif
}

{GREATEQUAL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("GREATEQUAL",">=");
    #else
        return GREATEQUAL;
    #endif
}

{GREAT} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("GREAT",">");
    #else
        return GREAT;
    #endif
}

{LESS} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LESS","<");
    #else
        return LESS;
    #endif
}

{LESSEQUAL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LESSEQUAL","<=");
    #else
        return LESSEQUAL;
    #endif
}

{NOTEQUAL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("NOTEQUAL","!=");
    #else
        return NOTEQUAL;
    #endif
}

{AND} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("AND","&&");
    #else
        return AND;
    #endif
}

{OR} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("OR","||");
    #else
        return OR;
    #endif
}

{NOT} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("NOT","!");
    #else
        return NOT;
    #endif
}

{COMMA} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("COMMA",",");
    #else
        return COMMA;
    #endif
}
{SEMICOLON} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("SEMICOLON",";");
    #else
        return SEMICOLON;
    #endif
}
{LPAREN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LPAREN","(");
    #else
        return LPAREN;
    #endif
}
{RPAREN} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RPAREN",")");
    #else
    return RPAREN;
    #endif
}

"[" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACKET","[");
    #else
        return LBRACKET;
    #endif
}
"]" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACKET","]");
    #else
        return RBRACKET;
    #endif
}

{DECIMAL_FLOAT} {
    #ifdef ONLY_FOR_LEX
        float temp;
        sscanf(yytext, "%f", &temp);
        DEBUG_FOR_LAB4(string("DECIMAL_FLOAT"),to_string(temp));
    #else
        return DECIMAL_FLOAT;
    #endif  
}

{HEXADECIMAL_FLOAT} {
    #ifdef ONLY_FOR_LEX
        float temp;
        sscanf(yytext, "%f", &temp);
        DEBUG_FOR_LAB4(string("HEXADECIMAL_FLOAT"),to_string(temp));
    #else
        return HEXADECIMAL_FLOAT;
    #endif  
}

{DECIMIAL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4(string("DECIMIAL"),string(yytext));
    #else
        return DECIMIAL;
    #endif
}

{OCTAL} {
    #ifdef ONLY_FOR_LEX
        int temp;
        sscanf(yytext, "%o", &temp);
        DEBUG_FOR_LAB4(string("OCTAL"),to_string(temp));
    #else
        return OCTAL;
    #endif
}

{HEXADECIMAL} {
    #ifdef ONLY_FOR_LEX
        int temp;
        sscanf(yytext, "%x", &temp);
        DEBUG_FOR_LAB4(string("HEXADECIMAL"),to_string(temp));
    #else
        return HEXADECIMAL;
    #endif
}

{LBRACE} {
    funcscope++;
    nowscope = funcscope;
    scope.push_back(nowscope);
    curScope = scope.size()-1;
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACE","{");
    #else
        return LBRACE;
    #endif
}
{RBRACE} {
    curScope--;
    nowscope = scope[curScope];
    scope.push_back(nowscope);
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACE","}");
    #else
        return RBRACE;
    #endif
}


{ID} {
    /*NODE:这里的逻辑如下:
    * 1. 判断是否存在该变量:遍历该符号表中当前作用域的符号
    * 2. 加入变量
    */  
    /*1. 判断是否存在该变量*/
    bool flag = true;
    unordered_map<string,symbol> nowTab;
    if(allTab.find(nowscope)!=allTab.end()){
        nowTab = allTab.find(nowscope)->second;
        if(nowTab.find(yytext)!=nowTab.end()){
            flag = false;
        }
    }
    /*2. 没有则添加变量*/
    if(flag){
        /*2.1 如果对应的符号表不存在,则添加符号表*/
        if(allTab.find(nowscope)==allTab.end()){
            unordered_map<string,symbol> newTab;
            symbol newid;
            newid.row = yylineno;
            newid.col = column;
            newid.scope = nowscope;
            newTab[yytext] = newid;
            allTab[nowscope]=newTab;
            newid.addr = (long unsigned int)&(allTab[nowscope][yytext]);
        }else{
            /*如果对应的符号表存在,则找到符号表向其中加入对应的项*/
            unordered_map<string,symbol>* table = &(allTab.find(nowscope)->second);
            symbol newid;
            newid.row = yylineno;
            newid.col = column;
            newid.scope = nowscope;
            table->insert(pair<string,symbol>(yytext, newid));
            newid.addr = (long unsigned int)&(allTab[nowscope][yytext]);
        }
    }

    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("ID",yytext);
    #else
        return ID;
    #endif
}

<*>{EOL} { 
    column = newcolumn = 0;
}
{WHITE} {}

{LINECOMMENT} {}
{BLOCKCOMMENTBEGIN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{BLOCKCOMMENTELEMENT} {}
<BLOCKCOMMENT>{BLOCKCOMMENTEND} {BEGIN INITIAL;}

%%

#ifdef ONLY_FOR_LEX
int main(int argc, char **argv){
    // if(argc != 5){
    //     fprintf(stderr, "Argument Not Enough");
    //     exit(EXIT_FAILURE);
    // }

    // if(!(yyin = fopen(argv[1], "r"))){
    //     fprintf(stderr, "No such file or directory: %s", argv[1]);
    //     exit(EXIT_FAILURE);
    // }

    // if(!(yyout = fopen(argv[3], "w"))){
    //     fprintf(stderr, "No such file or directory: %s", argv[3]);
    //     exit(EXIT_FAILURE);
    // }

    // yylex();
    cout<<std::setw(10)<<"token"<<std::setw(10)<<"lexeme"<<std::setw(10)<<"lineno"<<std::setw(10)<<"offset"<<std::setw(10)<<"scope_no"<<std::setw(20)<<"pointer_to_scope"<<std::setw(20)<<"pointer_to_symbol"<<std::endl;
    yylex();
    return 0;
}
#endif
