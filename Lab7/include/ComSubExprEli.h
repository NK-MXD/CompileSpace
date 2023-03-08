#ifndef _COMSUBEXPRELI_H
#define _COMSUBEXPRELI_H
#include <set>
#include "Instruction.h"
#include "Unit.h"
#include "Type.h"
//公共子表达式优化
struct cmp_inst{ 
    bool operator()(Instruction* a,Instruction* b)const{
        auto aops = a->getOp();
        auto bops = b->getOp();
        auto asizes = aops.size();
        auto bsizes = bops.size();
        if(asizes < bsizes){
            return true;
        }
        if(asizes > bsizes){
            return false;
        }

        auto ait = aops.begin();
        auto bit = bops.begin();
        while(ait != aops.end()){
            auto a_operand = *ait;
            auto b_operand = *bit;
            if(a_operand != b_operand){
                if(a_operand->isConstant() && b_operand->isConstant()){
                    auto a_const = dynamic_cast<ConstantSymbolEntry*>(a_operand->getSymbolEntry());
                    auto b_const = dynamic_cast<ConstantSymbolEntry*>(b_operand->getSymbolEntry());
                    if(a_const->getType() == TypeSystem::intType &&
                        b_const->getType() == TypeSystem::intType &&
                         a_const->getIntValue() != b_const->getIntValue()){
                        return a_const->getIntValue() < b_const->getIntValue();
                    }else if(a_const->getType() == TypeSystem::floatType &&
                        b_const->getType() == TypeSystem::intType &&
                         a_const->getFloatValue() != b_const->getIntValue()){
                        return a_const->getFloatValue() < b_const->getIntValue();
                    }else if(a_const->getType() == TypeSystem::intType &&
                        b_const->getType() == TypeSystem::floatType &&
                         a_const->getIntValue() != b_const->getFloatValue()){
                        return a_const->getIntValue() < b_const->getFloatValue();
                    }else if(a_const->getFloatValue() != b_const->getFloatValue())
                        return a_const->getFloatValue() < b_const->getFloatValue();
                }else{
                    return a_operand->toStr() < b_operand->toStr();
                }
            }
            ait++; bit++;
        }
        if(a->getInstType() != b->getInstType()){
            return a->getInstType() < b->getInstType();
        }else{
            return a->getOpcode() < b->getOpcode();
        }
        return false;
    }
};

class ComSubExprEli{
    Unit* unit;
    std::set<Instruction*,cmp_inst> U;
    std::map<BasicBlock*,std::set<Instruction*,cmp_inst>> bb_in, bb_out, bb_gen, bb_kill;
public:
    ComSubExprEli(Unit* _unit):unit(_unit){};
    void execute();
    static bool is_valid_expr(Instruction* inst);

    void compute_local_gen(Function* f);
    void compute_local_kill(Function* f);
    void compute_global_in_out(Function* f);
    void compute_global_common_expr(Function* f);
    void initial_map(Function* f);

    static void remove_relevant_instr(Type* val,std::set<Instruction*,cmp_inst>& bb_set);
    static void insert_relevant_instr(Type* val,std::set<Instruction*,cmp_inst>& bb_set);
};


#endif