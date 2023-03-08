%code top{
    #include "parser.h"
    extern Ast ast;
    int yylex();
    int yyerror( char const * );
    bool check_on = 1;
    bool assert_on = 1;
    extern int yylineno;
    extern int offsets;
    int now_in_while=0;
    int loop_marker=0;
    bool loop_switch=0;
    bool const_flag = 0;
    Type* const_type;
    Type* cur_type,*retType;
    int fin_return=0;
    std::vector<WhileStmt*>whilestmts;
    WhileStmt*now_whilestmt;
    int paramCnt=0;
    int intParamCnt=0;
    int floatParamCnt=0;
}

%code requires {
    #include "Ast.h"
    #include "SymbolTable.h"
    #include "Type.h"
    #include "Unit.h"
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
%token <strtype> ID GETINT GETFLOAT GETARRAY PUTINT PUTFLOAT PUTARRAY PUTFARRAY GETCH GETFARRAY PUTCH PUTF STARTTIME STOPTIME
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


%nterm <stmttype> Stmts Stmt AssignStmt BlockStmt IfStmt ReturnStmt  FuncDef 
%nterm <exprtype> AddExp Cond LOrExp PrimaryExp LVal RelExp LAndExp CastExp

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
    : AssignStmt {$$=$1;}
    | BlockStmt {$$=$1;}
    | IfStmt {$$=$1;}
    | ReturnStmt {$$=$1;}
    | FuncDef {$$=$1;}
    | DeclInitStmt{$$=$1;}
    | WhileStmt {$$=$1;}
    | BreakStmt {$$=$1;}
    | ContinueStmt {$$=$1;}
    | ExprStmt{$$=$1;}
    | FuncDecl{$$=$1;}
    | SEMICOLON{$$=new SpaceStmt();}
    ;
ExprStmt
    : Cond SEMICOLON {
        $$ = new ExprStmt($1);
    }
    ;

Cond
    :
    LOrExp {
        printinfo("Cond\n");
        $$ = $1;
    }
    ;
/* z1103 新增数组切片 */
/* z1107 finished*/
ArrayIndices
    : LBRACKET Cond RBRACKET {
        //z1209 完善数组
        Type * type = $2->getSymbolEntry()->getType();
        if(type!=TypeSystem::intType){
            if(type->isArray()){
                printg("isArr");
                type = dynamic_cast<ArrayType*>(type)->getEleType();
            }
            if(check_on&&type!=TypeSystem::intType){
                fprintf(stderr, "ArrayIndices is not int\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(type==TypeSystem::intType);
            }
        }
        $$ = $2;
    }
    | ArrayIndices LBRACKET Cond RBRACKET {
        //z1209 完善数组
        Type * type = $3->getSymbolEntry()->getType();
        if(type!=TypeSystem::intType){
            if(type->isArray()){
                type = dynamic_cast<ArrayType*>(type)->getEleType();
            }
            if(check_on&&type!=TypeSystem::intType){
                fprintf(stderr, "ArrayIndices is not int\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on){assert(type==TypeSystem::intType);}
            }
        }
        $$ = $1;
        $$->append($3);
    }
    /* z1108 可能会有问题 */
    | LBRACKET RBRACKET{
        SymbolEntry * se=nullptr;
        $$ = new ExprNode(se);
        $$->setNull(1);
    }
    ;
ArrayIndex
    : ArrayIndices {
        $$ = $1;
    }
    
    /* z1108 之后需要考虑到最低维缺省 */
    // | ArrayIndices LBRACKET RBRACKET
    ;
LVal
    : ID {
        SymbolEntry *se;
        se = identifiers->lookup($1);
        print($1);
        print("find id");
        
        Id* id;
        if(se == nullptr)
        {
            print("se == nullptr");
            if(check_on){
                fprintf(stderr, "identifier \"%s\" is undefined\n", (char*)$1);
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                delete [](char*)$1;
                if(assert_on) assert(se != nullptr);
            }
        }
        else{
            id = new Id(se,$1);
            if(se->getType()->isArray()){
                id->setIsArray(1);
                id->setArrPFlag(1);
                }
            
        }
        
        $$ = id;
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
                delete [](char*)$1;
                assert(se != nullptr);
            }
        }
        // 暂且写为只有最低维元素可赋值
        /*z1209 finished 可以赋值高维度了*/
        int sliceCnt=0;
        ExprNode *tmp=$2;
        while(tmp!=nullptr){
            sliceCnt++;
            tmp=(ExprNode *)tmp->getNext();
        }
        // z1209 完善数组
        $$ = new Id(se,$2,$1,1);
        delete []$1;
        // may detele $2
    }
    
    ;

/* z1102 IdList */
/* z1108 reduce */

/* z1109 finish {},{}*/
ArrAssignExp
    : Cond{
        $$ = $1;
        // std::cout<<"+++++++++++++++++++++++++++++\n";
    }
    /* z1209 fix nullptr 总是令人担心，可能会有问题*/
    | LBRACE RBRACE {
        //std::cout<<"arrinit: null\n";
        // $$ = nullptr;
        ConstantSymbolEntry*const_se = new ConstantSymbolEntry(TypeSystem::intType, 0);

        ExprNode* exp = new ExprNode(const_se);
        exp->setNull(1);
        exp->setLast(1);
        $$=exp;
    }

    | LBRACE ConstExpInitList RBRACE{
        ExprNode* exp=$2;
        while(exp->getNext()!=nullptr){
            exp=(ExprNode*)exp->getNext();
        }
        exp->setLast(1);
        $$ = $2;
    }
    ;

ConstExpInitList
    : ArrAssignExp{
        $$ = $1;
    }
    | ConstExpInitList COMMA ArrAssignExp{
        $1->append($3);
        $$ = $1;
    }
    ;


/*z1107 数组初始化 重新处理*/
ArrInit
    : 
    ID ArrayIndices {
        IdentifierSymbolEntry *se=new IdentifierSymbolEntry($1, identifiers->getLevel());
        identifiers->install($1, se);
        se->setAllZero(1);
        $$ =new InitStmt(new Id(se,$2,$1,true));
    }
    | 
    ID ArrayIndices ASSIGN ArrAssignExp{
        print("ID ArrayIndices ASSIGN ArrAssignExp");
        SymbolEntry *se=new IdentifierSymbolEntry($1, identifiers->getLevel());
        identifiers->install($1, se);
        $$ =new InitStmt(new Id(se,$2,$1,true),$4);
    }
    ;
InitStmt
// z1102
/* 连续赋值 */
// z1201 发现重大缺陷，暂时向前兼容下，先不动全局的代码
/* z1201 完成曲折修复 或许后续该缺陷不再需要修正 */
/* z1214 dbq 还是得改 */
    : ID ASSIGN Cond{
        printinfo("ID ASSIGN Cond");
        IdentifierSymbolEntry *se;
        if(const_flag){
            se= new IdentifierSymbolEntry(const_type, $1, identifiers->getLevel());
        }else{
            se= new IdentifierSymbolEntry($1, identifiers->getLevel());
        }
        identifiers->install($1, se);
        $$ =new InitStmt(new Id(se,$1),$3);
        if(const_flag){
            ConstantSymbolEntry* cs = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            // std::cout<<cs->getType()->toStr()<<cs->getFloatValue()<<std::endl;
            if(se->getType() == TypeSystem::intType){
                if(cs->getType() == TypeSystem::intType){
                    se->setIntValue(cs->getIntValue());
                }else{
                    se->setIntValue(cs->getFloatValue());
                    // std::cout<<"已经计算const "<<se->toStr()<<" "<<se->getIntValue()<<std::endl;
                }
                // std::cout<<dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry())->getIntValue()<<std::endl;
            }else if(se->getType() == TypeSystem::floatType){
                if(cs->getType() == TypeSystem::intType){
                    se->setFloatValue(cs->getIntValue());
                }else{
                    se->setFloatValue(cs->getFloatValue());
                }
                // se->setFloatValue(dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry())->getFloatValue());
            }
            se->setIdtype(IdentSystem::constant); 
        }
    }
    | InitStmt COMMA ID ASSIGN Cond{
        printinfo("ID ASSIGN Exp ++1");
        IdentifierSymbolEntry *se;
        if(const_flag){
            se= new IdentifierSymbolEntry(const_type, $3, identifiers->getLevel());
        }else{
            se= new IdentifierSymbolEntry($3, identifiers->getLevel());
        }
        identifiers->install($3, se);
        // std::cout<<"已经初始化2"<<se->toStr()<<std::endl;
        print($3);
        $$->append(new InitStmt(new Id(se,$3),$5));
        if(const_flag){
            ConstantSymbolEntry* cs = dynamic_cast<ConstantSymbolEntry*>($5->getSymbolEntry());
            // std::cout<<cs->getType()->toStr()<<cs->getFloatValue()<<std::endl;
            if(se->getType()  == TypeSystem::intType){
                if(cs->getType() == TypeSystem::intType){
                    se->setIntValue(cs->getIntValue());
                }else{
                    se->setIntValue(cs->getFloatValue());
                    // std::cout<<"已经计算const "<<se->toStr()<<" "<<se->getIntValue()<<std::endl;
                }
                // std::cout<<dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry())->getIntValue()<<std::endl;
            }else{
                if(cs->getType() == TypeSystem::intType){
                    se->setFloatValue(cs->getIntValue());
                }else{
                    se->setFloatValue(cs->getFloatValue());
                }
                // se->setFloatValue(dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry())->getFloatValue());
            }
            se->setIdtype(IdentSystem::constant); 
        }
    }
    /*z1107 数组赋值 重新处理*/
    | ArrInit{
        print("ArrInit");
        $$ = (InitStmt*)$1;
    }

    | InitStmt COMMA ArrInit{
        // SymbolEntry *se;
        // se=nullptr;
        $$->append($3);
    }
    | InitStmt COMMA ID{
        print("ID  +1");
        SymbolEntry *se= new IdentifierSymbolEntry($3, identifiers->getLevel());
        identifiers->install($3, se);
        $$->append(new InitStmt(new Id(se,$3)));
    }
    | ID {
        printinfo("IdList-ID");
        SymbolEntry *se= new IdentifierSymbolEntry($1, identifiers->getLevel());
        identifiers->install($1, se);
        $$=new InitStmt(new Id(se,$1));
    }
    ;
// z1102
/*z1107 finish type&index check*/
ConstDeclInitStmt
    : CONST Type{
        const_flag = true;
        const_type = $2;
    }
    InitStmt SEMICOLON{
        InitStmt * initexp = (InitStmt *)$4;
        ExprNode *expr;
        Type *expType;
        Type *type = (Type *)$2;
        while(initexp!=nullptr){
            expr = initexp->getExp();
            if(initexp->getId()->getIsArray()){
                ArrayType *arrType =new ArrayType($2);
                ExprNode* index = initexp->getId()->getIndex();
                /*计算维度*/
                int dimen=0;
                /*todo 检查是不是只有最高位缺省！*/
                /*z1215 seems to finish*/
                while(index!=nullptr){
                    if(index->getNull()){
                        arrType->getLenVec().push_back(0);
                        index=(ExprNode*)index->getNext();
                        continue;
                    }
                    if(index->getSymbolEntry()!=nullptr){
                    ConstantSymbolEntry* constEntry = (ConstantSymbolEntry*)index->getSymbolEntry();
                    if(!constEntry->isConstant()){
                        if(check_on){
                            fprintf(stderr,"ArrayDecl index is not const!\n");
                            fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                            if(assert_on) assert(index->getSymbolEntry()->isConstant());
                        }
                    }
                    
                    if(constEntry->getIntValue()<=0&&constEntry->getFloatValue()<=0){
                        if(check_on){
                            fprintf(stderr, "ArrayIndices is can not be negative or zero！\n");
                            fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                            if(assert_on) assert((constEntry->getIntValue()>0||constEntry->getFloatValue()>0));
                        }
                    }
                    /*z1107 补完常量维度*/
                    /*todo 需要计算最高维度是什么！！*/
                    arrType->getLenVec().push_back(constEntry->getIntValue());
                    }
                    dimen++;
                    index=(ExprNode*)index->getNext();
                }
                if(dimen==0){
                    dimen=1;
                }
                arrType->setDimen(dimen);
                std::vector<Type*> typeVec;
                typeVec.push_back(type);
                /*类型检查*/
                while(expr!=nullptr){
                    expType = expr->getSymbolEntry()->getType();
                    // z1209 完善数组&函数
                    if(expType!=type){
                        if(expType->isArray()){
                            expType=dynamic_cast<ArrayType*>(expType)->getEleType();
                        }
                        else if(expType->isFunc()){
                            expType=dynamic_cast<FunctionType*>(expType)->getRetType();
                        }
                        if(expType!=type){
                            
                            if(check_on){
                                fprintf(stderr,"Warning: implicit type conversion!\n");
                                fprintf(stderr, "warn occurs in <line: %d, col: %d>\n",yylineno,offsets);
                                // if(assert_on) assert(expType==type);
                            }
                        }
                    }
                    expr=(ExprNode *)expr->getNext();
                }
                bool calres = arrType->calHighestDimen();
                if(check_on&&!calres){
                    fprintf(stderr,"error: Array default dimen cal fail!\n");
                    if(assert_on) assert(calres);

                }
                // z1201 更改se初始化策略
                IdentifierSymbolEntry* idse = (IdentifierSymbolEntry*)initexp->getId()->getSymbolEntry();
                idse->setType(arrType); 
                idse->setIdtype(IdentSystem::constant); 
            }
            
            print("init Name：")
            print(initexp->getId()->getName().c_str());
            initexp=(InitStmt*)(initexp->getNext());

        }
        $$ = new DeclInitStmt((InitStmt *)$4);
        print("ConstDeclInitStmt over");
        const_flag = false;
    }
    ;
    
/*z1107 finish type&index check*/
DeclInitStmt
    : Type InitStmt SEMICOLON{
        // std::cout<<"22222"<<std::endl;
        InitStmt * initexp = (InitStmt *)$2;
        ExprNode *expr;
        cur_type=(Type *)$1;
        Type *expType;
        Type *type = (Type *)$1;
        while(initexp!=nullptr){
            expr = initexp->getExp();
            if(initexp->getId()->getIsArray()){
                ArrayType *arrType =new ArrayType($1);
                ExprNode* index = initexp->getId()->getIndex();
                /*计算维度*/
                int dimen=0;
                while(index!=nullptr){
                    if(index->getNull()){
                        arrType->getLenVec().push_back(0);
                        index=(ExprNode*)index->getNext();
                        continue;
                    }
                    // printf("%s %d",se->toStr().c_str(),dynamic_cast<IdentifierSymbolEntry*>(se)->isConstant());
                    ConstantSymbolEntry* constEntry = (ConstantSymbolEntry*)index->getSymbolEntry();
                    if(!constEntry->isConstant()){
                        if(check_on){
                            fprintf(stderr,"ArrayDecl index is not const!\n");
                            fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                            // if(assert_on) assert(index->getSymbolEntry()->isConstant());
                        }
                    }
                    if(constEntry->getIntValue()<=0&&constEntry->getFloatValue()<=0){
                        if(check_on){
                            fprintf(stderr, "ArrayIndices is can not be negative or zero！\n");
                            fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                            if(assert_on) assert(constEntry->getIntValue()>0);
                        }
                    }
                    /*z1107 补完常量维度*/
                    arrType->getLenVec().push_back(constEntry->getIntValue());
                    dimen++;
                    index=(ExprNode*)index->getNext();
                }
                // if(dimen==0){
                //     dimen=1;
                // }
                arrType->setDimen(dimen);
                
                /*类型检查*/
                while(expr!=nullptr){
                    expType = expr->getSymbolEntry()->getType();
                    // z1209 完善数组&函数
                    if(expType!=type){
                        if(expType->isArray()){
                            expType=dynamic_cast<ArrayType*>(expType)->getEleType();
                        }
                        else if(expType->isFunc()){
                            expType=dynamic_cast<FunctionType*>(expType)->getRetType();
                        }
                        if(expType!=type){
                            if(check_on){
                                fprintf(stderr,"Warning: implicit type conversion!\n");
                                fprintf(stderr, "warn occurs in <line: %d, col: %d>\n",yylineno,offsets);
                                // if(assert_on) assert(expType==type);
                            }
                        }
                    }
                    expr=(ExprNode *)expr->getNext();
                }
                bool calres = arrType->calHighestDimen();
                if(check_on&&!calres){
                    fprintf(stderr,"error: Array default dimen cal fail!\n");
                    if(assert_on) assert(calres);

                }
                // z1201 更改se初始化策略
                IdentifierSymbolEntry* idse = (IdentifierSymbolEntry*)initexp->getId()->getSymbolEntry();
                idse->setType(arrType); 
            }

            else{
                IdentifierSymbolEntry* idse = (IdentifierSymbolEntry*)initexp->getId()->getSymbolEntry();
                idse->setType($1); 
                // std::cout<<cs->getType()->toStr()<<cs->getFloatValue()<<std::endl;
               
                if(idse->isGlobal()){
                    if(expr!=nullptr && expr->getSymbolEntry()->isConstant()){
                        ConstantSymbolEntry* cs = dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry());
                        if($1 == TypeSystem::intType){
                            if(cs->getType() == TypeSystem::intType){
                                idse->setIntValue(cs->getIntValue());
                            }else{
                                idse->setIntValue(cs->getFloatValue());
                                // std::cout<<"已经计算const "<<se->toStr()<<" "<<se->getIntValue()<<std::endl;
                            }
                            // std::cout<<"全局变量的值: "<<idse->getIntValue()<<std::endl;
                            // std::cout<<dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry())->getIntValue()<<std::endl;
                        }else{
                            if(cs->getType() == TypeSystem::intType){
                                idse->setFloatValue(cs->getIntValue());
                            }else{
                                idse->setFloatValue(cs->getFloatValue());
                            }
                            // std::cout<<"全局变量的值: "<<idse->getFloatValue()<<std::endl;
                            // se->setFloatValue(dynamic_cast<ConstantSymbolEntry*>(expr->getSymbolEntry())->getFloatValue());
                        }
                    }else{
                        if($1 == TypeSystem::intType){
                            idse->setIntValue(0);
                        }else{
                            idse->setFloatValue(0);
                        }
                    }
                }
                
            }
            print("init  Name：")
            print(initexp->getId()->getName().c_str());
            initexp=(InitStmt*)(initexp->getNext());

        }
        $$ = new DeclInitStmt((InitStmt *)$2);
    }
    | ConstDeclInitStmt
    ; 
