#ifndef __MACHINECODE_H__
#define __MACHINECODE_H__
#include <vector>
#include <set>
#include <string>
#include <algorithm>
#include <iostream>
#include <fstream>
#include "Type.h"
#include "SymbolTable.h"
using namespace std;

# define DEBUG_SWITCH_machine 0
# if DEBUG_SWITCH_machine
# define printma(str)\
        std::cout<<str<<"\n";
# else
# define printma(str) //
# endif
/* Hint:
* MachineUnit: Compiler unit
* MachineFunction: Function in assembly code 
* MachineInstruction: Single assembly instruction  
* MachineOperand: Operand in assembly instruction, such as immediate number, register, address label */

/* Todo:
* We only give the example code of "class BinaryMInstruction" and "class AccessMInstruction" (because we believe in you !!!),
* You need to complete other the member function, especially "output()" ,
* After that, you can use "output()" to print assembly code . */

class MachineUnit;
class MachineFunction;
class MachineBlock;
class MachineInstruction;

class MachineOperand
{
private:
    MachineInstruction* parent;
    MachineInstruction* def=nullptr;
    int type;
    int val;  // value of immediate number
    int reg_no; // register no
    std::string label; // address label

    bool param = false;
    bool fpu = false;  // floating point
    float fval;
    // 用于计算栈内偏移
    int paramNo;
    int allParamNo;

public:
    enum { IMM, VREG, REG, LABEL };
    MachineOperand(int tp, int val,bool fpu=0);
    MachineOperand(int tp, float fval);
    MachineOperand(std::string label);
    bool operator == (const MachineOperand&) const;
    bool operator < (const MachineOperand&) const;
    bool isImm() { return this->type == IMM; }; 
    bool isReg() { return this->type == REG; };
    bool isVReg() { return this->type == VREG; };
    bool isLabel() { return this->type == LABEL; };
    int getVal() {return this->val; };
    float getFVal() {return this->fval; };
    int getReg() {return this->reg_no; };
    void setReg(int regno) {this->type = REG; this->reg_no = regno;};
    std::string getLabel() {return this->label; };
    void setParent(MachineInstruction* p) { this->parent = p; };
    MachineInstruction* getParent() { return this->parent;};
    void PrintReg();
    void output();
    void setVal(int val) { this->val = val; };
    void setParam(bool p=1) { param = p; }
    bool isParam() { return param; }
    void setParamNo(int no) { paramNo = no; }
    void setAllParamNo(int no) { allParamNo = no; }
    int getAllParamNo() { return allParamNo; }
    int getOffset() { return 4 * allParamNo; };
    void setDef(MachineInstruction* inst) { def = inst; };
    bool isFloat() { return this->fpu; }
};

class MachineInstruction
{
protected:
    MachineBlock* parent;
    int no;
    int type;  // Instruction type
    int cond = MachineInstruction::NONE;  // Instruction execution condition, optional !!
    int op;  // Instruction opcode
    // Instruction operand list, sorted by appearance order in assembly instruction
    std::vector<MachineOperand*> def_list;
    std::vector<MachineOperand*> use_list;
    void addDef(MachineOperand* ope) { def_list.push_back(ope); };
    void addUse(MachineOperand* ope) { use_list.push_back(ope); };
    
    // Print execution code after printing opcode
    void PrintCond();
public:
    enum instType { BINARY, LOAD, STORE, MOV, BRANCH, CMP, STACK, VCVT, VMRS };
    enum condType { EQ, NE, LT, LE , GT, GE, NONE };
    virtual void output() = 0;
    void setNo(int no) {this->no = no;};
    int getNo() {return no;};
    std::vector<MachineOperand*>& getDef() {return def_list;};
    std::vector<MachineOperand*>& getUse() {return use_list;};
    void insertBefore(MachineInstruction*);
    void insertAfter(MachineInstruction*);
    MachineBlock* getParent() const { return parent; };
    bool isBX() const { return type == BRANCH && op == 2; };
    bool isStore() const { return type == STORE; };
    bool isAdd() const { return type == BINARY && op == 0; };
    bool isLoad() const { return type == LOAD; };
    int getType() { return type; }
    int getOp() { return op; }
};

class BinaryMInstruction : public MachineInstruction
{
public:
    enum opType { ADD, SUB, MUL, DIV, MOD, AND, OR, VADD, VSUB, VMUL, VDIV };
    BinaryMInstruction(MachineBlock* p, int op, 
                    MachineOperand* dst, MachineOperand* src1, MachineOperand* src2, 
                    int cond = MachineInstruction::NONE);
    void output();
};


class LoadMInstruction : public MachineInstruction
{
    bool needModify;
public:
    enum opType { LDR, VLDR };
    LoadMInstruction(MachineBlock* p,int op,
                    MachineOperand* dst, MachineOperand* src1, MachineOperand* src2 = nullptr, 
                    int cond = MachineInstruction::NONE);
    void setNeedModify() { needModify = true; }
    bool isNeedModify() { return needModify; }
    void output();
};

class StoreMInstruction : public MachineInstruction
{
public:
    enum opType { STR, VSTR };
    StoreMInstruction(MachineBlock* p,int op,
                    MachineOperand* src1, MachineOperand* src2, MachineOperand* src3 = nullptr, 
                    int cond = MachineInstruction::NONE);
    void output();
};

class MovMInstruction : public MachineInstruction
{
public:
    enum opType { MOV, MVN, MOVT, VMOV, VMOVF32, MOVLSL, MOVLSR, MOVASR };
    MovMInstruction(MachineBlock* p, int op, 
                MachineOperand* dst, MachineOperand* src,
                int cond = MachineInstruction::NONE);
    void output();
};

