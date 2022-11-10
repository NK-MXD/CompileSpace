%option noyywrap
%{
    /*
    * You will need to comment this line in lab5.
    */
    // #define ONLY_FOR_LEX
    
    #ifdef ONLY_FOR_LEX
    #else
    #define YYSTYPE void *
    #include "parser.h"
    #endif

    #define YY_NO_UNPUT
    #define YY_NO_INPUT
    #include <string>

    #ifdef ONLY_FOR_LEX
    #include <ostream>
    #include <fstream>
    #include <vector>

    using namespace std;
    extern FILE *yyin; 
    extern FILE *yyout;
    extern bool dump_tokens;

    int offsets = 0;

    struct SymTab{
        char ident[80];
        int scope;
        int row;
        int col;
        unsigned long int addr;
    }symTab[80][80];

    vector<int> globalFrame;
    int frameSize[30];
    int currentFrame = 0;

    void DEBUG_FOR_LAB4(std::string s, SymTab symt){
        string DEBUG_INFO;
        char temp[20];
        sprintf(temp, "0x%lx", symt.addr);
        DEBUG_INFO = "[DEBUG LAB4]: \t" + s + "\t\t" + to_string(yylineno) + "\t\t"+ to_string(offsets) + "\t\t" +to_string(symt.scope)+"\t\t"+string(temp) + "\n";
        fputs(DEBUG_INFO.c_str(), yyout);
    }
    void DEBUG_FOR_LAB4(std::string s){
        string DEBUG_INFO;
        DEBUG_INFO = "[DEBUG LAB4]: \t" + s + "\t\t" + to_string(yylineno) + "\t\t" + to_string(offsets) + "\n";
        fputs(DEBUG_INFO.c_str(), yyout);
    }
    
    int stackIdx = 0;
    int stackAddr = 0;
    #endif
%}


DECIMIAL ([1-9][0-9]*|0)
OCTAL (0[0-7]+)
HEXADECIMAL (0[x|X][0-9A-Fa-f]+)

DECIMAL_FLOAT ((([0-9]*[.][0-9]*([eE][+-]?[0-9]+)?)|([0-9]+[eE][+-]?[0-9]+))[fLlL]?)
HEXADECIMAL_FLOAT (0[xX](([0-9A-Fa-f]*[.][0-9A-Fa-f]*([pP][+-]?[0-9]+)?)|([0-9A-Fa-f]+[pP][+-]?[0-9]+))[fLlL]?)

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
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("INT\t\tint");
        offsets += strlen("int");
    #else
        return INT;
    #endif
}
"float" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("FLOAT\t\tfloat");
        offsets += strlen("float");
    #else
        return FLOAT;
    #endif
}
"void" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("VOID\t\tvoid");
        offsets += strlen("void");
    #else
        return VOID;
    #endif 
}
"const" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("CONST\t\tconst");
        offsets += strlen("const");
    #else
        return CONST;
    #endif 
}
"if" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("IF\t\tif");
        offsets += strlen("if");
    #else
        return IF;
    #endif
}
"else" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("ELSE\t\telse");
        offsets += strlen("else");
    #else
        return ELSE;
    #endif
}
"return" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RETURN\t\treturn");
        offsets += strlen("return");
    #else
        return RETURN;
    #endif
}
"while" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("WHILE\t\twhile");
        offsets += strlen("while");
    #else
        return WHILE;
    #endif
}
"for" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("FOR\t\tfor");
        offsets += strlen("for");
    #else
        return FOR;
    #endif
}
"do" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("DO\t\tdo");
        offsets += strlen("do");
    #else
        return DO;
    #endif
}
"break" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("BREAK\t\tbreak");
        offsets += strlen("break");
    #else
        return BREAK;
    #endif
}
"continue" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("CONTINUE\t\tcontinue");
        offsets += strlen("continue");
    #else
        return CONTINUE;
    #endif
}
"==" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("EQUAL\t\t==");
        offsets += strlen("==");
    #else
        return EQUAL;
    #endif
}
"!=" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("NOTEQUAL\t\t!=");
        offsets += strlen("!=");
    #else
        return NOTEQUAL;
    #endif
}
"=" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("ASSIGN\t\t=");
        offsets += strlen("=");
    #else
        return ASSIGN;
    #endif
}
"<=" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LESSEQUAL\t\t<=");
        offsets += strlen("<=");
    #else
        return LESSEQUAL;
    #endif
}
">=" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("GREATEREQUAL\t\t<=");
        offsets += strlen(">=");
    #else
        return GREATEREQUAL;
    #endif
}
"<" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LESS\t\t<");
        offsets += strlen("<");
    #else
        return LESS;
    #endif
}
">" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("GREATER\t\t>");
        offsets += strlen(">");
    #else
        return GREATER;
    #endif
}
"+" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("ADD\t\t+");
        offsets += strlen("+");
    #else
        return ADD;
    #endif
}
"-" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MINUS\t\t-");
        offsets += strlen("-");
    #else
        return MINUS;
    #endif
}
"*" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MUL\t\t*");
        offsets += strlen("*");
    #else
        return MUL;
    #endif
}
"/" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("DIV\t\t/");
        offsets += strlen("/");
    #else
        return DIV;
    #endif
}
"%" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("MOD\t\t%");
        offsets += strlen("%");
    #else
        return MOD;
    #endif
}
"&&" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("AND\t\t&&");
        offsets += strlen("&&");
    #else
        return AND;
    #endif
}
"||" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("OR\t\t||");
        offsets += strlen("||");
    #else
        return OR;
    #endif
}
"!" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("NOT\t\t!");
        offsets += strlen("!");
    #else
        return NOT;
    #endif
}
";" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("SEMICOLON\t;");
        offsets += strlen(";");
    #else
        return SEMICOLON;
    #endif
}
"(" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LPAREN\t\t(");
        offsets += strlen("(");
    #else
        return LPAREN;
    #endif
}
")" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RPAREN\t\t)");
        offsets += strlen(")");
    #else
    return RPAREN;
    #endif
}
"{" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACE\t\t{");
        offsets += strlen("{");
        frameSize[stackIdx] = stackAddr + 1;
        globalFrame.push_back(++stackIdx);
        currentFrame=stackIdx;
        stackAddr = 0;
    #else
        return LBRACE;
    #endif
}
"}" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACE\t\t}");
        offsets += strlen("}");
        // 切换作用域
        globalFrame.pop_back();
        currentFrame=globalFrame.back();
        int curAddr = frameSize[currentFrame];
        stackAddr = max(curAddr-1,0);
    #else
        return RBRACE;
    #endif
}
"[" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACKET\t\t[");
        offsets += strlen("[");
    #else
        return LBRACKET;
    #endif
}
"]" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACKET\t\t]");
        offsets += strlen("]");
    #else
        return RBRACKET;
    #endif
}
"," {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("COMMA\t\t,");
        offsets += strlen(",");
    #else
        return COMMA;
    #endif
}

