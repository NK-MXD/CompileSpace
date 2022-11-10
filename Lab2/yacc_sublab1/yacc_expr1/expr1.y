%{
/****************************************************************************
expr1.y
YACC file: 最简单的程序: 只能处理简单的四则运算, 不能处理空格等特殊符号, 不能处理多位整数
Date: 2022/10/9
Meng Xiaoduo <2010349@nbjl.nankai.edu.cn>
****************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#ifndef YYSTYPE
#define YYSTYPE double
#endif
int yylex ();
extern int yyparse();
FILE* yyin;
void yyerror(const char* s);
%}

%left '+' '-'
%left '*' '/'
%right UMINUS

%%


lines   :   lines expr '\n' { printf("%f\n", $2); }
        |   lines '\n'
        |
        ;

expr    :   expr '+' expr { $$ = $1 + $3; }
        |   expr '-' expr { $$ = $1 - $3; }
        |   expr '*' expr { $$ = $1 * $3; }
        |   expr '/' expr 
                {   if($3==0.0)
                        yyerror("divided by zero.");
                    else
                        $$ = $1 / $3;
                }
        |   '(' expr ')' { $$ = $2; }
        |   '-' expr %prec UMINUS { $$ = -$2; }
        |   NUMBER
        ;

NUMBER  :   '0' { $$ = 0.0; }
        |   '1' { $$ = 1.0; }
        |   '2' { $$ = 2.0; }
        |   '3' { $$ = 3.0; }
        |   '4' { $$ = 4.0; }
        |   '5' { $$ = 5.0; }
        |   '6' { $$ = 6.0; }
        |   '7' { $$ = 7.0; }
        |   '8' { $$ = 8.0; }
        |   '9' { $$ = 9.0; }
        ;

%%

 // programs section

int yylex()
{
    // place your token retrieving code here
    return fgetc(yyin);
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
    }else{
        yyin = stdin;
    }
    do {
        yyparse();
    } while (!feof (yyin));
    // } while (fgetc(yyin)!=EOF);
    return 0;
}
void yyerror(const char* s) {
    fprintf (stderr , "Parse error : %s\n", s );
    exit (1);
}