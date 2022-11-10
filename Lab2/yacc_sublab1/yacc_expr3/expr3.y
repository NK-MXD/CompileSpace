%{
/****************************************************************************
expr3.y
YACC file: 设立符号表, 转化为C++代码, 进行赋值运算符Yacc程序编写 注: makefile测试中存在的问题, 文件读取的缓存问题
Date: 2022/10/11
Meng Xiaoduo <2010349@nbjl.nankai.edu.cn>
****************************************************************************/
#include <stdio.h>
#include <math.h>
#include <iostream>
#include <string.h>
#include <map> //建立符号表, 本文中建立的符号表较为简单, 仅包含对应标识符的值一个属性
using namespace std;
int yylex ();
int isdigit(int);
int isIdStr(int);
extern int yyparse();
FILE* yyin ;
void yyerror(const char* s);

char idStr[50];//标识符
map<string, double> T_Table;//建立符号表
%}

%union {
	double d_val;
	char* s_val;
}

//需要将yylval定义两种类型的变量
%token<d_val> T_NUMBER
%token<s_val> T_ID
%token T_EQUAL
%token T_ADD
%token T_MINUS
%token T_MULTIPLY
%token T_DIVIDE
%token T_LEFT
%token T_RIGHT

%right T_EQUAL
%left T_ADD T_MINUS
%left T_MULTIPLY T_DIVIDE
%right UMINUS

//实现符号表要声明对应的表达式的类型
%type<d_val> expr

%%

statement_list: statement ';'
        |       statement_list statement ';'
statement:      T_ID T_EQUAL expr { T_Table[$1] = $3; }
        |       expr              { cout<<" = "<<$1<<endl; }
        ;


expr    :   expr T_ADD expr { $$ = $1 + $3; }
        |   expr T_MINUS expr { $$ = $1 - $3; }
        |   expr T_MULTIPLY expr { $$ = $1 * $3; }
        |   expr T_DIVIDE expr 
                {   if($3==0.0)
                        yyerror("divided by zero.");
                    else
                        $$ = $1 / $3;
                }
        |   T_LEFT expr T_RIGHT { $$ = $2; }
        |   T_MINUS expr %prec UMINUS { $$ = -$2; }
        |   T_NUMBER { $$ = $1; }
        |   T_ID { $$ = T_Table[$1]; }
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
            yylval.d_val = 0;
            while(isdigit(t)){
                yylval.d_val = (int)yylval.d_val * 10 + t - '0';
                t = fgetc(yyin);
            }
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
            yylval.s_val = (char*)malloc(50*sizeof(char)); 
            strcpy(yylval.s_val,idStr);
            ungetc(t,yyin);
            return T_ID;
        }
        //4. 对运算符号的处理
        else{
            switch(t){
                case '+':return T_ADD;
                case '-':return T_MINUS;
                case '*':return T_MULTIPLY;
                case '/':return T_DIVIDE;
                case '(':return T_LEFT;
                case ')':return T_RIGHT;
                case '=':return T_EQUAL;
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