AssignStmt
    :
    /* 左值直接赋值 */
    LVal ASSIGN Cond SEMICOLON {
        print("Direct assignment ");
        Id* id = dynamic_cast<Id *>($1);
        id->setLeft();
        $$ = new AssignStmt(id, $3);
    }
    ;
BlockStmt
    :   LBRACE 
        {identifiers = new SymbolTable(identifiers);
        // if(loop_switch){
        //     loop_marker++;
        //     }
         } 
        Stmts RBRACE 
        {
            $$ = new CompoundStmt($3);
            SymbolTable *top = identifiers;
            identifiers = identifiers->getPrev();
            // if(--loop_marker==0&&now_in_while){
            //     now_in_while=0;
            //     loop_switch=0;
            // }
            delete top;
        }
    /* 函数体为空 */
    /*z1201 debug: nullptr->spacestmt*/
    | LBRACE RBRACE {$$=new SpaceStmt();;}
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
        if(now_in_while==0){
            fprintf(stderr, "error! break outside while");
            if(check_on)
                assert(now_in_while>=1);
        }
        if(!whilestmts.empty())
            $$ = new BreakStmt(whilestmts.back());
    }
    ;
ContinueStmt
    : CONTINUE SEMICOLON {
        if(now_in_while==0){
            fprintf(stderr, "error! continue outside while");
            if(check_on)
                assert(now_in_while>=1);
        }
        if(!whilestmts.empty())
            $$ = new ContinueStmt(whilestmts.back());
        // $$ = new ContinueStmt(now_whilestmt);
    }
    ;
