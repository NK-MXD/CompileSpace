#ifndef __INSTRUCTION_H__
#define __INSTRUCTION_H__

#include "Operand.h"
#include "AsmBuilder.h"
#include "Type.h"
#include <vector>
#include <map>

class BasicBlock;

class Instruction
{
public:
    Instruction(unsigned instType, BasicBlock *insert_bb = nullptr);
    virtual ~Instruction();
    BasicBlock *getParent();
    unsigned getInstType() const {return instType; };
    unsigned getOpcode() const {return opcode; };
    bool isUncond() const { return instType == UNCOND; };
    bool isCond() const { return instType == COND; };
    bool isRet() const { return instType == RET; };
    bool isAlloc() const {return instType == ALLOCA;};
    bool isGep() const { return instType == GEP; };
    bool isCall() const { return instType == CALL; };
    bool isLOAD() const { return instType == LOAD; };
    bool isCMP() const { return instType == CMP; };
    bool isZEXT() const { return instType == ZEXT; };
    bool isStore() const { return instType == STORE; };
    bool isVoid() { return (instType == RET) || (instType == COND) || (instType == UNCOND) || (instType == STORE) || (instType == CALL); };
    void setParent(BasicBlock *);
    void setNext(Instruction *);
    void setPrev(Instruction *);
    Instruction *getNext();
    Instruction *getPrev();
    std::vector<Operand *> &getOp(){return operands;};
    virtual void output() const = 0;
    MachineOperand* genMachineOperand(Operand*);
    MachineOperand* genMachineFloatOperand(Operand*);
    MachineOperand* genMachineReg(int reg);
    MachineOperand* genMachineVReg(bool fpu = false);
    MachineOperand* genMachineFReg(int freg);
    MachineOperand* genMachineImm(int val);
    MachineOperand* genMachineLabel(int block_no);
    virtual void genMachineCode(AsmBuilder*) = 0;
    bool isEssential();
    void setMark() { mark = true; }
    void unsetMark() { mark = false; }
    bool isMark() const { return mark; }
    virtual std::vector<Operand*> getUse() { return std::vector<Operand*>(); }
    virtual Operand* getDef() { return nullptr; }
protected:
    unsigned instType;
    unsigned opcode;
    Instruction *prev;
    Instruction *next;
    BasicBlock *parent;
    std::vector<Operand *> operands;
    enum
    {
        BINARY,
        COND,
        UNCOND,
        RET,
        LOAD,
        STORE,
        CMP,
        ALLOCA,
        CALL,
        GEP,
        XOR,
        ZEXT,
        BITCAST,
        FPTOSI,  // floating point to signed int
        SITOFP,  // signed int to floating point
    };
    bool mark;
};
//添加NOT异或运算
class XorInstruction : public Instruction {
public:
    XorInstruction(Operand* dst, Operand* src, BasicBlock* insert_bb = nullptr);
    ~XorInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    Operand* getDef() { return operands[0]; }
};


// meaningless instruction, used as the head node of the instruction list.
class DummyInstruction : public Instruction
{
public:
    DummyInstruction() : Instruction(-1, nullptr){};
    void output() const {};
    void genMachineCode(AsmBuilder*) {};
};

class FuncCallInstruction : public Instruction
{
public:
    SymbolEntry* rParams;
    // z0101
    Operand* dst;
    FuncCallInstruction(Operand* dst, SymbolEntry* se, std::vector<Operand*> rParams, BasicBlock* insert_bb = nullptr);    
    void output() const;
    void genMachineCode(AsmBuilder*);
    Operand* getDef() { return operands[0]; }
    SymbolEntry* getSymbolEmpty() { return se; }
private:
    SymbolEntry *se;
};

class AllocaInstruction : public Instruction
{
public:
    AllocaInstruction(Operand *dst, SymbolEntry *se, BasicBlock *insert_bb = nullptr);
    ~AllocaInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    Operand* getDef() { return operands[0]; }
private:
    SymbolEntry *se;
};

class LoadInstruction : public Instruction
{
    int align;
    bool flag;
public:
    LoadInstruction(Operand *dst, Operand *src_addr, BasicBlock *insert_bb = nullptr,int align=4);
    ~LoadInstruction();
    void output() const;
    void setFlag(bool f){this->flag=f;}
    void genMachineCode(AsmBuilder*);
    std::vector<Operand*> getUse() {
        return std::vector<Operand*>({operands[1]});
    }
    Operand* getDef() { return operands[0]; }
};

class StoreInstruction : public Instruction
{
    int align;
public:
    StoreInstruction(Operand *dst_addr, Operand *src, BasicBlock *insert_bb = nullptr,int align=4);
    ~StoreInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    std::vector<Operand*> getUse() {
        return std::vector<Operand*>({operands[0], operands[1]});
    }
};