{DECIMAL_FLOAT} {
    #ifdef ONLY_FOR_LEX
        float temp;
        sscanf(yytext, "%f", &temp);
        DEBUG_FOR_LAB4(string("DECIMAL_FLOAT\t") + to_string(temp));
        offsets += strlen(yytext);
    #else
        return DECIMAL_FLOAT;
    #endif  
}

{HEXADECIMAL_FLOAT} {
    #ifdef ONLY_FOR_LEX
        float temp;
        sscanf(yytext, "%f", &temp);
        DEBUG_FOR_LAB4(string("HEXADECIMAL_FLOAT\t") + to_string(temp));
        offsets += strlen(yytext);
    #else
        return DECIMAL_FLOAT;
    #endif  
}

{DECIMIAL} {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4(string("DECIMIAL\t\t") + string(yytext));
        offsets += strlen(yytext);
    #else
        return DECIMIAL;
    #endif
}

{OCTAL} {
    #ifdef ONLY_FOR_LEX
        int temp;
        sscanf(yytext, "%o", &temp);
        DEBUG_FOR_LAB4(string("OCTAL\t\t") + to_string(temp));
        offsets += strlen(yytext);
    #else
        return OCTAL;
    #endif
}

{HEXADECIMAL} {
    #ifdef ONLY_FOR_LEX
        int temp;
        sscanf(yytext, "%x", &temp);
        DEBUG_FOR_LAB4(string("HEXADECIMAL\t") + to_string(temp));
        offsets += strlen(yytext);
    #else
        return HEXADECIMAL;
    #endif
}


<*>{EOL} {
    offsets += strlen(yytext);
    yylineno++;
    offsets = 0;
}


{ID} {
    if(dump_tokens)
        DEBUG_FOR_LAB4(yytext);
    char *lexeme;
    lexeme = new char[strlen(yytext) + 1];
    strcpy(lexeme, yytext);
    yylval.strtype = lexeme;
    offsets += strlen(yytext);
    return ID;
}


{WHITE} {offsets += strlen(yytext);}
{LINECOMMENT} {}
{BLOCKCOMMENTBEGIN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{BLOCKCOMMENTELEMENT} {}
<BLOCKCOMMENT>{BLOCKCOMMENTEND} {BEGIN INITIAL;}

%%

#ifdef ONLY_FOR_LEX
int main(int argc, char **argv){
    if(argc != 5){
        fprintf(stderr, "Argument Not Enough");
        exit(EXIT_FAILURE);
    }

    if(!(yyin = fopen(argv[1], "r"))){
        fprintf(stderr, "No such file or directory: %s", argv[1]);
        exit(EXIT_FAILURE);
    }

    if(!(yyout = fopen(argv[3], "w"))){
        fprintf(stderr, "No such file or directory: %s", argv[3]);
        exit(EXIT_FAILURE);
    }
    string title="[DEBUG LAB4]:\tToken\t\tLexeme\t\tLineno\t\tOffset\t\tScope\t\tAddr\n";
    fputs(title.c_str(), yyout);
    yylex();
    return 0;
}
#endif
