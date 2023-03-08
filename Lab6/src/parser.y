%code top{
    #include "parser.h"
    extern Ast ast;
    int yylex();
    int yyerror( char const * );
    bool check_on = 0;
    extern int yylineno;
    extern int offsets;
}

%code requires {
    #include "Ast.h"
    #include "SymbolTable.h"
    #include "Type.h"
}

%union {
    int itype;
    char* strtype;
    float ftype; 
    StmtNode* stmttype;
    ExprNode* exprtype;
    Type* type;
}

%start Program
%token <strtype> ID GETINT GETFLOAT GETARRAY PUTINT PUTFLOAT PUTARRAY PUTFARRAY GETCH GETFARRAY PUTCH PUTF
%token <itype> INTEGER OCTAL HEXADECIMAL
%token <ftype> DECIMAL_FLOAT HEXADECIMAL_FLOAT
%token IF ELSE WHILE FOR DO BREAK CONTINUE
%token INT VOID FLOAT
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON LBRACKET RBRACKET COMMA
%token AND OR
%token EQUAL NOTEQUAL LESSEQUAL GREATEREQUAL
%token ADD SUB LESS ASSIGN GREATER
%token MUL DIV MOD
%token PLUS UMINUS NOT
%token CONST
%token RETURN


%nterm <stmttype> Stmts Stmt BlockStmt IfStmt ReturnStmt  FuncDef 
%nterm <exprtype> Exp AddExp Cond LOrExp PrimaryExp LVal RelExp LAndExp ConstExp CastExp AssignExp

/* new */
%nterm <exprtype>  FuncCall FuncRParam ArrayIndices UnaryExp MulExp EqExp ConstExpInitList ArrAssignExp ArrayIndex 
%nterm <stmttype> InitStmt DeclInitStmt ConstDeclInitStmt FuncFParam FuncFParamList WhileStmt BreakStmt ContinueStmt ExprStmt FuncDecl FuncHead ArrInit

%nterm <type> Type
%precedence THEN
%precedence ELSE
%%
Program
    : Stmts {
        ast.setRoot($1);
    }
    ;
Stmts
    : Stmt {$$=$1;}
    | Stmts Stmt{
        $$ = new SeqNode($1, $2);
    }
    ;
Stmt
    :
    // : AssignStmt {$$=$1;}
    BlockStmt {$$=$1;}
    | IfStmt {$$=$1;}
    | ReturnStmt {$$=$1;}
    //| DeclStmt {$$=(DeclStmt*)$1;}
    | FuncDef {$$=$1;}
    | DeclInitStmt{$$=$1;}
    //| FuncStmt {$$=$1;}
    | WhileStmt {$$=$1;}
    | BreakStmt {$$=$1;}
    | ContinueStmt {$$=$1;}
    /*for eg. print();  a+1;*/
    | ExprStmt{$$=$1;}
    | FuncDecl{$$=$1;}
    | SEMICOLON{$$=new SpaceStmt();}
    //| %empty{$$=nullptr;}
    ;
ExprStmt
    : Exp SEMICOLON {
        $$ = new ExprStmt($1);
    }
    ;
