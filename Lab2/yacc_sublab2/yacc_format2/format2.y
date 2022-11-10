%{
/****************************************************************************
format2.y
YACC file: 使用C++进行简单的中缀表达式向后缀表达式进行转化
Date: 2022/10/9
Meng Xiaoduo <2010349@nbjl.nankai.edu.cn>
****************************************************************************/
#include <iostream>
#include <cctype>
#include <string.h>
#include <stdio.h>//printf和FILE要用的  
using namespace std;
#ifndef YYSTYPE
#define YYSTYPE string
#endif
string numStr;
string idStr;
int yylex ();
int isdigit(int);
int isIdStr(int);
extern int yyparse();
FILE* yyin ;
void yyerror(const char* s);
%}

%token T_NUMBER
%token T_ID
%token T_ADD
%token T_MINUS
%token T_MULTIPLY
%token T_DIVIDE
%token T_LEFT
%token T_RIGHT
%left T_ADD T_MINUS
%left T_MULTIPLY T_DIVIDE
%right UMINUS

%%

// 由于要实现忽略对应的换行符, 这里用;来进行替代
lines   :   lines expr ';' { cout<<$2<<endl; }
        |   lines ';'
        |
        ;

expr    :   expr T_ADD expr { $$ = $1; $$ += $3; $$ += "+ "; }
        |   expr T_MINUS expr { $$ = $1; $$ += $3; $$ += "- "; }
        |   expr T_MULTIPLY expr { $$ = $1; $$ += $3; $$ += "* "; }
        |   expr T_DIVIDE expr { $$ = $1; $$ += $3; $$ += "/ "; }
        |   T_LEFT expr T_RIGHT { $$ = $2; }
        |   T_MINUS expr %prec UMINUS { $$ = "-"; $$ += $2; $$ += " "; }
        |   T_NUMBER { $$ = $1; $$ += " "; }
        |   T_ID { $$ = $1; $$ += " "; }
        ;

%%

 // programs section

int yylex()
{
    int t; 
    //注: 这里为什么要声明为整型呢?
    //在yacc中声明的token都会有一个互不冲突的整数值, 不需要在yacc中进行对token赋值一个整数这种显示的宏定义,只需要声明即可
    while(1){
        t = fgetc(yyin);
        //1. 对空格和制表符换行符的处理
        if ( t == ' ' || t == '\t' || t == '\n' ){
            //不做处理
        }
        //2. 对数字的处理
        //默认数字是在一行的, 数字中间不能有空格换行符制表符
        else if(isdigit(t)){
            numStr.clear();
            while(isdigit(t)){
                numStr += (char)t;
                t = fgetc(yyin);
            }
            yylval = numStr;
            ungetc(t,yyin); 
            return T_NUMBER;
        }
        //3. 对ID进行处理
        else if(isIdStr(t)){
            idStr.clear();
            while(isIdStr(t)||isdigit(t)){
                idStr += (char)t;
                t = fgetc(yyin);
            }
            yylval = idStr;
            ungetc(t,yyin);
            return T_ID;
        }
        //4. 对四则运算符号的处理
        else{
            switch(t){
                case '+':return T_ADD;
                case '-':return T_MINUS;
                case '*':return T_MULTIPLY;
                case '/':return T_DIVIDE;
                case '(':return T_LEFT;
                case ')':return T_RIGHT;
                default: return t;
            }
        }
    }
}

int main(int argc,char **argv)
{
    if(argc>1){
        yyin=fopen(argv[1],"r");
        char ch;//缓存数组
        while((ch=fgetc(yyin))!=EOF)//如果读入的字符没有不是文件结束符
        {
            putchar(ch);//打印这个字符到显示屏上面
        }
        rewind(yyin);
        do {
            yyparse();
        } while (fgetc(yyin)!=EOF);
    }
    else{
        yyin = stdin;
        do {
            yyparse();
        } while (!feof (yyin));
    }
    return 0;
}
void yyerror(const char* s) {
    fprintf (stderr , "Parse error : %s\n", s );
    exit (1);
}

int isdigit(int t){
    int num = t - '0';
    if(num >= 0 || num <= 9){
        return 1;
    }
    return 0;
}

int isIdStr(int t){
    if(t >= 'a' && t <= 'z'){
        return 1;
    }else if(t >= 'A' && t <= 'Z'){
        return 1;
    }else if(t == '_'){
        return 1;
    }else{
        return 0;
    }
}