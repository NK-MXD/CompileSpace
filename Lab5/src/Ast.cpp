#include "Ast.h"
#include "SymbolTable.h"
#include <string>
#include "Type.h"

extern FILE *yyout;
int Node::counter = 0;

Node::Node()
{
    seq = counter++;
    next=nullptr;
}

void FuncHead::output(int level)
{
    // print("FuncHead");
    // fprintf(yyout, "%*cFuncHead\n", level, ' ');
    // id->output(level + 4);
}

void Ast::output()
{
    print("program");
    fprintf(yyout, "program\n");
    if(root != nullptr)
        root->output(4);
}
/*m1102 定义单目运算符输出*/
void UnaryExpr::output(int level)
{
    print("UnaryExpr");
    std::string op_str;
    switch(op)
    {
        case PLUS:
            op_str = "plus";
            break;
        case UMINUS:
            op_str = "minus";
            break;
        case NOT:
            op_str = "not";
            break;
    }
    fprintf(yyout, "%*cUnaryExpr\top: %s\n", level, ' ', op_str.c_str());
    /*ques:为啥这里要输出level+4*/
    /*ans:为了排版*/
    /*fix: ret*/
    if(expr1)
        expr1->output(level + 4);
}

void BinaryExpr::output(int level)
{
    print("BinaryExpr");
    std::string op_str;
    switch(op)
    {
        case ADD:
            op_str = "add";
            break;
        case SUB:
            op_str = "sub";
            break;
        case AND:
            op_str = "and";
            break;
        case OR:
            op_str = "or";
            break;
        case MUL:
            op_str = "mul";
            break;
        case DIV:
            op_str = "div";
            break;
        case MOD:
            op_str = "mod";
            break;
        case LESS:
            op_str = "less";
            break;
        case GREATER:
            op_str = "greater";
            break;
        case LESSEQUAL:
            op_str = "lessequal";
            break;
        case GREATEREQUAL:
            op_str = "greatequal";
            break;
        case EQUAL:
            op_str = "greatequal";
            break;
        case NOTEQUAL:
            op_str = "greatequal";
            break;
    }
    fprintf(yyout, "%*cBinaryExpr\top: %s\n", level, ' ', op_str.c_str());
    /*fix: ret*/
    if(expr1)
        expr1->output(level + 4);
    if(expr2)
        expr2->output(level + 4);
    print("BinaryExpr-end");
}

void Constant::output(int level)
{
    print("constant");
    std::string type, value;
    type = symbolEntry->getType()->toStr();
    value = symbolEntry->toStr();
        print("IntegerLiteral");
    fprintf(yyout, "%*cIntegerLiteral\tvalue: %s\ttype: %s\n", level, ' ',
            value.c_str(), type.c_str());
            print("IntegerLiteral-end");
}

void Id::output(int level)
{
    std::string sname, type;
    int scope;
    sname = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    print("Id");
    if(dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->isConstant()){
        fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: const %s\n", level, ' ',
            sname.c_str(), scope, type.c_str());
    }
    else{
        fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: %s\n", level, ' ',
            sname.c_str(), scope, type.c_str());
    }   
}

void ConstNode::output(int level)
{
    print("ConstNode");
    std::string sname, type;
    int scope;
    sname = id->getSymbolEntry()->toStr();
    type = id->getSymbolEntry()->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(id->getSymbolEntry())->getScope();
    print("Id");
    fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: const %s\n", level, ' ',
        sname.c_str(), scope, type.c_str());
}

void CompoundStmt::output(int level)
{
    print("CompoundStmt");
    fprintf(yyout, "%*cCompoundStmt\n", level, ' ');
    stmt->output(level + 4);
}

void FuncStmt::output(int level)
{
    print("FuncStmt");
    fprintf(yyout, "%*cFuncStmt\n", level, ' ');
    expr->output(level + 4);
}

void SeqNode::output(int level)
{
    print("Sequence");
    //fprintf(yyout, "%*cSequence\n", level, ' ');
    // stmt1->output(level + 4);
    // stmt2->output(level + 4);
    stmt1->output(level);
    stmt2->output(level);
}

void DeclStmt::output(int level)
{
    print("DeclStmt");
    fprintf(yyout, "%*cDeclStmt\n", level, ' ');
    Id * p =this->id;
    while(p!=nullptr){
        print("before id");
        p->output(level + 4);
        p = (Id *)p->getNext();
    }
}
void DeclInitStmt::output(int level)
{
    print("DeclInitStmt");
    fprintf(yyout, "%*cDeclInitStmt\n", level, ' ');
    InitStmt * is =this->initstmt;
    print("DeclInitStmt while" );
    while(is!=nullptr){
        print("init output +1");
        is->output(level + 4);
        is=(InitStmt *)is->getNext();
    }
    
}
void SpaceStmt::output(int level)
{
    fprintf(yyout, "%*cSpaceStmt\n", level, ' ');
    
}
void InitStmt::output(int level)
{
    print("InitExpr");
    fprintf(yyout, "%*cInitExpr\n", level, ' ');
    id->output(level + 4);
    if(expr!=nullptr)
        expr->output(level + 4);
}



void IfStmt::output(int level)
{
    print("IfStmt");
    fprintf(yyout, "%*cIfStmt\n", level, ' ');
    cond->output(level + 4);
    if(thenStmt!=nullptr){
        print("cond?");
        thenStmt->output(level + 4);
        print("cond-end");
    }
    print("IfStmt-end");
    
}

void IfElseStmt::output(int level)
{
    print("IfElseStmt");
    fprintf(yyout, "%*cIfElseStmt\n", level, ' ');
    cond->output(level + 4);
    thenStmt->output(level + 4);
    elseStmt->output(level + 4);
}

void WhileStmt::output(int level) {
    print("WhileStmt");
    fprintf(yyout, "%*cWhileStmt\n", level, ' ');
    if(cond)
        cond->output(level + 4);
    stmt->output(level + 4);
}

void BreakStmt::output(int level) {
    fprintf(yyout, "%*cBreakStmt\n", level, ' ');
}

void ContinueStmt::output(int level) {
    fprintf(yyout, "%*cContinueStmt\n", level, ' ');
}

void ReturnStmt::output(int level)
{
    print("ReturnStmt");
    fprintf(yyout, "%*cReturnStmt\n", level, ' ');
    retValue->output(level + 4);
}

void AssignStmt::output(int level)
{
    print("AssignStmt");
    fprintf(yyout, "%*cAssignStmt\n", level, ' ');
    lval->output(level + 4);
    expr->output(level + 4);
}


void FunctionDef::output(int level) {
    print("FunctionDef");
    std::string name, type;
    name = se->toStr();
    type = se->getType()->toStr();
    fprintf(yyout, "%*cFunctionDef\tfunc name: %s\ttype: %s\n", level,
            ' ', name.c_str(), type.c_str());
    if (decl) {
        decl->output(level + 4);
    }
    stmt->output(level + 4);
}

void FuncCall::output(int level) {
    print("FuncCall");
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry*>(symbolEntry)->getScope();
    fprintf(yyout, "%*cFuncCall\tfunction name: %s\tscope: %d\ttype: %s\n",
            level, ' ', name.c_str(), scope, type.c_str());
    Node* temp = param;
    while (temp) {
        temp->output(level + 4);
        temp = temp->getNext();
    }
    print("FuncCall-end");
}

void ExprStmt::output(int level) {
    print("ExprStmt");
    fprintf(yyout, "%*cExprStmt\n", level, ' ');
    expr->output(level + 4);
}
