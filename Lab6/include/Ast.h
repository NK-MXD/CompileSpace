#ifndef __AST_H__
#define __AST_H__

#include <fstream>
#include"Type.h"
#include "SymbolTable.h"
# define DEBUG_SWITCH 0
# if DEBUG_SWITCH
# define print(str)\
        printf("%s\n",str);
# else
# define print(str) //
# endif

# define DEBUG_SWITCH_M 0
# if DEBUG_SWITCH_M
# define printinfo(str)\
        printf("%s\n",str);
# else
# define printinfo(str) //
# endif

class SymbolEntry;

class Node
{
private:
    static int counter;
    int seq;
    /* z1102 增加next结点 */
    Node *next =nullptr;
public:
    Node();
    int getSeq() const {return seq;};
    virtual void output(int level) = 0;
    void setNext(Node* node) {
        this->next=node;
    }
    void append(Node* node){
        print("in append");
        Node *p=this;
        while(p->getNext()!=nullptr){
            p=p->getNext();
        }
        
        if(p != this)
            p->setNext(node);
        else 
            p->setNext(node);

    }
    Node* getNext() {
        return next;
    }
};

class ExprNode : public Node
{
protected:
    SymbolEntry *symbolEntry;
public:
    ExprNode(SymbolEntry *symbolEntry) : symbolEntry(symbolEntry){};
    SymbolEntry *&getSymbolEntry(){return this->symbolEntry;}
    void output(int level){}
};

/*m1102 定义单目运算符*/
class UnaryExpr : public ExprNode
{
private:
    int op;
    ExprNode *expr1;
public:
    enum {PLUS, UMINUS, NOT,FUNC};
    UnaryExpr(SymbolEntry *se, int op, ExprNode*expr1) : ExprNode(se), op(op), expr1(expr1){};
    void output(int level);
};

/*m1102 添加乘法运算符, 关系运算符等*/
class BinaryExpr : public ExprNode
{
private:
    int op;
    ExprNode *expr1, *expr2;
public:
    enum {ADD, SUB, AND, OR, MUL, DIV, MOD, LESS, GREATER, LESSEQUAL, GREATEREQUAL, EQUAL, NOTEQUAL};
    BinaryExpr(SymbolEntry *se, int op, ExprNode*expr1, ExprNode*expr2) : ExprNode(se), op(op), expr1(expr1), expr2(expr2){};
    void output(int level);
};

class Constant : public ExprNode
{
public:
    Constant(SymbolEntry *se) : ExprNode(se){};
    void output(int level);
};

class Id : public ExprNode
{
private:
    std::string name;
    ExprNode* index;
    bool isArray;
public:
    Id(SymbolEntry *se,std::string name="",bool isArray=false) : ExprNode(se),name(name),isArray(isArray){};
    /* for ID ArrayIndices */
    Id(SymbolEntry *se,ExprNode* index,std::string name="",bool isArray=false) : ExprNode(se),name(name),index(index),isArray(isArray){};
    void output(int level);
    void setName(std::string name){this->name=name;}
    std::string getName(){return this->name;}
    ExprNode* getIndex(){return index;}
    void setIsArray(bool isArray){this->isArray=isArray;}
    bool getIsArray(){return this->isArray;}
    
    // z1102
    // void setNext(Id* node) {
    //     this->setNext(node);
    // }
    // Id* getNext() {
    //     print("getNext");
    //     return this->getNext();
    // }
    // void append(Id* node){
    //     print("in append");
    //     Node *p=this;
    //     while(p->getNext()!=nullptr){
    //         p=p->getNext();
    //     }
        
    //     if(p != this)
    //         this->setNext(node);
    //     else 
    //         p->setNext(node);

    // }
};

// class ConstNode : public Id
// {
// private:
//     ConstantSymbolEntry *constantSymbolEntry;
// public:
//     ConstNode(SymbolEntry *se,ConstantSymbolEntry *constantSymbolEntry):Id(se), constantSymbolEntry(constantSymbolEntry){};
//     ConstantSymbolEntry *&getSymbolEntry(){return this->constantSymbolEntry;};
// };

class ConstNode : public ExprNode
{
protected:
    ExprNode* id;
public:
    ConstNode(ExprNode* id,SymbolEntry *cs):ExprNode(cs), id(id){};
    void output(int level);
};