class BranchMInstruction : public MachineInstruction
{
public:
    enum opType { B, BL, BX };
    BranchMInstruction(MachineBlock* p, int op, 
                MachineOperand* dst, 
                int cond = MachineInstruction::NONE);
    void output();
};

class CmpMInstruction : public MachineInstruction
{
public:
    enum opType { CMP, VCMP };
    CmpMInstruction(MachineBlock* p, int op,
                MachineOperand* src1, MachineOperand* src2, 
                int cond = MachineInstruction::NONE);
    void output();
};

// class StackMInstruction : public MachineInstruction
// {
// public:
//     enum opType { PUSH, POP, VPUSH, VPOP };
//     StackMInstruction(MachineBlock* p, int op, 
//                 MachineOperand* src,
//                 int cond = MachineInstruction::NONE);
//     StackMInstruction(MachineBlock* p,int op, 
//                 MachineOperand* src,
//                 MachineOperand* src2,
//                 std::vector<MachineOperand*> opds,
//                 int cond = MachineInstruction::NONE);
//     void output();
// };

class StackMInstruction : public MachineInstruction {
   public:
    enum opType { PUSH, POP, VPUSH, VPOP };
    StackMInstruction(MachineBlock* p,
                      int op,
                      std::vector<MachineOperand*> srcs,
                      MachineOperand* src = nullptr,
                      MachineOperand* src1 = nullptr,
                      int cond = MachineInstruction::NONE);
    void output();
};


class VcvtMInstruction : public MachineInstruction {
   public:
    enum opType { S2F, F2S };
    VcvtMInstruction(MachineBlock* p,
                     int op,
                     MachineOperand* dst,
                     MachineOperand* src,
                     int cond = MachineInstruction::NONE);
    void output();
};

class VmrsMInstruction : public MachineInstruction {
   public:
    VmrsMInstruction(MachineBlock* p);
    void output();
};


class MachineBlock
{
private:
    MachineFunction* parent;
    int no;  
    std::vector<MachineBlock *> pred, succ;
    std::vector<MachineInstruction*> inst_list;
    std::set<MachineOperand*> live_in;
    std::set<MachineOperand*> live_out;
    int cond;
    static int label;
public:
    std::vector<MachineInstruction*>& getInsts() {return inst_list;};
    std::vector<MachineInstruction*>::iterator begin() { return inst_list.begin(); };
    std::vector<MachineInstruction*>::iterator end() { return inst_list.end(); };
    std::vector<MachineInstruction*>::reverse_iterator rbegin() { return inst_list.rbegin(); };
    MachineBlock(MachineFunction* p, int no) { this->parent = p; this->no = no; };
    void InsertInst(MachineInstruction* inst) { this->inst_list.push_back(inst); };
    void addPred(MachineBlock* p) { this->pred.push_back(p); };
    void addSucc(MachineBlock* s) { this->succ.push_back(s); };
    std::set<MachineOperand*>& getLiveIn() {return live_in;};
    std::set<MachineOperand*>& getLiveOut() {return live_out;};
    std::vector<MachineBlock*>& getPreds() {return pred;};
    std::vector<MachineBlock*>& getSuccs() {return succ;};
    void output();
    
    int getSize() const { return inst_list.size(); };
    int getCmpCond() const { return cond; };
    void setCmpCond(int cond) { this->cond = cond; };
    MachineFunction* getParent() { return parent; };
};

class MachineFunction
{
private:
    MachineUnit* parent;
    std::vector<MachineBlock*> block_list;
    int stack_size;
    std::set<int> saved_regs;
    std::set<int> saved_fpregs;
    SymbolEntry* sym_ptr;
    int paramNum;
    bool need_align;
public:
    std::vector<MachineBlock*>& getBlocks() {return block_list;};
    std::vector<MachineBlock*>::iterator begin() { return block_list.begin(); };
    std::vector<MachineBlock*>::iterator end() { return block_list.end(); };
    MachineFunction(MachineUnit* p, SymbolEntry* sym_ptr);
    /* HINT:
    * Alloc stack space for local variable;
    * return current frame offset ;
    * we store offset in symbol entry of this variable in function AllocInstruction::genMachineCode()
    * you can use this function in LinearScan::genSpillCode() */
    int AllocSpace(int size) { this->stack_size += size; return this->stack_size; };
    void InsertBlock(MachineBlock* block) { this->block_list.push_back(block); };
    void addSavedRegs(int regno);
    void output();
    std::set<int> getRegs(){return saved_regs;};
    MachineUnit* getParent() { return parent; };
    int getParamNum() const { return paramNum; };
    bool needAlign() { return need_align; }

    std::vector<MachineOperand*> getSavedRegs();
    std::vector<MachineOperand*> getSavedFpRegs();

};

class MachineUnit
{
private:
    std::vector<MachineFunction*> func_list;
    std::vector<SymbolEntry*> global_list;
    void PrintGlobalDecl();
    int global_num=0;
    
public:
    std::vector<MachineFunction*>& getFuncs() {return func_list;};
    std::vector<MachineFunction*>::iterator begin() { return func_list.begin(); };
    std::vector<MachineFunction*>::iterator end() { return func_list.end(); };
    void InsertFunc(MachineFunction* func) { func_list.push_back(func);};
    void output();
    int getGlobalNum(){return global_num;}
    void insertGlobal(SymbolEntry*);
    void printGlobal();
};


#endif