ReturnStmt
    :
    RETURN Cond SEMICOLON{
        print("RETURN ");
        if(fin_return==1||fin_return==2){
            fin_return=2;
        }
        else{
            fprintf(stderr,"Return statement should in function!\n");
            if(assert_on)assert(fin_return==1||fin_return==2);
        }
        // $$ = new ReturnStmt($2);

        // z1214 返回类型检查
        std::vector<Type*> typeVec;
        // Type* type=$2->getSymbolEntry()->getType();
        Type* type = getBasicType($2->getSymbolEntry());
        int retno;
        // 强转
        if ((type->isFloat() && retType->isInt()) ||
            (type->isInt() && retType->isFloat())) {
            $$ = new ReturnStmt(new ImplictCastExpr($2, retType));
        } else {
            $$ = new ReturnStmt($2);            
        }
        
        if(retType==TypeSystem::voidType&&!(type==TypeSystem::voidType))
            retno=1;
        if(!(retType==TypeSystem::voidType)&&(type==TypeSystem::voidType))
            retno=1;
        // std::cout<<type->toStr()<<" "<<retType->toStr()<<" "<<retno<<"\n";
        if(retno==1){
            fprintf(stderr,"Return type %s and %s not match!\n",type->toStr().c_str(),retType->toStr().c_str());
            if(assert_on)assert(1!=retno);
        }
    }
    // Z1203 return void;
    |RETURN SEMICOLON{
        print("RETURN void ");
        $$ = new ReturnStmt(new ExprNode(nullptr));
    }
    ;
