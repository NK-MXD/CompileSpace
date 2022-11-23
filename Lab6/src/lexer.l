%option noyywrap
%option yylineno 
%{
    #define YY_NO_UNPUT
    #define YY_NO_INPUT

    #include "parser.h"
    #include <ostream>
    #include <fstream>
    using namespace std;
    int offsets = 0;
    int newoffsets = 0;
    extern FILE *yyin; 
    extern FILE *yyout;
    extern bool dump_tokens;

    void update_loc(){
        offsets = newoffsets;
        newoffsets = offsets + strlen(yytext);
    }

    void DEBUG_FOR_LAB4(std::string s){
        string DEBUG_INFO;
        DEBUG_INFO = "[DEBUG LAB4]: \t" + s + "\t\t" + to_string(yylineno) + "\t\t" + to_string(offsets) + "\n";
        fputs(DEBUG_INFO.c_str(), yyout);
    }
    #define YY_USER_ACTION update_loc();  
%}

OCTAL (0[0-7]+)
HEXADECIMAL (0[x|X][0-9A-Fa-f]+)

DECIMAL_FLOAT ((([0-9]*[.][0-9]*([eE][+-]?[0-9]+)?)|([0-9]+[eE][+-]?[0-9]+))[fLlL]?)
HEXADECIMAL_FLOAT (0[xX](([0-9A-Fa-f]*[.][0-9A-Fa-f]*([pP][+-]?[0-9]+)?)|([0-9A-Fa-f]+[pP][+-]?[0-9]+))[fLlL]?)

DECIMIAL ([1-9][0-9]*|0)
ID [[:alpha:]_][[:alpha:][:digit:]_]*
EOL (\r\n|\n|\r)
WHITE [\t ]
BLOCKCOMMENTBEGIN \/\*
BLOCKCOMMENTELEMENT .
BLOCKCOMMENTEND \*\/
%x BLOCKCOMMENT
LINECOMMENT \/\/[^\n]*

%%

"int" {
    /*
    * Questions: 
    *   Q1: Why we need to return INT in further labs?
    *   Q2: What is "INT" actually?
    */
    if(dump_tokens)
        DEBUG_FOR_LAB4("INT\tint");
    // printf("%s\n",yytext);
    return INT;
}
"float" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("INT\tfloat");
    // printf("%s\n",yytext);
    return FLOAT;
}
"void" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("VOID\tvoid");
    // printf("%s\n",yytext);
    return VOID;
}
"const" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("VOID\tvoid");
    return CONST;
}
"if" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("IF\tif");
    return IF;
};
"else" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("ELSE\telse");
    return ELSE;
};
"return" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RETURN\treturn");
    return RETURN;
}
"while" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RETURN\twhile");
    return WHILE;
}
"for" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RETURN\twhile");
    return FOR;
}
"do" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RETURN\twhile");
    return DO;
}
"break" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RETURN\twhile");
    return BREAK;
}
"continue" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RETURN\twhile");
    return CONTINUE;
}
"==" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("EQUAL\t\t==");
    return EQUAL;
}
"!=" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("NOTEQUAL\t\t!=");
    return NOTEQUAL;
}
"<=" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("LESSEQUAL\t\t<=");
    return LESSEQUAL;
}
">=" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("GREATEREQUAL\t\t<=");
    return GREATEREQUAL;
}

"=" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("ASSIGN\t=");
    return ASSIGN;
}
"<" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("LESS\t<");
    return LESS;
}
">" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("GREATER\t\t>");
    return GREATER;
}
"+" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("ADD\t+");
    return ADD;
}
"-" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("MINUS\t\t-");
    return SUB;
}
"*" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("MUL\t\t*");
    return MUL;
}
"/" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("DIV\t\t/");
    return DIV;
}
"%" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("MOD\t\t%");
    return MOD;
}
"&&" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("AND\t\t&&");
    return AND;
}
"||" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("OR\t\t||");
    return OR;
}
"!" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("NOT\t\t!");
    return NOT;
}
";" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("SEMICOLON\t;");
    return SEMICOLON;
}
"(" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("LPAREN\t(");
    return LPAREN;
}
")" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RPAREN\t)");
    return RPAREN;
}
"{" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("LBRACE\t{");
    return LBRACE;
}
"}" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RBRACE\t}");
    return RBRACE;
}
"[" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("LBRACKET\t\t[");
    return LBRACKET;
}
"]" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("RBRACKET\t\t]");

    return RBRACKET;
}
"," {
    if(dump_tokens)
        DEBUG_FOR_LAB4("COMMA\t\t,");
    return COMMA;
}

{DECIMIAL} {
    if(dump_tokens)
        DEBUG_FOR_LAB4(yytext);
    yylval.itype = atoi(yytext);
    return INTEGER;
}

{DECIMAL_FLOAT} {
    if(dump_tokens)
        DEBUG_FOR_LAB4("DECIMAL_FLOAT\t");
    yylval.ftype = atof(yytext);
    return DECIMAL_FLOAT;
}

{HEXADECIMAL_FLOAT} {
    if(dump_tokens)
        DEBUG_FOR_LAB4("HEXADECIMAL_FLOAT\t");
    yylval.ftype = atof(yytext);
    
    return HEXADECIMAL_FLOAT;
}

{OCTAL} {
    int temp;
    sscanf(yytext, "%o", &temp);
    yylval.itype = temp;
    if(dump_tokens)
        DEBUG_FOR_LAB4(string("OCTAL\t\t") + to_string(temp));
    return OCTAL;
}

{HEXADECIMAL} {
    int temp;
    sscanf(yytext, "%x", &temp);
    yylval.itype = temp;
    if(dump_tokens)
        DEBUG_FOR_LAB4(string("HEXADECIMAL\t") + to_string(temp));
    
    return HEXADECIMAL;
}

"getint" {
    /*m1101: 考虑yacc改写, 函数*/
    if(dump_tokens)
        DEBUG_FOR_LAB4("GETINT\tgetint");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return GETINT;
}

"getch" {
    /*m1101: 考虑yacc改写, 函数*/
    if(dump_tokens)
        DEBUG_FOR_LAB4("GETCHAR\tgetch");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return GETCH;
}

"getfloat" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("GETFLOAT\tgetfloat");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return GETFLOAT;
}

"getarray" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("GETARRAY\tgetarray");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return GETARRAY;
}

"getfarray" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("GETARRAY\tgetarray");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return GETFARRAY;
}

"putint" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("PUTINT\tputint");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return PUTINT;
}

"putch" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("PUTINT\tputch");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return PUTCH;
}

"putfloat" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("PUTFLOAT\tputfloat");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return PUTFLOAT;
}

"putarray" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("PUTARRAY\tputarray");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return PUTARRAY;
}

"putfarray" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("PUTFARRAY\tputfarray");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return PUTFARRAY;
}

"putf" {
    if(dump_tokens)
        DEBUG_FOR_LAB4("PUTF\tputf");
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return PUTF;
}

<*>{EOL} {}


{ID} {
    if(dump_tokens)
        DEBUG_FOR_LAB4(yytext);
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    return ID;
}

{WHITE} {}
{LINECOMMENT} {}
{BLOCKCOMMENTBEGIN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{BLOCKCOMMENTELEMENT} {}
<BLOCKCOMMENT>{BLOCKCOMMENTEND} {BEGIN INITIAL;}

%%