class BinaryInstruction : public Instruction
{
public:
    BinaryInstruction(unsigned opcode, Operand *dst, Operand *src1, Operand *src2, BasicBlock *insert_bb = nullptr);
    ~BinaryInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    enum { SUB, ADD, AND, OR, MUL, DIV, MOD };
    std::vector<Operand*> getUse() {
        return std::vector<Operand*>({operands[1], operands[2]});
    }
    Operand* getDef() { return operands[0]; }
};

class CmpInstruction : public Instruction
{
public:
    CmpInstruction(unsigned opcode, Operand *dst, Operand *src1, Operand *src2, BasicBlock *insert_bb = nullptr);
    ~CmpInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    enum
    {
        E, NE, L, LE, G, GE
    };
    std::vector<Operand*> getUse() {
        return std::vector<Operand*>({operands[1], operands[2]});
    }
    Operand* getDef() { return operands[0]; }
};
class ZextInstruction : public Instruction {
public:
    ZextInstruction(Operand* dst,
                    Operand* src,
                    BasicBlock* insert_bb = nullptr);
    void output() const;
    void genMachineCode(AsmBuilder*);
    Operand* getDef() { return operands[0]; }
};
// unconditional branch
class UncondBrInstruction : public Instruction
{
public:
    UncondBrInstruction(BasicBlock *, BasicBlock *insert_bb = nullptr);
    void output() const;
    void setBranch(BasicBlock *);
    BasicBlock *getBranch();
    void genMachineCode(AsmBuilder*);
protected:
    BasicBlock *branch;
};

// conditional branch
class CondBrInstruction : public Instruction
{
public:
    CondBrInstruction(BasicBlock *, BasicBlock *, Operand *, BasicBlock *insert_bb = nullptr);
    ~CondBrInstruction();
    void output() const;
    Operand *cond;
    void setTrueBranch(BasicBlock *);
    BasicBlock *getTrueBranch();
    void setFalseBranch(BasicBlock *);
    BasicBlock *getFalseBranch();
    void genMachineCode(AsmBuilder*);
    std::vector<Operand*> getUse() {
        return std::vector<Operand*>({operands[0]});
    }
protected:
    BasicBlock *true_branch;
    BasicBlock *false_branch;
};

class RetInstruction : public Instruction
{
public:
    RetInstruction(Operand *src, BasicBlock *insert_bb = nullptr);
    ~RetInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    std::vector<Operand*> getUse() {
        if (operands.size())
            return std::vector<Operand*>({operands[0]});
        return std::vector<Operand*>();
    }
};
class GepInstruction : public Instruction
{
private:
    bool param=0;
    Operand *init;
    bool idxFlag=1;
    bool idxFirst=0;
    bool idxLast=0;

public:
    GepInstruction(Operand *dst, Operand *src,BasicBlock *insert_bb = nullptr,Operand *idx=nullptr);
    ~GepInstruction();
    void output() const;
    void setIdxFirst(bool b){idxFirst=b;}
    void setIdxLast(bool b){idxLast=b;}
    void setParam(bool p){param=p;}
    bool isParam(){return param;}
    void genMachineCode(AsmBuilder*);
    Operand* getInit() const { return init; };
    void setInit(Operand* init) { this->init = init; };
    Operand* getDef() { return operands[0]; }
};

class BitcastInstruction : public Instruction {
   private:
    Operand* dst;
    Operand* src;
    bool flag;

   public:
    BitcastInstruction(Operand* dst,
                       Operand* src,
                       BasicBlock* insert_bb = nullptr);
    ~BitcastInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    std::vector<Operand*> getUse() {
        return std::vector<Operand*>({operands[1]});
    }
    bool genNode();
    Instruction* copy();
    Operand* getDef() { return operands[0]; }
    void setDef(Operand* def) {
        operands[0] = def;
        dst = def;
        def->setDef(this);
    }
    void replaceUse(Operand* old, Operand* new_);
    void setFlag() { flag = true; }
    bool getFlag() { return flag; }
};

class FptosiInstruction : public Instruction {
   private:
    Operand* dst;
    Operand* src;

   public:
    FptosiInstruction(Operand* dst,
                      Operand* src,
                      BasicBlock* insert_bb = nullptr);
    ~FptosiInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    Operand* getDef() { return operands[0]; }
};

class SitofpInstruction : public Instruction {
   private:
    Operand* dst;
    Operand* src;

   public:
    SitofpInstruction(Operand* dst,
                      Operand* src,
                      BasicBlock* insert_bb = nullptr);
    ~SitofpInstruction();
    void output() const;
    void genMachineCode(AsmBuilder*);
    Operand* getDef() { return operands[0]; }
};

#endif