// Exp 
//     : AddExp {
//         $$ = $1;
//     }
//     ;

PrimaryExp
    :
    // z1104
    /* z1108 fix:这块之后函数call的返回值需要处理下*/
    /*m1104 这里修正*/
    LPAREN Cond RPAREN{
        $$ = $2;
    }
    | FuncCall{
        print("func call");
        // SymbolEntry *se = $1->getSymbolEntry();
        // (FunctionType *)se->getType()->getRetType();
        /*m1204: 需要检查函数的返回类型 void 类型会报错*/
        $$ = $1;
    }
    |
    LVal {
        printinfo("lval");
        /*m1104-7 常量表达式的计算修复*/
        SymbolEntry *se = $1->getSymbolEntry();
        print(se->toStr().c_str());
        if(dynamic_cast<IdentifierSymbolEntry*>(se)->isConstant()){
            printinfo("constant");
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::intType, dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue());
                Id * id =(Id*)$1;
                $$ = new ConstNode(id, cs);
            }
            else if(se->getType() == TypeSystem::floatType){
                printinfo("float");
                cs = new ConstantSymbolEntry(TypeSystem::floatType, dynamic_cast<IdentifierSymbolEntry*>(se)->getFloatValue());
                Id * id =(Id*)$1;
                $$ = new ConstNode(id, cs);
            }
            else if(se->getType()->isArray()){
                //m1203 处理常量数组的情况
                // std::cout<<"const array"<<std::endl;
                // ArrayType* arrType = (ArrayType *)se->getType();
                // if(arrType->getEleType() == TypeSystem::intType){
                //     printinfo("array int");
                //     cs = new ConstantSymbolEntry(TypeSystem::intType, dynamic_cast<IdentifierSymbolEntry*>(se)->getIntValue());
                // }else if(arrType->getEleType() == TypeSystem::floatType){
                //     printinfo("array float");
                //     cs = new ConstantSymbolEntry(TypeSystem::floatType, dynamic_cast<IdentifierSymbolEntry*>(se)->getFloatValue());
                // }
                $$ = $1;
            }
            
        }else{
            printinfo("variable");
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
        print("DECIMAL_FLOAT");
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
    /*m1102 单目运算符*/
    PrimaryExp {$$ = $1;}
    | ADD UnaryExp %prec PLUS{
        Type* btype = getBasicType($2->getSymbolEntry());
        if(btype == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype != TypeSystem::voidType);
            }
        }
        if($2->getSymbolEntry()->isConstant()){
            /*not do: 常量数组之后处理, 数组元素取值的处理, 指针的处理*/
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($2->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,se->getFloatValue());
            }else{
                /*包含bool情况*/
                cs = new ConstantSymbolEntry(TypeSystem::intType,se->getIntValue());
            }
            $$ = new UnaryExpr(cs, UnaryExpr::PLUS, $2);
        }
        // else if($2->getSymbolEntry()->getType()->isFunc()){
        //     std::cout<<"add func";
        //     IdentifierSymbolEntry *se =(IdentifierSymbolEntry*)$2->getSymbolEntry();
        //     $$ = new UnaryExpr(se, UnaryExpr::PLUS, $2);
        // }
        else{
            //m1216 补充处理bool函数情况
            SymbolEntry *se;
            if(btype==TypeSystem::boolType){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }else{
                se = new TemporarySymbolEntry(btype, SymbolTable::getLabel());
            }
            $$ = new UnaryExpr(se, UnaryExpr::PLUS, $2);
        }

    }
    | SUB UnaryExp %prec UMINUS{
        Type* btype = getBasicType($2->getSymbolEntry());
        if(btype == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype != TypeSystem::voidType);
            }
        }
        if($2->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($2->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,-se->getFloatValue());
            }else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,-se->getIntValue());
            }
            $$ = new UnaryExpr(cs, UnaryExpr::UMINUS, $2);
        }
        else{
            SymbolEntry *se;
            if(btype==TypeSystem::boolType){
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }else{
                se = new TemporarySymbolEntry(btype, SymbolTable::getLabel());
            }
            $$ = new UnaryExpr(se, UnaryExpr::UMINUS, $2);
        }
    }
    | NOT UnaryExp{
        printinfo("NOT Exp");
        Type* btype = getBasicType($2->getSymbolEntry());
        if(btype == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype != TypeSystem::voidType);
            }
        }
        if($2->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($2->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(se->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,!se->getFloatValue());
            }
            else{
                // z1201 补了
                cs = new ConstantSymbolEntry(TypeSystem::boolType,!se->getIntValue());
            }
            $$ = new UnaryExpr(cs, UnaryExpr::NOT, $2);
        }else{
            SymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new UnaryExpr(se, UnaryExpr::NOT, $2);
        }
    }
    ;

