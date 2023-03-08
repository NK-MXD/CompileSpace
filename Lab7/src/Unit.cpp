#include "Unit.h"
#include "Ast.h"
#include "Type.h"
#include <stack>
extern FILE *yyout;
void Unit::insertFunc(Function *f)
{
    func_list.push_back(f);
}

void Unit::removeFunc(Function *func)
{
    // printf("====start erase=====\n");
    func_list.erase(std::find(func_list.begin(), func_list.end(), func));
    // printf("====end erase=====\n");
}
void Unit::insertGlobal(SymbolEntry *se)
{
    global_list.push_back(se);
}

void Unit::output() const
{
    printg("=== GLOBAL LIST ===");
    for (auto se : global_list)
    {
        if (se->getType()->isInt())
        {
            fprintf(yyout, "%s = global %s %d, align 4\n",
                    se->toStr().c_str(), se->getType()->toStr().c_str(),
                    ((IdentifierSymbolEntry *)se)->getIntValue());
        }
        else if (se->getType()->isFloat())
        {
            fprintf(yyout, "%s = global %s %f, align 4\n", 
                    se->toStr().c_str(),se->getType()->toStr().c_str(),
                    ((IdentifierSymbolEntry *)se)->getFloatValue());
        }

        else if (se->getType()->isArray())
        {
            ArrayType* arr = (ArrayType*)se->getType();
            std::string str = genInitializer(arr);
            fprintf(yyout, "%s = global %s %f, align 4\n", 
                    se->toStr().c_str(),str.c_str());
            
        }
    }
    printg("=== FUNCTION LIST ===");
    for (auto &func : func_list)
    {
        func->output();
    }
    for (auto se : declare_list)
    {
        FunctionType *type = (FunctionType *)(se->getType());
        std::string str = type->toStr();
        std::string name = str.substr(0, str.find('('));
        std::string param = str.substr(str.find('('));
        fprintf(yyout, "declare %s %s%s\n", type->getRetType()->toStr().c_str(),
                se->toStr().c_str(), param.c_str());
    }
}

void Unit::insertDeclare(SymbolEntry *se)
{
    auto it = std::find(declare_list.begin(), declare_list.end(), se);
    if (it == declare_list.end())
    {
        declare_list.push_back(se);
    }
}
Unit::~Unit()
{
    // for (auto &func : func_list)
    //     delete func;
    // for (auto &se : global_list)
    //     delete se;
}

void Unit::genMachineCode(MachineUnit* munit) 
{
    AsmBuilder* builder = new AsmBuilder();
    builder->setUnit(munit);
    for (auto &func : func_list)
        func->genMachineCode(builder);
}