/* z1103 新增数组切片 */
/* z1107 finished*/
ArrayIndices
    : LBRACKET Exp RBRACKET {
        // 检查下标是否为整数
        // if(!$2->getSymbolEntry()->isConstant()){
        //     fprintf(stderr, "ArrayIndices is not const\n");
        //     assert($2->getSymbolEntry()->isConstant());
        // }
        if($2->getSymbolEntry()->getType()!=TypeSystem::intType){
            if(check_on){
                fprintf(stderr, "ArrayIndices is not int\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert($2->getSymbolEntry()->getType()==TypeSystem::intType);
            }
        }
        $$ = $2;
    }
    | ArrayIndices LBRACKET Exp RBRACKET {
        // if(!$3->getSymbolEntry()->isConstant()){
        //     fprintf(stderr, "ArrayIndices is not const\n");
        //     assert($3->getSymbolEntry()->isConstant());
        // }
        if($3->getSymbolEntry()->getType()!=TypeSystem::intType){
            if(check_on){
                fprintf(stderr, "ArrayIndices is not int\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert($3->getSymbolEntry()->getType()==TypeSystem::intType);
            }
        }
        $$ = $1;
        $1->append($3);
    }
    ;
ArrayIndex
    : ArrayIndices {
        $$ = $1;
    }
    /* z1108 可能会有问题 */
    | LBRACKET RBRACKET{
        $$ = nullptr;
    }
    /* z1108 之后需要考虑到最低维缺省 */
    // | ArrayIndices LBRACKET RBRACKET
    ;
LVal
    : ID {
        SymbolEntry *se;
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            if(check_on){
                fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                delete [](char*)$1;
                assert(se != nullptr);
            }
        }
        $$ = new Id(se);
        delete []$1;
    }
    /*~有问题 还没解决数组-->维度确定，这里跟常值表达式挂钩~*/
    /*z1107 finished*/
    | ID ArrayIndices{
        SymbolEntry *se;
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            if(check_on){
                fprintf(stderr, "array identifier \"%s\" is undefined\n", (char*)$1);
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                delete [](char*)$1;
                assert(se != nullptr);
            }
        }
        // 暂且写为只有最低维元素可赋值
        int sliceCnt=0;
        ExprNode *tmp=$2;
        while(tmp!=nullptr){
            sliceCnt++;
            tmp=(ExprNode *)tmp->getNext();
        }
        Array * arrType = (Array *)se->getType();
        printinfo(arrType->getEleType()->toStr().c_str());
        if(sliceCnt!=arrType->getDimen()){
            if(check_on){
                fprintf(stderr, "Cannot assign an address!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert(sliceCnt==arrType->getDimen());
            }
        }
        $$ = new Id(se);
        /*m1122 数组: 需要将对应的元素取出来*/
        /*m1122 函数: 需要将对应的返回值返回*/
        // SymbolEntry* index = $2->getSymbolEntry();
        // if(index->isConstant()){
        //     ConstantSymbolEntry *cs = dynamic_cast<ConstantSymbolEntry*>index;
        // }
        // if(dynamic_cast<IdentifierSymbolEntry*>(se)->isConstant()){
        //     if(se->getType() == TypeSystem::intType){
        //         SymbolEntry *newse = new ConstantSymbolEntry(TypeSystem::intType, dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue());
        //     }
        //     else{
        //         SymbolEntry *newse = new ConstantSymbolEntry(TypeSystem::intType, dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue());
        //     }
        // }
        // else{

        // }
        delete []$1;
        // may detele $2
    }
    | FuncCall{
        $$ = $1;
    }
    ;

/* z1102 IdList */
/* z1108 reduce */

/* z1109 fix {},{}*/
ArrAssignExp
    : ConstExp{
        $$ = $1;
    }
    | LBRACE RBRACE {$$ = new ExprNode(new ConstantSymbolEntry());}

    | LBRACE ConstExpInitList RBRACE{
        $$ = $2;
    }
    ;

ConstExpInitList
    : ArrAssignExp{
        $$ = $1;
    }
    | ConstExpInitList COMMA ArrAssignExp{
        $$ = $1;
    }
    ;


/*z1107 数组初始化 重新处理*/
ArrInit
    : 
    ID ArrayIndices {
        SymbolEntry *se;
        se = nullptr;
        $$ =new InitStmt(new Id(se,$2,$1,true));
    }
    | 
    ID ArrayIndices ASSIGN ArrAssignExp{
        print("ID ArrayIndices ASSIGN ArrAssignExp");
        SymbolEntry *se;
        se=nullptr;
        $$ =new InitStmt(new Id(se,$2,$1,true),$4);
    }
    ;
InitStmt
// z1102
/* 连续赋值 */
    : ID ASSIGN Exp{
        SymbolEntry *se;
        se=nullptr;
        $$ =new InitStmt(new Id(se,$1),$3);

    }
    | InitStmt COMMA ID ASSIGN Exp{
        SymbolEntry *se;
        se=nullptr;
        $$->append(new InitStmt(new Id(se,$3),$5));
    }
    /*z1107 数组赋值 重新处理*/
    | ArrInit{
        $$ = (InitStmt*)$1;
    }

    | InitStmt COMMA ArrInit{
        // SymbolEntry *se;
        // se=nullptr;
        $$->append($3);
    }
    | InitStmt COMMA ID{
        SymbolEntry *se;
        se=nullptr;
        $$->append(new InitStmt(new Id(se,$3)));
    }
    | ID {
        printinfo("IdList-ID");
        SymbolEntry *se;
        se=nullptr;
        $$=new InitStmt(new Id(se,$1));
    }
    ;
// z1102
/*z1107 finish type&index check*/
ConstDeclInitStmt
    : CONST Type InitStmt SEMICOLON{
        InitStmt * initexp = (InitStmt *)$3;
        ExprNode *expr;
        Type *expType;
        Type *type = (Type *)$2;
        while(initexp!=nullptr){
            expr = initexp->getExp();
            if(initexp->getId()->getIsArray()){
                Array *arrType =new Array($2);
                ExprNode* index = initexp->getId()->getIndex();
                /*计算维度*/
                int dimen=0;
                while(index!=nullptr){
                    ConstantSymbolEntry* constEntry = (ConstantSymbolEntry*)index->getSymbolEntry();
                    if(!constEntry->isConstant()){
                        if(check_on){
                        fprintf(stderr,"ArrayDecl index is not const!\n");
                        fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                        assert(index->getSymbolEntry()->isConstant());
                        }
                    }
                    
                    if(constEntry->getIntValue()<=0){
                        if(check_on){
                        fprintf(stderr, "ArrayIndices is can not be negative or zero！\n");
                        fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                        assert(constEntry->getIntValue()>0);
                        }
                    }
                    /*z1107 补完常量维度*/
                    arrType->getLenVec().push_back(constEntry->getIntValue());
                    dimen++;
                    index=(ExprNode*)index->getNext();
                }
                if(dimen==0){
                    dimen=1;
                }
                arrType->setDimen(dimen);
                /*类型检查*/
                while(expr!=nullptr){
                    expType = expr->getSymbolEntry()->getType();
                    if(expType!=type){
                        if(check_on){
                        fprintf(stderr,"Type not match!\n");
                        fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                        assert(expType==type);
                        }
                    }

                    expr=(ExprNode *)expr->getNext();
                }
                initexp->getId()->getSymbolEntry() = new IdentifierSymbolEntry(arrType, initexp->getId()->getName(), identifiers->getLevel(),IdentSystem::constant);
            }

            else{
                initexp->getId()->getSymbolEntry() = new IdentifierSymbolEntry
                    ($2, initexp->getId()->getName(), identifiers->getLevel(),IdentSystem::constant);
                
            }
            identifiers->install(initexp->getId()->getName(), initexp->getId()->getSymbolEntry());
            print("init Name：")
            print(initexp->getId()->getName().c_str());
            initexp=(InitStmt*)(initexp->getNext());

        }
        $$ = new DeclInitStmt((InitStmt *)$3);
    }
    ;
/*z1107 finish type&index check*/
DeclInitStmt
    : Type InitStmt SEMICOLON{
        InitStmt * initexp = (InitStmt *)$2;
        ExprNode *expr;
        Type *expType;
        Type *type = (Type *)$1;
        while(initexp!=nullptr){
            expr = initexp->getExp();
            if(initexp->getId()->getIsArray()){
                
                Array *arrType =new Array($1);
                ExprNode* index = initexp->getId()->getIndex();
                /*计算维度*/
                int dimen=0;
                while(index!=nullptr){
                    ConstantSymbolEntry* constEntry = (ConstantSymbolEntry*)index->getSymbolEntry();
                    if(!constEntry->isConstant()){
                        if(check_on){
                        fprintf(stderr,"ArrayDecl index is not const!\n");
                        fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                        assert(index->getSymbolEntry()->isConstant());
                        }
                    }
                    if(constEntry->getIntValue()<=0){
                        if(check_on){
                        fprintf(stderr, "ArrayIndices is can not be negative or zero！\n");
                        fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                        assert(constEntry->getIntValue()>0);
                        }
                    }
                    /*z1107 补完常量维度*/
                    arrType->getLenVec().push_back(constEntry->getIntValue());
                    dimen++;
                    index=(ExprNode*)index->getNext();
                }
                if(dimen==0){
                    dimen=1;
                }
                arrType->setDimen(dimen);
                /*类型检查*/
                while(expr!=nullptr){
                    expType = expr->getSymbolEntry()->getType();
                    if(expType!=type){
                        if(check_on){
                        fprintf(stderr,"Type not match!\n");
                        fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                        assert(expType==type);
                        }
                    }
                    expr=(ExprNode *)expr->getNext();
                }


                initexp->getId()->getSymbolEntry() = new IdentifierSymbolEntry(arrType, initexp->getId()->getName(), identifiers->getLevel());
            }

            else{
                initexp->getId()->getSymbolEntry()=new IdentifierSymbolEntry($1, initexp->getId()->getName(), identifiers->getLevel());
                
            }
            identifiers->install(initexp->getId()->getName(), initexp->getId()->getSymbolEntry());
            print("init  Name：")
            print(initexp->getId()->getName().c_str());
            initexp=(InitStmt*)(initexp->getNext());

        }
        
        $$ = new DeclInitStmt((InitStmt *)$2);
    }
    | ConstDeclInitStmt
    ;
// AssignStmt
//     :
//     /* 左值直接赋值 */
//     LVal ASSIGN Exp SEMICOLON {
//         print("Direct assignment ");
//         $$ = new AssignStmt($1, $3);
//     }
//     ;
BlockStmt
    :   LBRACE 
        {identifiers = new SymbolTable(identifiers);} 
        Stmts RBRACE 
        {
            $$ = new CompoundStmt($3);
            SymbolTable *top = identifiers;
            identifiers = identifiers->getPrev();
            delete top;
        }
    /* 函数体为空 */
    | LBRACE RBRACE {$$=nullptr;}
    //| SEMICOLON{} // 空语句，有可能有问题……
    ;
IfStmt
    : IF LPAREN Cond RPAREN Stmt %prec THEN {
        print("IF THEN");
        $$ = new IfStmt($3, $5);
        print("OUT IF THEN");
    }
    | IF LPAREN Cond RPAREN Stmt ELSE Stmt {
        print("IF ELSE");
        $$ = new IfElseStmt($3, $5, $7);
        print("OUT IF ELSE");
    }
    ;
BreakStmt
    : BREAK SEMICOLON {
        $$ = new BreakStmt();
    }
    ;
ContinueStmt
    : CONTINUE SEMICOLON {
        $$ = new ContinueStmt();
    }
    ;
ReturnStmt
    :
    RETURN Exp SEMICOLON{
        print("RETURN ");
        $$ = new ReturnStmt($2);
    }
    ;
Exp
    : AssignExp {
        $$ = $1;
    }
    /*m1124 这里需要改为assign expression*/
    // | LOrExp{
    //     $$ = $1;
    // }
    ;
AssignExp
    :
    /*m1124 这里需要做一些类型的检查*/
    Cond{$$ = $1;}
    | UnaryExp ASSIGN AssignExp{
        // SymbolEntry *se1 = $1->getSymbolEntry();
        // SymbolEntry *se2 = $3->getSymbolEntry();
        printinfo("heldodo");
        SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
        $$ = new BinaryExpr(se, BinaryExpr::ASSIGN, $1, $3);
    }
    ;

Cond
    :
    LOrExp {$$ = $1;}
    ;

Type
    : INT {
        $$ = TypeSystem::intType;
    }
    | VOID {
        $$ = TypeSystem::voidType;
    }
    | FLOAT {
        $$ = TypeSystem::floatType;
    }
    ;

PrimaryExp
    :
    /*m1104 这里修正*/
    LPAREN Exp RPAREN{
        $$ = $2;
    }
    |
    LVal {
        /*m1104~m1107 常量表达式的计算以及修正*/
        SymbolEntry *se = $1->getSymbolEntry();
        
        if(dynamic_cast<IdentifierSymbolEntry*>(se)->isConstant()){
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::intType){
                printinfo("int");
                cs = new ConstantSymbolEntry(TypeSystem::intType, dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue());
            }
            /*m1122 处理数组情况: 思路是将对应的数组的值 在LVal中获得*/
            else if(se->getType()->isArray()){
                printinfo("array");
                // Array * arrType = (Array *)se->getType();
                std::cout<<dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue()<<std::endl;
                cs = new ConstantSymbolEntry(TypeSystem::intType, dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue());
            }
            else if(se->getType() == TypeSystem::floatType){
                printinfo("float");
                cs = new ConstantSymbolEntry(TypeSystem::floatType, dynamic_cast<IdentifierSymbolEntry*>(se)->getFloatValue());
            }
            /*m1122 处理为函数的情况: 思路是将对应函数的计算结果存在 LVal中*/
            else{
                if(check_on){
                    fprintf(stderr, "Val type is not int or float!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                }
            }
            $$ = new ConstNode($1, cs);
        }else{
            /*处理void情况*/
            if(se->getType()->isVoid()){
                if(check_on){
                    fprintf(stderr, "Cannot compute void type!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    assert(se->getType()->isVoid() == 0);
                }
            }
            $$ = $1;
        }
    }
    | INTEGER {
        ConstantSymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
        $$ = new Constant(se);
    }
    | OCTAL {
        ConstantSymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
        $$ = new Constant(se);
    }
    | HEXADECIMAL {
        ConstantSymbolEntry *se = new ConstantSymbolEntry(TypeSystem::intType, $1);
        $$ = new Constant(se);
    }
    | DECIMAL_FLOAT {
        ConstantSymbolEntry *se = new ConstantSymbolEntry(TypeSystem::floatType, $1);
        $$ = new Constant(se);
    }
    | HEXADECIMAL_FLOAT {
        ConstantSymbolEntry *se = new ConstantSymbolEntry(TypeSystem::floatType, $1);
        $$ = new Constant(se);
    }
    ;
UnaryExp
    :
    // z1104
    /* z1108 fix:这块之后函数call的返回值需要处理下*/
    // FuncCall{
    //     $$ = $1;
    // }
    /*m1102 单目运算符*/
    PrimaryExp {$$ = $1;}
    | ADD UnaryExp %prec PLUS{
        if($2->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($2->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,se->getIntValue());
            }else if(se->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,se->getFloatValue());
            }else{
                if(check_on){
                    fprintf(stderr, "The type can't compute!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                }
            }
            $$ = new UnaryExpr(cs, UnaryExpr::PLUS, $2);
        }
        /*m1122 检查非常量的类型*/
        else{
            SymbolEntry *se = new TemporarySymbolEntry($2->getSymbolEntry()->getType(), SymbolTable::getLabel());
            $$ = new UnaryExpr(se, UnaryExpr::PLUS, $2);
        }
    }
    | SUB UnaryExp %prec UMINUS{
        if($2->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($2->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,-se->getIntValue());
            }else if(se->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,-se->getFloatValue());
            }else{
                if(check_on){
                    fprintf(stderr, "The type can't compute!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                }
            }
            $$ = new UnaryExpr(cs, UnaryExpr::UMINUS, $2);
        }
        else{
            SymbolEntry *se = new TemporarySymbolEntry($2->getSymbolEntry()->getType(), SymbolTable::getLabel());
            $$ = new UnaryExpr(se, UnaryExpr::UMINUS, $2);
        }
        
    }
    | NOT UnaryExp{
        if($2->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($2->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,!se->getIntValue());
            }
            else if(se->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,!se->getFloatValue());
            }else{
                if(check_on){
                    fprintf(stderr, "The type can't compute!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                }
            }
            $$ = new UnaryExpr(cs, UnaryExpr::NOT, $2);
        }
        else{
            SymbolEntry *se = new TemporarySymbolEntry($2->getSymbolEntry()->getType(), SymbolTable::getLabel());
            $$ = new UnaryExpr(se, UnaryExpr::NOT, $2);
        }
    }
    ;

CastExp
    :
    /*m1123 添加显示类型转换*/
    UnaryExp {$$ = $1;}
    | LPAREN Type RPAREN CastExp{
        if($4->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($4->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::intType){
                if($2 == TypeSystem::intType)
                    cs = new ConstantSymbolEntry(TypeSystem::intType,se->getIntValue());
                else
                    cs = new ConstantSymbolEntry(TypeSystem::floatType,(float)se->getIntValue());
            }
            else if(se->getType() == TypeSystem::floatType){
                if($2 == TypeSystem::intType)
                    cs = new ConstantSymbolEntry(TypeSystem::intType,(int)se->getFloatValue());
                else
                    cs = new ConstantSymbolEntry(TypeSystem::floatType,se->getFloatValue());
            }else{
                if(check_on){
                    fprintf(stderr, "The type can't be casted!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                }
            }
            $$ = new CastExpr(cs, $4->getSymbolEntry(), $4);
        }else{
            
            SymbolEntry *ts = new TemporarySymbolEntry($2, SymbolTable::getLabel());
            $$ = new CastExpr(ts, $4->getSymbolEntry(), $4);
        }
    }
    // void转换这里有问题
    // | LPAREN VOID RPAREN CastExp{

    // }
    ;

MulExp
    :
    /*m1102 乘法运算符*/
    CastExp {$$ = $1;}
    | MulExp MUL CastExp{
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getFloatValue()*ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts2->getIntValue()*ts1->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts2->getFloatValue()*ts1->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts2->getIntValue()*ts1->getIntValue());
            }else{
                if(check_on){
                    fprintf(stderr, "The type can't compute!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                }
            }
            $$ = new BinaryExpr(cs, BinaryExpr::MUL, $1, $3);
        }
        else{
            SymbolEntry *se;
            if($1->getSymbolEntry()->getType() == TypeSystem::floatType || 
                $3->getSymbolEntry()->getType() == TypeSystem::floatType){
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::MUL, $1, $3);
        }        
    }
    | MulExp DIV CastExp{
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType()!=TypeSystem::intType||ts2->getType()!=TypeSystem::intType){
                if(check_on){
                    fprintf(stderr, "error! div only can use int type");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    assert(ts1->getType()==TypeSystem::intType);
                    assert(ts2->getType()==TypeSystem::intType);
                }
            }
            if(ts2->getIntValue() == 0){
                if(check_on){
                    fprintf(stderr, "error! the disivor is 0");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    assert(ts2->getIntValue()!=0);
                }
            }
            cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()/ts2->getIntValue());
            $$ = new BinaryExpr(cs, BinaryExpr::DIV, $1, $3);
        }
        else{
            SymbolEntry *se1 = $1->getSymbolEntry();
            SymbolEntry *se2 = $3->getSymbolEntry();
            if(se1->getType()!=TypeSystem::intType||se2->getType()!=TypeSystem::intType){
                if(check_on){
                    fprintf(stderr, "error! div only can use int type");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    assert(se1->getType()==TypeSystem::intType);
                    assert(se2->getType()==TypeSystem::intType);
                }
            }
            SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::DIV, $1, $3);
        } 
    }
    | MulExp MOD CastExp{
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType()!=TypeSystem::intType||ts2->getType()!=TypeSystem::intType){
                if(check_on){
                fprintf(stderr, "error! mod use float Type");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert(ts1->getType()==TypeSystem::intType);
                assert(ts2->getType()==TypeSystem::intType);
                }
            }
            if(ts2->getIntValue() == 0){
                if(check_on){
                fprintf(stderr, "error! the disivor is 0");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert(ts2->getIntValue()!=0);
                }
            }
            cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()%ts2->getIntValue());
            $$ = new BinaryExpr(cs, BinaryExpr::MOD, $1, $3);
        }
        else{
            SymbolEntry *se1 = $1->getSymbolEntry();
            SymbolEntry *se2 = $3->getSymbolEntry();
            if(se1->getType()!=TypeSystem::intType||se2->getType()!=TypeSystem::intType){
                if(check_on){
                    fprintf(stderr, "error! div only can use int type");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    assert(se1->getType()==TypeSystem::intType);
                    assert(se2->getType()==TypeSystem::intType);
                }
            }
            SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::MOD, $1, $3);
        }
    }
    ;
