%option noyywrap
%{
    /*
    * You will need to comment this line in lab5.
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
    #include <ostream>
    #include <fstream>
    #include <vector>

    using namespace std;
    extern FILE *yyin; 
    extern FILE *yyout;

    struct SymTab{
        string name;
        int scope;
        int row;
        int col;
        unsigned long int addr;
    };
    /*QUES:用一个简单的数组来表示感觉会不太够,考虑更好地数据结构*/
    SymTab symTab[10][10];
    /*QUES:用一个数组来实现?浪费?不确定变量层数*/
    int frameSize[10];
    int stackIdx = 0;
    int stackAddr = 0;
    /*QUES:识别的整数浮点数正则表达式考虑偏移量了吗?*/
    int offsets = 0;
    /*QUES:这个的逻辑不是很清楚*/
    vector<int> globalFrame;

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
    #endif
%}

DECIMAL_FLOAT ((([0-9]*[.][0-9]*([eE][+-]?[0-9]+)?)|([0-9]+[eE][+-]?[0-9]+))[fLlL]?)
HEXADECIMAL_FLOAT (0[xX](([0-9A-Fa-f]*[.][0-9A-Fa-f]*([pP][+-]?[0-9]+)?)|([0-9A-Fa-f]+[pP][+-]?[0-9]+))[fLlL]?)

DECIMIAL ([1-9][0-9]*|0)
OCTAL (0[0-7]+)
HEXADECIMAL (0[x|X][0-9A-Fa-f]+)
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
        DEBUG_FOR_LAB4("SUB\t\t-");
        offsets += strlen("-");
    #else
        return SUB;
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
        stackAddr = 0;
    #else
        return LBRACE;
    #endif
}
"}" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACE\t\t}");
        offsets += strlen("}");
        // 栈帧底部
        int bottom = globalFrame.front();
        stackAddr = (frameSize[bottom] - 1) >= 0 ? (frameSize[bottom] - 1): 0;
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
        DEBUG_FOR_LAB4(string("DECIMAL_FLOAT\t\t") + to_string(temp));
        offsets += strlen(yytext);
    #else
        return DECIMAL_FLOAT;
    #endif  
}

{HEXADECIMAL_FLOAT} {
    #ifdef ONLY_FOR_LEX
        float temp;
        sscanf(yytext, "%f", &temp);
        DEBUG_FOR_LAB4(string("HEXADECIMAL_FLOAT\t\t") + to_string(temp));
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
        DEBUG_FOR_LAB4(string("HEXADECIMAL\t\t") + to_string(temp));
        offsets += strlen(yytext);
    #else
        return HEXADECIMAL;
    #endif
}


<*>{EOL} {
    /*QUES:这里的<*>是为什么考虑呢?*/
    /*NODE:注释内部换行加行数*/
    offsets += strlen(yytext);
    yylineno++;
    offsets = 0;
}

{WHITE} {offsets += strlen(yytext);}
{LINECOMMENT} {}
{BLOCKCOMMENTBEGIN} {BEGIN BLOCKCOMMENT;}
<BLOCKCOMMENT>{BLOCKCOMMENTELEMENT} {}
<BLOCKCOMMENT>{BLOCKCOMMENTEND} {BEGIN INITIAL;}

{ID} {
    /*NODE:思路是每一个花括号内都有一个作用域,但是如果使用的是上一个作用域的变量呢?*/
    bool flag = false;
    // int size = globalFrame.size()-1;
    // int frameIdx;
    // while(!globalFrame.empty()&& size>=0){
    //     frameIdx = globalFrame[size];
    //     for(int i=0;i<frameSize[frameIdx];i++){
    //         // 如果查找到
    //         if(symTab[frameIdx][i].name == string(yytext)){
    //             DEBUG_FOR_LAB4(string("ID\t") + string(yytext), &(symTab[frameIdx][i]));
    //             flag = true;
    //             break;
    //         }
    //     }
    //     if(flag){
    //         break;
    //     }
    //     size--;
    // }
    for(int i=0;i<frameSize[stackIdx];i++){
        // 如果查找到（此处已限制在当前作用域）
        if(symTab[stackIdx][i].name == string(yytext)){
            DEBUG_FOR_LAB4(string("ID\t\t") + string(yytext), (symTab[stackIdx][i]));
            flag = true;
            break;
        }
    }
    // 当前作用域不存在则检查全局作用域
    if(!flag){
        for(int i=0;i<frameSize[0];i++){
            // 如果查找到
            if(symTab[0][i].name == string(yytext)){
                DEBUG_FOR_LAB4(string("ID\t\t") + string(yytext), (symTab[0][i]));
                flag = true;
                break;
            }
        }
        int frameIdx = globalFrame.size();
        // 若仍不存在则新建变量
        if(!flag){
            symTab[frameIdx][stackAddr].name = string(yytext);
            symTab[frameIdx][stackAddr].row=yylineno;
            symTab[frameIdx][stackAddr].col=offsets;
            symTab[frameIdx][stackAddr].scope=frameIdx;
            symTab[frameIdx][stackAddr].addr=(long unsigned int)&(symTab[frameIdx][stackAddr]);
            DEBUG_FOR_LAB4(string("ID\t\t") + string(yytext),symTab[frameIdx][stackAddr]);
        }
    }
}

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
    // cout<<std::setw(10)<<"token"<<std::setw(10)<<"lexeme"<<std::setw(10)<<"lineno"<<std::setw(10)<<"offset"<<std::setw(10)<<"scope"<<std::setw(20)<<"pointer_to_scope"<<std::endl;
    yylex();
    return 0;
}
#endif
