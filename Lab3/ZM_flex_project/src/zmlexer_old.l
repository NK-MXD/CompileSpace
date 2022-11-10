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
    #include<unordered_map>
    #include<iomanip>
    #include <utility>
    #include<vector>
    using namespace std;
    extern FILE *yyin; 
    extern FILE *yyout;
    /*单个符号*/
    struct SymTab{
        string name;
        int row;
        int col;
    };
    /*单个作用域*/
    struct ScopeNode{
        unordered_map<string,SymTab> ScopeTab;
        ScopeNode* back;
    };
    /*全局符号表*/
    ScopeNode gloNode;
    /*符号表指针*/
    ScopeNode* curNode = &gloNode;
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
            unordered_map<string,SymTab> nowTab;
            nowTab = curNode->ScopeTab;
            if(nowTab.find(lexeme)!=nowTab.end()){
                cout<<std::setw(10)<<token<<std::setw(10)<<lexeme<<std::setw(10)<<yylineno<<std::setw(10)<<column<<std::setw(20)<<&(nowTab.find(lexeme)->second)<<std::endl;
                return;
            }
            nowTab = gloNode.ScopeTab;
            if(nowTab.find(lexeme)!=nowTab.end()){
                cout<<std::setw(10)<<token<<std::setw(10)<<lexeme<<std::setw(10)<<yylineno<<std::setw(10)<<column<<std::setw(20)<<&(nowTab.find(lexeme)->second)<<std::endl;
                return;
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
{LBRACE} {
    /*这里的逻辑是: 只要遇到{就新增加一个节点*/
    cout<<"未更新{"<<endl<<curNode<<endl;
    ScopeNode newNode;
    newNode.back = curNode;
    curNode = &newNode;
    cout<<"更新后{"<<&newNode<<endl;
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACE","{");
    #else
        return LBRACE;
    #endif
}
{RBRACE} {
    /*nowscope--;*/
    /*这里的逻辑是: 只要遇到}就回溯到上一个节点*/
    cout<<"未更新}"<<curNode<<endl;
    curNode=curNode->back;
    cout<<"更新后}"<<curNode<<endl;
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACE","}");
    #else
        return RBRACE;
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


{ID} {
    /*NODE:这里的逻辑如下:
    * 1. 判断是否存在该变量:先遍历该符号表中当前作用域的符号;再遍历该符号表中全局变量作用域中的符号
    * 2. 加入变量
    */  
    bool flag = true;
    unordered_map<string,SymTab> nowTab;
    nowTab = curNode->ScopeTab;
    if(nowTab.find(yytext)!=nowTab.end()){
        cout<<"局部我找到了"<<endl;
        cout<<&(nowTab.find(yytext)->second)<<endl;
        flag = false;
    }
    if(flag){
        nowTab = gloNode.ScopeTab;
        if(nowTab.find(yytext)!=nowTab.end()){
            cout<<"全局我找到了"<<endl;
            cout<<&(nowTab.find(yytext)->second)<<endl;
            flag = false;
        }
    }
    
    if(flag){
        cout<<"我要加了"<<endl;
        unordered_map<string,SymTab>* table = &(curNode->ScopeTab);
        SymTab newID;
        newID.row = yylineno;
        newID.col = column;
        newID.name = yytext;
        table->insert(pair<string,SymTab>(yytext, newID));
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
    cout<<std::setw(10)<<"token"<<std::setw(10)<<"lexeme"<<std::setw(10)<<"lineno"<<std::setw(10)<<"offset"<<std::setw(20)<<"pointer_to_scope"<<std::endl;
    yylex();
    return 0;
}
#endif