AddExp
    :
    MulExp {$$ = $1;}
    |
    AddExp ADD MulExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts2->getFloatValue()+ts1->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts2->getIntValue()+ts1->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts2->getFloatValue()+ts1->getIntValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts2->getIntValue()+ts1->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::ADD, $1, $3);
        }
        else{
            SymbolEntry *se;
            if($1->getSymbolEntry()->getType() == TypeSystem::floatType || 
                $3->getSymbolEntry()->getType() == TypeSystem::floatType){
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::ADD, $1, $3);
        }
    }
    |
    AddExp SUB MulExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getFloatValue()-ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getFloatValue()-ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getIntValue()-ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()-ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::SUB, $1, $3);
        }
        else{
            SymbolEntry *se;
            if($1->getSymbolEntry()->getType() == TypeSystem::floatType || 
                $3->getSymbolEntry()->getType() == TypeSystem::floatType){
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::SUB, $1, $3);
        }
    }
    ;
ConstExp
    : Cond {
        if($1->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *cs;
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            if(se->getType()==TypeSystem::intType){
                cs = new ConstantSymbolEntry(se->getType(), se->getIntValue());
            }
            else{
                cs = new ConstantSymbolEntry(se->getType(), se->getFloatValue());
            }
            $$ = new ExprNode(cs);
        }
        else{
            if(check_on){
                fprintf(stderr, "The expression is not const\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert($1->getSymbolEntry()->isConstant());
            }
        }
    }
    ;
RelExp
    :
    /*m1101 关系运算符补充*/
    /*m1122 关系运算符类型检查与转换*/
    AddExp {
        if($1->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *cs;
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            if(se->getType()==TypeSystem::intType){
                cs = new ConstantSymbolEntry(se->getType(), se->getIntValue());
            }
            else{
                cs = new ConstantSymbolEntry(se->getType(), se->getFloatValue());
            }
            $$ = new ConstNode($1, cs);
        }
        else{
            /*计算结果类型检查*/
            $$ = $1;
        }
    }
    |
    RelExp LESS AddExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()<ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()<ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()<ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()<ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::LESS, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
        }
    }
    |
    RelExp GREATER AddExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()>ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()>ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()>ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()>ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::GREATER, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::GREATER, $1, $3);
        }
    }
    |
    RelExp LESSEQUAL AddExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()<=ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()<=ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()<=ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()<=ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::LESSEQUAL, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::LESSEQUAL, $1, $3);
        }
    }
    |
    RelExp GREATEREQUAL AddExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()>=ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()>=ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()>=ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()>=ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::GREATEREQUAL, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::GREATEREQUAL, $1, $3);
        }
    }
    ;