CastExp
    :
    /*m1123 添加显示类型转换(几乎无用)*/
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
        printinfo("MulExp\n");
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
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
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts2->getIntValue()*ts1->getIntValue());
                // if(check_on){
                //     fprintf(stderr, "The type can't compute!\n");
                //     fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                // }
            }
            $$ = new BinaryExpr(cs, BinaryExpr::MUL, $1, $3);
        }
        else{
            SymbolEntry *se;
            // SymbolEntry *se, *se1, *se2;
            // Type* type1 = $1->getSymbolEntry()->getType();
            // Type* type2 = $3->getSymbolEntry()->getType();
            // if(type1!=nullptr&&type1->isArray()){
            //     ArrayType* arrType = (ArrayType *)type1;
            //     if(arrType->getEleType() == TypeSystem::intType){
            //         se1 = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            //     }else if(arrType->getEleType() == TypeSystem::floatType){
            //         se1 = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            //     }
            // }else if(type1!=nullptr&&type1->isFunc()){
            //     /*m1202 处理void情况*/
            //     FunctionType * funcType=(FunctionType *)type1;
            //     if(funcType->getRetType() == TypeSystem::intType){
            //         se1 = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            //     }else if(funcType->getRetType() == TypeSystem::floatType){
            //         se1 = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            //     }else if(funcType->getRetType() == TypeSystem::voidType){
            //         printinfo("void");
            //         if(check_on){
            //             fprintf(stderr, "Cannot compute void type!\n");
            //             fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
            //             if(assert_on) assert(funcType->getRetType() != TypeSystem::voidType);
            //         }
            //     }
            // }else{
            //     se1 = new TemporarySymbolEntry(type1, SymbolTable::getLabel());
            // }
            // if(type2!=nullptr&&type2->isArray()){
            //     ArrayType* arrType = (ArrayType *)type2;
            //     if(arrType->getEleType() == TypeSystem::intType){
            //         se2 = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            //     }else if(arrType->getEleType() == TypeSystem::floatType){
            //         se2 = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            //     }
            // }else{
            //     se2 = new TemporarySymbolEntry(type2, SymbolTable::getLabel());
            // }
            if(btype1 == TypeSystem::floatType || 
                btype2 == TypeSystem::floatType){
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::MUL, $1, $3);
        }         
    
    }
    | MulExp DIV UnaryExp{
        print("DIV");
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(btype2 == TypeSystem::intType && ts2->getIntValue() == 0){
                if(check_on){
                    fprintf(stderr, "error! the disivor is 0");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(!(btype2 == TypeSystem::intType && ts2->getIntValue() == 0));
                }
            }else if(btype2 == TypeSystem::floatType && ts2->getFloatValue() == 0){
                if(check_on){
                    fprintf(stderr, "error! the disivor is 0");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(!(btype2 == TypeSystem::floatType && ts2->getFloatValue() == 0));
                }
            }
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getFloatValue()/ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getFloatValue()/ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getIntValue()/ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()/ts2->getIntValue());
                // if(check_on){
                //     fprintf(stderr, "The type can't compute!\n");
                //     fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                // }
            }
            $$ = new BinaryExpr(cs, BinaryExpr::DIV, $1, $3);
        }
        else{
            SymbolEntry *se;
            if(btype1 == TypeSystem::floatType || 
                btype2 == TypeSystem::floatType){
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::DIV, $1, $3);
        } 
    }
    | MulExp MOD UnaryExp{
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType()==TypeSystem::floatType || ts2->getType()==TypeSystem::floatType){
                if(check_on){
                    fprintf(stderr, "error! mod use float Type");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(ts1->getType()!=TypeSystem::floatType);
                    if(assert_on) assert(ts2->getType()!=TypeSystem::floatType);
                }
            }
            if(ts2->getIntValue() == 0){
                if(check_on){
                    fprintf(stderr, "error! the disivor is 0");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(ts2->getIntValue() != 0);
                }
            }
            cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()%ts2->getIntValue());
            $$ = new BinaryExpr(cs, BinaryExpr::MOD, $1, $3);
        }
        else{
            SymbolEntry *se;
            if(btype1==TypeSystem::floatType || btype2==TypeSystem::floatType){
                if(check_on){
                    fprintf(stderr, "error! mod use float Type");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(btype1!=TypeSystem::floatType);
                    if(assert_on) assert(btype2!=TypeSystem::floatType);
                }
            }
            se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
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
        printinfo("ADDExp\n");
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
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
            if(btype1 == TypeSystem::floatType || 
                btype2 == TypeSystem::floatType){
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
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
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
                cs = new ConstantSymbolEntry(TypeSystem::floatType,ts1->getIntValue()-ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::intType,ts1->getIntValue()-ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::SUB, $1, $3);
        }
        else{
            SymbolEntry *se;
            if(btype1 == TypeSystem::floatType || 
                btype2 == TypeSystem::floatType){
                se = new TemporarySymbolEntry(TypeSystem::floatType, SymbolTable::getLabel());
            }
            else{
                se = new TemporarySymbolEntry(TypeSystem::intType, SymbolTable::getLabel());
            }
            $$ = new BinaryExpr(se, BinaryExpr::SUB, $1, $3);
        }
    }
    ;