// z1103
class FuncCall : public ExprNode {
   private:
    ExprNode* param;
    // z1108 或许之后用得上
    Type * retType;
    ExprNode* retExp;
   public:
    FuncCall(SymbolEntry* se, ExprNode* param = nullptr,ExprNode*retExp=nullptr): ExprNode(se), param(param),retExp(retExp){
            FunctionType * funcType=(FunctionType *)se->getType();
            retType=funcType->getreturnType();
        };
    ExprNode* getRetExp(){return this->retExp;}
    void output(int level);
};


class StmtNode : public Node
{};

class FuncStmt : public StmtNode
{
private:
    ExprNode *expr;
public:
    FuncStmt(ExprNode *expr) : expr(expr) {};
    void output(int level);
};

class CompoundStmt : public StmtNode
{
private:
    StmtNode *stmt;
public:
    CompoundStmt(StmtNode *stmt) : stmt(stmt) {};
    void output(int level);
};

class SeqNode : public StmtNode
{
private:
    StmtNode *stmt1, *stmt2;
public:
    SeqNode(StmtNode *stmt1, StmtNode *stmt2) : stmt1(stmt1), stmt2(stmt2){};
    void output(int level);
};

class DeclStmt : public StmtNode
{
private:
    Id *id;
public:
    DeclStmt(Id *id) : id(id){};
    void output(int level);
    Id * &getId(){
        return id;
    }
};

// z1102
class InitStmt : public StmtNode
{
private:
    Id *id;
    ExprNode *expr;
public:
    InitStmt(Id *id, ExprNode *expr) : id(id), expr(expr) {};
    InitStmt(Id *id) : id(id) {};
    void output(int level);
    Id* &getId(){
        return id;
    }
    ExprNode* &getExp(){
        return expr;
    }

};
// z1105
class FuncHead : public StmtNode {
   private:
    
    Type* type;
    std::string name; 

   public:
    FuncHead(Type* type, std::string name)
        : type(type), name(name){};
    std::string getName(){return this->name;}
    Type* &getType(){return this->type;}
    void output(int level);
};

class DeclInitStmt : public StmtNode
{
private:
    InitStmt *initstmt;
public:
    DeclInitStmt(InitStmt *initstmt) : initstmt(initstmt){};
    void output(int level);
};

class SpaceStmt : public StmtNode
{
public:
    void output(int level);
};

class IfStmt : public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *thenStmt;
public:
    IfStmt(ExprNode *cond, StmtNode *thenStmt) : cond(cond), thenStmt(thenStmt){};
    void output(int level);
};

class IfElseStmt : public StmtNode
{
private:
    ExprNode *cond;
    StmtNode *thenStmt;
    StmtNode *elseStmt;
public:
    IfElseStmt(ExprNode *cond, StmtNode *thenStmt, StmtNode *elseStmt) : cond(cond), thenStmt(thenStmt), elseStmt(elseStmt) {};
    void output(int level);
};

class WhileStmt : public StmtNode {
   private:
    ExprNode* cond;
    StmtNode* stmt;

   public:
    WhileStmt(ExprNode* cond, StmtNode* stmt) : cond(cond), stmt(stmt){};
    void output(int level);
};

class ReturnStmt : public StmtNode
{
private:
    ExprNode *retValue;
public:
    ReturnStmt(ExprNode*retValue) : retValue(retValue) {};
    void output(int level);
};

class BreakStmt : public StmtNode {
   public:
    BreakStmt(){};
    void output(int level);
};

class ContinueStmt : public StmtNode {
   public:
    ContinueStmt(){};
    void output(int level);
};

class AssignStmt : public StmtNode
{
private:
    ExprNode *lval;
    ExprNode *expr;
public:
    AssignStmt(ExprNode *lval, ExprNode *expr) : lval(lval), expr(expr) {};
    void output(int level);
};

class ExprStmt : public StmtNode {
   private:
    ExprNode* expr;

   public:
    ExprStmt(ExprNode* expr) : expr(expr){};
    void output(int level);
};

class FunctionDef : public StmtNode
{
private:
    SymbolEntry *se;
    StmtNode *stmt;
    // Z1103
    DeclStmt* decl;
public:
    FunctionDef(SymbolEntry *se, StmtNode *stmt, DeclStmt* decl) : se(se), stmt(stmt), decl(decl){};
    void output(int level);
};

class Ast
{
private:
    Node* root;
public:
    Ast() {root = nullptr;}
    void setRoot(Node*n) {root = n;}
    void output();
};

#endif