EqExp
    :
    RelExp {
        if($1->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *cs;
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            if(se->getType()==TypeSystem::intType){
                cs = new ConstantSymbolEntry(se->getType(), se->getIntValue());
            }
            else{
                cs = new ConstantSymbolEntry(se->getType(), se->getFloatValue());
            }
            $$ = new ConstNode($1, cs);
        }
        else{
            $$ = $1;
        }
    }
    | 
    EqExp EQUAL RelExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()==ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()==ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()==ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()==ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::EQUAL, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::EQUAL, $1, $3);
        }
    }
    | 
    EqExp NOTEQUAL RelExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()!=ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()!=ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()!=ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()!=ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::NOTEQUAL, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::NOTEQUAL, $1, $3);
        }
    }
    ;
LAndExp
    :
    EqExp {
        if($1->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *cs;
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            if(se->getType()==TypeSystem::intType){
                cs = new ConstantSymbolEntry(se->getType(), se->getIntValue());
            }
            else{
                cs = new ConstantSymbolEntry(se->getType(), se->getFloatValue());
            }
            $$ = new ConstNode($1, cs);
        }
        else{
            $$ = $1;
        }
    }
    |
    LAndExp AND EqExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()&&ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()&&ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()&&ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()&&ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::AND, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::AND, $1, $3);
        }
    }
    ;