// z1209 暂时抛弃该token
// ConstExp
//     : AddExp {
//         if($1->getSymbolEntry()->isConstant()){
//             ConstantSymbolEntry *cs;
//             ConstantSymbolEntry *se = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
//             if(se->getType()==TypeSystem::intType){
//                 cs = new ConstantSymbolEntry(se->getType(), se->getIntValue());
//             }
//             else{
//                 cs = new ConstantSymbolEntry(se->getType(), se->getFloatValue());
//             }
//             $$ = new ExprNode(cs);
//         }
//         else{
//             if(check_on)
//             fprintf(stderr, "The expression is not const\n");
//         }
//     }
//     ;
RelExp
    :
    /*m1101 关系运算符补充*/
    AddExp {$$ = $1;}
    |
    RelExp LESS AddExp
    {
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()<ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()<ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()<ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()<ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::LESS, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::LESS, $1, $3);
        }
    }
    |
    RelExp GREATER AddExp
    {
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()>ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()>ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()>ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()>ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::GREATER, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::GREATER, $1, $3);
        }
    }
    |
    RelExp LESSEQUAL AddExp
    {
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()<=ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()<=ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()<=ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()<=ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::LESSEQUAL, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::LESSEQUAL, $1, $3);
        }
    }
    |
    RelExp GREATEREQUAL AddExp
    {
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()>=ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()>=ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()>=ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()>=ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::GREATEREQUAL, $1, $3);
        }
        else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::GREATEREQUAL, $1, $3);
        }
    }
    ;
