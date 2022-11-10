%{
/****************************************************************************
format1.y
YACC file: 进行简单的中缀表达式向后缀表达式进行转化
Date: 2022/10/9
Meng Xiaoduo <2010349@nbjl.nankai.edu.cn>
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef YYSTYPE
#define YYSTYPE char*
#endif
char idStr[50];
char numStr[50];
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
lines   :   lines expr ';' { printf("%s\n", $2); }
        |   lines ';'
        |
        ;

expr    :   expr T_ADD expr { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$1); strcat($$,$3); strcat($$,"+ "); }
        |   expr T_MINUS expr { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$1); strcat($$,$3); strcat($$,"- "); }
        |   expr T_MULTIPLY expr { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$1); strcat($$,$3); strcat($$,"* "); }
        |   expr T_DIVIDE expr { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$1); strcat($$,$3); strcat($$,"/ "); }
        |   T_LEFT expr T_RIGHT { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$2); }
        |   T_MINUS expr %prec UMINUS { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,"-"); strcat($$,$2); strcat($$," "); }
        |   T_NUMBER { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$1); strcat($$," "); }
        |   T_ID { $$ = (char*)malloc(50*sizeof(char)); strcpy($$,$1); strcat($$," "); }
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
            int num = 0;
            while(isdigit(t)){
                numStr[num] = t;
                t = fgetc(yyin);
                num++;
            }
            numStr[num] = '\0';
            yylval = numStr;
            ungetc(t,yyin);
            return T_NUMBER;
        }
        //3. 对ID进行处理
        else if(isIdStr(t)){
            int id = 0;
            while(isIdStr(t)||isdigit(t)){
                idStr[id] = t;
                t = fgetc(yyin);
                id++;
            }
            idStr[id] = '\0';
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