LOrExp
    :
    LAndExp {
        if($1->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *cs;
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            if(se->getType()==TypeSystem::intType){
                cs = new ConstantSymbolEntry(se->getType(), se->getIntValue());
            }
            else{
                cs = new ConstantSymbolEntry(se->getType(), se->getFloatValue());
            }
            $$ = new ConstNode($1, cs);
        }
        else{
            $$ = $1;
        }
    }
    |
    LOrExp OR LAndExp
    {
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()||ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getFloatValue()||ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()||ts1->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()||ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::OR, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::OR, $1, $3);
        }
    }
    ;



/* Z1102 add声明同时初始化 */
/* z1103 被之后的更新reduce */
/* z1104 更新数组  */
/* z1107 补完常量维度 */
/* z1108 ruduce conflit 抛弃该token的维护 */
// DeclStmt
//     : ConstDeclStmt
//     | Type ID SEMICOLON 
//     ;



WhileStmt
    : WHILE LPAREN Cond RPAREN Stmt {
        print("while");
        $$ = new WhileStmt($3, $5);
    }
    ;
FuncFParamList 
    : FuncFParam{
        $$ = $1;
    }
    | FuncFParamList COMMA FuncFParam{
        $$ = $1;
        $$->append($3);
    }
    /* 形参为空 */
    | %empty {$$ = nullptr;}
    ;