EqExp
    :
    RelExp {$$ = $1;}
    | 
    EqExp EQUAL RelExp
    {
        printinfo("Equal Exp\n");
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()==ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()==ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()==ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()==ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::EQUAL, $1, $3);
        }else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::EQUAL, $1, $3);
        }
    }
    | 
    EqExp NOTEQUAL RelExp
    {
        printinfo("NOT Equal Exp\n");
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()!=ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()!=ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()!=ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()!=ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::NOTEQUAL, $1, $3);
        }else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::NOTEQUAL, $1, $3);
        }
    }
    ;
LAndExp
    :
    EqExp {$$ = $1;}
    |
    LAndExp AND EqExp
    {
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()&&ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()&&ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()&&ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()&&ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::AND, $1, $3);
        }else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::AND, $1, $3);
        }
    }
    ;
LOrExp
    :
    LAndExp {$$ = $1;}
    |
    LOrExp OR LAndExp
    {
        printinfo("LOrExp");
        Type* btype1 = getBasicType($1->getSymbolEntry());
        Type* btype2 = getBasicType($3->getSymbolEntry());
        if(btype1 == TypeSystem::voidType || btype2 == TypeSystem::voidType){
            /*m1202 处理void情况*/
            printinfo("void");
            if(check_on){
                fprintf(stderr, "Cannot compute void type!\n");
                fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                if(assert_on) assert(btype1 != TypeSystem::voidType && btype2 != TypeSystem::voidType);
            }
        }
        if($1->getSymbolEntry()->isConstant()&&$3->getSymbolEntry()->isConstant()){
            ConstantSymbolEntry *ts1 = dynamic_cast<ConstantSymbolEntry*>($1->getSymbolEntry());
            ConstantSymbolEntry *ts2 = dynamic_cast<ConstantSymbolEntry*>($3->getSymbolEntry());
            ConstantSymbolEntry *cs;
            if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()||ts2->getFloatValue());
            }
            else if(ts1->getType() == TypeSystem::floatType && ts2->getType() == TypeSystem::intType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getFloatValue()||ts2->getIntValue());
            }
            else if(ts1->getType() == TypeSystem::intType && ts2->getType() == TypeSystem::floatType){
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()||ts2->getFloatValue());
            }
            else{
                cs = new ConstantSymbolEntry(TypeSystem::boolType,ts1->getIntValue()||ts2->getIntValue());
            }
            $$ = new BinaryExpr(cs, BinaryExpr::OR, $1, $3);
        }else{
            TemporarySymbolEntry *se = new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel());
            $$ = new BinaryExpr(se, BinaryExpr::OR, $1, $3);
        }
    }
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
    : WHILE LPAREN Cond RPAREN{
        print("while!");
        loop_switch=1;
        now_in_while++;
        now_whilestmt = new WhileStmt($3);
        whilestmts.push_back(now_whilestmt);
        
    } Stmt {
        now_whilestmt=whilestmts.back();
        whilestmts.pop_back();
        now_whilestmt->setStmt($6);
        $$ = now_whilestmt;
        now_in_while--;

    }
    ;
FuncFParamList 
    : FuncFParam{
        $$ = $1;
    }
    | FuncFParamList COMMA FuncFParam{
        print("FuncFParamList COMMA FuncFParam");
        $1->append($3);
        $$ = $1;
    }
    /* 形参为空 */
    | %empty {$$ = nullptr;}
    ;
FuncRParam
    : Cond {
        $$ = $1;
    }
    | FuncRParam COMMA Cond {
        $1->append($3);
        $$ = $1;
    }
    /* 实参为空 */
    | %empty {$$=nullptr;}
    ;