FuncRParam
    : Exp {
        $$ = $1;
    }
    | FuncRParam COMMA Exp {
        $$ = $1;
        $$->append($3);
    }
    /* 实参为空 */
    | %empty {$$=nullptr;}
    ;
FuncFParam
    : Type ID{
        SymbolEntry* se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel());
        identifiers->install($2, se);
        $$ = new DeclStmt(new Id(se));
        delete []$2;
    }
    /* z1108 add参数为数组 */
    /* 不确定检查类型的时候有没有顺利完成任务 */
    | Type ID ArrayIndex{
        Array *arrType =new Array($1);
        ExprNode* index = (ExprNode*)$3;
        /*计算维度*/
        int dimen=0;
        while(index!=nullptr){
            ConstantSymbolEntry* constEntry = (ConstantSymbolEntry*)index->getSymbolEntry();
            if(!constEntry->isConstant()){
                if(check_on){
                fprintf(stderr,"ArrayDecl index is not const!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert(index->getSymbolEntry()->isConstant());
                }
            }
            
            if(constEntry->getIntValue()<=0){
                if(check_on){
                fprintf(stderr, "ArrayIndices is can not be negative or zero！\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert(constEntry->getIntValue()>0);
                }
            }
            arrType->getLenVec().push_back(constEntry->getIntValue());
            dimen++;
            index=(ExprNode*)index->getNext();
        }
        if(dimen==0)
            dimen=1;
        arrType->setDimen(dimen);

        SymbolEntry* se = new IdentifierSymbolEntry(arrType,$2,identifiers->getLevel());
        identifiers->install($2, se);
        $$ = new DeclStmt(new Id(se));
        delete []$2;
    }

    ;
FuncHead
    : Type ID  {
        identifiers = new SymbolTable(identifiers); // new region
        $$ = new FuncHead($1,$2);
    } 
    ;
FuncDecl
    : 
    FuncHead LPAREN FuncFParamList RPAREN SEMICOLON{
        FuncHead* funchead=(FuncHead*)$1;
        Type* funcType;
        std::vector<Type*> vec;
        DeclStmt* fparam = (DeclStmt*)$3;
        while(fparam!=nullptr){

            vec.push_back(fparam->getId()->getSymbolEntry()->getType());
            fparam = (DeclStmt*)(fparam->getNext());
        }
        funcType = new FunctionType(funchead->getType(), vec);
        SymbolEntry* se = new IdentifierSymbolEntry(funcType, funchead->getName(), identifiers->getLevel());
        identifiers->install(funchead->getName(), se);
        $$ = new DeclStmt(new Id(se));
    }
    ;
FuncDef
    :
    /*z1104 try to fix decl&def*/
    /*z1105 try to fix decl&def*/
    FuncHead LPAREN FuncFParamList RPAREN{
        FuncHead* funchead=(FuncHead*)$1;
        SymbolEntry *se;
        FunctionType* funcType;
        se = identifiers->lookup(funchead->getName());
        if(se==nullptr){
            
            std::vector<Type*> vec;
            DeclStmt* fparam = (DeclStmt*)$3;
            while(fparam!=nullptr){
                vec.push_back(fparam->getId()->getSymbolEntry()->getType());
                fparam = (DeclStmt*)(fparam->getNext());
            }
            funcType = new FunctionType(funchead->getType(), vec);
            SymbolEntry* se = new IdentifierSymbolEntry(funcType, funchead->getName(), identifiers->getPrev()->getLevel());
            identifiers->getPrev()->install(funchead->getName(), se);
        }
        else{
            /*z1107 一些新的问题：重载*/
            /*参数检查*/
            funcType =(FunctionType*)se->getType();
            std::vector<Type*> rparams;
            ExprNode* exp = (ExprNode*)$3;
            while(exp!=nullptr){
                rparams.push_back(exp->getSymbolEntry()->getType());
                exp=(ExprNode*)exp->getNext();
            }
            bool check_res=true;
            if(check_on)
             check_res= funcType->checkParam(rparams);
            if(!check_res){
                if(check_on){
                fprintf(stderr,"func def is not match with its decl\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                assert(check_res);
                }
            }

        }
    }
    BlockStmt
    {
        FuncHead* funchead=(FuncHead*)$1;
        SymbolEntry *se;
        se = identifiers->lookup(funchead->getName());
        $$ = new FunctionDef(se, $6, (DeclStmt*)$3);
        SymbolTable *ident = identifiers;
        identifiers = identifiers->getPrev();
        delete ident;
        //delete []$$;
    }
    ;

FuncCall
    : ID LPAREN FuncRParam RPAREN {
        printinfo("funccall");
        SymbolEntry* se;
        se = identifiers->lookup($1);
        if(se == nullptr)
        {
            if(check_on){
            fprintf(stderr, "function \"%s\" is undefined!\n", (char*)$1);
            fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
            delete [](char*)$1;
            assert(se != nullptr);}
        }
        /*参数检查 还没做，exp可能还得提供个getType的接口*/
        /*z1107 finish? still not check*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
        funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    /*m1105 输入输出需要声明为全局*/
    | GETINT LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        // printinfo($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | GETCH LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | GETFLOAT LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::floatType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | GETARRAY LPAREN FuncRParam RPAREN{
        FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            Type* funcType;
            std::vector<Type*> vec;
            //fix: vec.push_back()这里需要push进去int数组的形参
            Array *arrType =new Array(TypeSystem::intType);
            vec.push_back(arrType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | GETFARRAY LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
            Type* funcType;
            std::vector<Type*> vec;
             //fix: vec.push_back()这里需要push进去float数组的形参
            Array *arrType =new Array(TypeSystem::floatType);
            vec.push_back(arrType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | PUTINT LPAREN FuncRParam RPAREN{
        // printinfo($1);
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            // printinfo(funchead->getName().c_str());
            Type* funcType;
            std::vector<Type*> vec;
            vec.push_back(TypeSystem::intType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | PUTCH LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            vec.push_back(TypeSystem::intType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | PUTFLOAT LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            vec.push_back(TypeSystem::floatType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | PUTARRAY LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            vec.push_back(TypeSystem::intType);
            //fix:vec.push_back();这里需要补一个int数组类型的函数参数
            Array *arrType =new Array(TypeSystem::intType);
            vec.push_back(arrType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    | PUTFARRAY LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            vec.push_back(TypeSystem::intType);
            //fix:vec.push_back();这里需要补一个float数组类型的函数参数
            Array *arrType =new Array(TypeSystem::floatType);
            vec.push_back(arrType);
            funcType = new FunctionType(funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<Type*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry()->getType());
            exp=(ExprNode*)exp->getNext();
        }
        if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
    }
    ;

%%

int yyerror(char const* message)
{
    std::cerr<<message<<std::endl;
    return -1;
}