FuncFParam
    : Type ID{
        printinfo("Fparam +1");
        if($1->isInt()){
            paramCnt=intParamCnt++;
        }else if($1->isFloat()){
            paramCnt=floatParamCnt++;
        }
        IdentifierSymbolEntry* se = new IdentifierSymbolEntry($1, $2, identifiers->getLevel(),paramCnt,IdentSystem::variable);
        // std::cout<<"==="<<identifiers->getLevel()<<"\n";
        identifiers->install($2, se);
        $$ = new DeclStmt(new Id(se));
        delete []$2;
    }
    /* z1108 add参数为数组 */
    /* z1201 todo: 差写死维度的参数检查！*/
    | Type ID ArrayIndex{
        print("Fparam arr +1");
        ArrayType *arrType =new ArrayType($1);
        ExprNode* index = (ExprNode*)$3;
        /*计算维度*/
        int dimen=0;
        while(index!=nullptr){
            if(index->getNull()){
                arrType->getLenVec().push_back(0);
            }
            if(index->getSymbolEntry()!=nullptr){
            ConstantSymbolEntry* constEntry = (ConstantSymbolEntry*)index->getSymbolEntry();
            if(!constEntry->isConstant()){
                if(check_on){
                    fprintf(stderr,"ArrayDecl index is not const!\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(index->getSymbolEntry()->isConstant());
                }
            }
            
            if(constEntry->getIntValue()<=0&&constEntry->getFloatValue()<=0){
                if(check_on){
                    fprintf(stderr, "ArrayIndices can not be negative or zero！\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert((constEntry->getIntValue()>0||constEntry->getFloatValue()>0));
                }
            }
            /*z1203 todo 计算最高维*/
            arrType->getLenVec().push_back(constEntry->getIntValue());
            }
            dimen++;
            index=(ExprNode*)index->getNext();
        }
        if(dimen==0)
            dimen=1;
        arrType->setDimen(dimen);
        paramCnt=intParamCnt++;
        // if(arrType->getEleType()->isInt()){
        //     paramCnt=intParamCnt++;
        // }else{
        //     paramCnt=floatParamCnt++;
        // }
        SymbolEntry* se = new IdentifierSymbolEntry(arrType,$2,identifiers->getLevel(),paramCnt,IdentSystem::variable);
        // std::cout<<paramCnt;
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
        FunctionType* funcType;
        std::vector<Type*> vec;
        std::vector<Operand*> vecSe;
        DeclStmt* fparam = (DeclStmt*)$3;
        while(fparam!=nullptr){
            IdentifierSymbolEntry * idse = (IdentifierSymbolEntry*)fparam->getId()->getSymbolEntry();
            vec.push_back(idse->getType());
            idse->setAddr(fparam->getId()->getOperand());
            vecSe.push_back(fparam->getId()->getOperand());
            fparam = (DeclStmt*)(fparam->getNext());
        }
        funcType = new FunctionType(funchead->getName(),funchead->getType(), vec);
        funcType->setParamSe(vecSe);
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
        paramCnt=0;
        intParamCnt=0;
        floatParamCnt=0;

        FuncHead* funchead=(FuncHead*)$1;
        SymbolEntry *se;
        FunctionType* funcType;
        se = identifiers->lookup(funchead->getName());
        if(se==nullptr){
            
            std::vector<Type*> vec;
            std::vector<Operand*> vecSe;
            DeclStmt* fparam = (DeclStmt*)$3;
            while(fparam!=nullptr){
            IdentifierSymbolEntry * idse = (IdentifierSymbolEntry*)fparam->getId()->getSymbolEntry();
            vec.push_back(idse->getType());
            idse->setAddr(fparam->getId()->getOperand());
            vecSe.push_back(fparam->getId()->getOperand());
            fparam = (DeclStmt*)(fparam->getNext());
        }
            funcType = new FunctionType(funchead->getName(),funchead->getType(), vec);
            funcType->setParamSe(vecSe);
            retType = funcType->getRetType();
            SymbolEntry* se = new IdentifierSymbolEntry(funcType, funchead->getName(), identifiers->getPrev()->getLevel());
            identifiers->getPrev()->install(funchead->getName(), se);
        }
        else{
            /*z1107 一些新的问题：todo 重载*/
            /*参数检查*/
            funcType =(FunctionType*)se->getType();
            retType = funcType->getRetType();
            std::vector<SymbolEntry*> rparams;
            ExprNode* exp = (ExprNode*)$3;
            while(exp!=nullptr){
                rparams.push_back(exp->getSymbolEntry());
                exp=(ExprNode*)exp->getNext();
            }
            bool check_res=true;
            if(check_on)
                check_res= funcType->checkParam(rparams);
            if(check_res){
                if(check_on){
                    fprintf(stderr,"func def is not match with its decl\n");
                    fprintf(stderr, "error occurs in <line: %d, col: %d>\n",yylineno,offsets);
                    if(assert_on) assert(check_res);
                }
            }

        }
        fin_return=1;
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
        FunctionType* func = dynamic_cast<FunctionType*>(se->getType());
        //delete []$$;
        if(func->getRetType()->isVoid()||fin_return==2){
            
        }
        else{
            fprintf(stderr,"Need return statement!\n");
            if(assert_on)assert(fin_return==2&&!func->getRetType()->isVoid());
        }
        
        fin_return=0;
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
                if(assert_on) assert(se != nullptr);
            }
        }
        /*参数检查 还没做，exp可能还得提供个getType的接口*/
        /*z1107 finish? still not check*/
        // finish
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
        
    }
    | GETCH LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
        
    }
    | GETFLOAT LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::floatType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
        
    }
    | GETARRAY LPAREN FuncRParam RPAREN{
        FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            Type* funcType;
            std::vector<Type*> vec;
            // vec.push_back(TypeSystem::intType);
            // ArrayType* arrType = new ArrayType(TypeSystem::intType, 1);
            PointerType *arrType =new PointerType(TypeSystem::intType);
            //fix: vec.push_back()这里需要push进去int数组的形参
            //z1209 完善指针
            vec.push_back(arrType);
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
        
    }
    | GETFARRAY LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::intType, $1);
            Type* funcType;
            std::vector<Type*> vec;
             //vec.push_back()这里需要push进去float数组的形参
            PointerType *arrType =new PointerType(TypeSystem::floatType);
            vec.push_back(arrType);
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
            
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
            //z1209 完善指针
            PointerType *arrType =new PointerType(TypeSystem::intType);
            vec.push_back(arrType);
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
            //z1209 完善指针
            vec.push_back(new PointerType(TypeSystem::floatType));
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
        
    }
    | STARTTIME LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
            funcType->checkParam(rparams);
        $$ = new FuncCall(se, $3);
        
    }
    | STOPTIME LPAREN FuncRParam RPAREN{
        SymbolEntry *se = globals->lookup($1);
        if(se==nullptr){
            FuncHead* funchead = new FuncHead(TypeSystem::voidType, $1);
            Type* funcType;
            std::vector<Type*> vec;
            funcType = new FunctionType($1,funchead->getType(), vec);
            se = new IdentifierSymbolEntry(funcType, funchead->getName(), 0);
            globals->install(funchead->getName(), se);
            unit.insertDeclare(se);
        }
        /*m1107 参数类型检查*/
        FunctionType * funcType =(FunctionType*)se->getType();
        std::vector<SymbolEntry*> rparams;
        ExprNode* exp = (ExprNode*)$3;
        while(exp!=nullptr){
            rparams.push_back(exp->getSymbolEntry());
            exp=(ExprNode*)exp->getNext();
        }
        // if(check_on)
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
