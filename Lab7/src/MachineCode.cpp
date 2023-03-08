#include "MachineCode.h"
extern FILE* yyout;

int MachineBlock::label = 0;

MachineOperand::MachineOperand(int tp, int val,bool fpu)
{
    this->type = tp;
    this->fpu=fpu;
    if(tp == MachineOperand::IMM)
        this->val = val;
    else 
        this->reg_no = val;
}


MachineOperand::MachineOperand(int tp, float fval)
{
    this->type = tp;
    if (tp == MachineOperand::IMM) {
        this->fval = fval;
        this->fpu = true;
    } else {
        // error
    }
}

MachineOperand::MachineOperand(std::string label)
{
    this->type = MachineOperand::LABEL;
    this->label = label;
}

bool MachineOperand::operator==(const MachineOperand&a) const
{
    if (this->type != a.type)
        return false;
    if (this->type == IMM)
        return this->val == a.val;
    return this->reg_no == a.reg_no;
}

bool MachineOperand::operator<(const MachineOperand&a) const
{
    if(this->type == a.type)
    {
        if(this->type == IMM)
            return this->val < a.val;
        return this->reg_no < a.reg_no;
    }
    return this->type < a.type;

    if (this->type != a.type)
        return false;
    if (this->type == IMM)
        return this->val == a.val;
    return this->reg_no == a.reg_no;
}

void MachineOperand::PrintReg()
{
    if (reg_no >= 16) {
        int sreg_no = reg_no - 16;
        if (sreg_no <= 31) {
            fprintf(yyout, "s%d", sreg_no);
        } else if (sreg_no == 32) {
            fprintf(yyout, "FPSCR");
        }
    } else if (reg_no == 11) {
        fprintf(yyout, "fp");

    } else if (reg_no == 13) {
        fprintf(yyout, "sp");

    } else if (reg_no == 14) {
        fprintf(yyout, "lr");

    } else if (reg_no == 15) {
        fprintf(yyout, "pc");

    } else {
        fprintf(yyout, "r%d", reg_no);
    }
}

void MachineOperand::output() 
{
printma("MachineOperand");
    /* HINT：print operand
    * Example:
    * immediate num 1 -> print #1;
    * register 1 -> print r1;
    * lable addr_a -> print addr_a; */
    switch (this->type)
    {
    case IMM:
        fprintf(yyout, "#%d", this->val);
        break;
    case VREG:
        fprintf(yyout, "v%d", this->reg_no);
        break;
    case REG:
        PrintReg();
        break;
    case LABEL:
        if (this->label.substr(0, 2) == ".L")
            fprintf(yyout, "%s", this->label.c_str());
        else if (this->label.substr(0, 1) == "@")
            fprintf(yyout, "%s", this->label.c_str() + 1);
        else
            fprintf(yyout, "addr_%s%d", this->label.c_str(), parent->getParent()->getParent()->getParent()->getGlobalNum());
    default:
        break;
    }
}

void MachineInstruction::PrintCond()
{
    // TODO
    // B指令可以接上后缀,用来和cmp比较后待条件的跳转
    // cmp x0,x1 ;这里做比较,用来下面的b跳转做比较条件
    // b.lt label2  //lt小于时候跳转,上面cmp 比较练x0和x1,x0<x1成立,所以 b.lt会跳转
    switch (cond)
    {
    case LT:
        fprintf(yyout, "lt");
        break;
    case EQ:
        fprintf(yyout, "eq");
        break;
    case NE:
        fprintf(yyout, "ne");
        break;
    case GT:
        fprintf(yyout, "gt");
        break;
    case GE:
        fprintf(yyout, "ge");
        break;
    case LE:
        fprintf(yyout, "le");
        break;
    default:
        break;
    }
}


BinaryMInstruction::BinaryMInstruction(
    MachineBlock* p, int op, 
    MachineOperand* dst, MachineOperand* src1, MachineOperand* src2, 
    int cond)
{
    this->parent = p;
    this->type = MachineInstruction::BINARY;
    this->op = op;
    this->cond = cond;
    this->def_list.push_back(dst);
    this->use_list.push_back(src1);
    this->use_list.push_back(src2);
    dst->setParent(this);
    src1->setParent(this);
    src2->setParent(this);
}

void BinaryMInstruction::output() 
{
printma("BinaryMInstruction");
    // TODO: 
    // Complete other instructions
    switch (this->op)
    {
        case BinaryMInstruction::ADD:
            fprintf(yyout, "\tadd ");
            break;
        case BinaryMInstruction::SUB:
            fprintf(yyout, "\tsub ");
            break;
        case BinaryMInstruction::AND:
            fprintf(yyout, "\tand ");
            break;
        case BinaryMInstruction::OR:
            fprintf(yyout, "\torr ");
            break;
        case BinaryMInstruction::MUL:
            fprintf(yyout, "\tmul ");
            break;
        case BinaryMInstruction::DIV:
            fprintf(yyout, "\tsdiv ");
            break;
        case BinaryMInstruction::VADD:
            fprintf(yyout, "\tvadd.f32 ");
            break;
        case BinaryMInstruction::VSUB:
            fprintf(yyout, "\tvsub.f32 ");
            break;
        case BinaryMInstruction::VMUL:
            fprintf(yyout, "\tvmul.f32 ");
            break;
        case BinaryMInstruction::VDIV:
            fprintf(yyout, "\tvdiv.f32 ");
            break;
        default:
            break;
    }
    this->def_list[0]->output();
    fprintf(yyout, ", ");
    this->use_list[0]->output();
    fprintf(yyout, ", ");
    this->use_list[1]->output();
    fprintf(yyout, "\n");
}

LoadMInstruction::LoadMInstruction(MachineBlock* p,
                                   int op,
                                   MachineOperand* dst,
                                   MachineOperand* src1,
                                   MachineOperand* src2,
                                   int cond) {
    this->parent = p;
    this->type = MachineInstruction::LOAD;
    this->op = op;
    this->cond = cond;
    this->needModify = false;
    this->def_list.push_back(dst);
    this->use_list.push_back(src1);
    if (src2)
        this->use_list.push_back(src2);
    dst->setParent(this);
    src1->setParent(this);
    if (src2)
        src2->setParent(this);
    dst->setDef(this);

}

void LoadMInstruction::output()
{
printma("LoadMInstruction");
    if (op == LoadMInstruction::LDR) {
        fprintf(yyout, "\tldr ");
        this->def_list[0]->output();
        fprintf(yyout, ", ");

        // Load immediate num, eg: ldr r1, =8
        if (this->use_list[0]->isImm()) {
            if (this->use_list[0]->isFloat()) {
                float fval = this->use_list[0]->getFVal();
                uint32_t temp = reinterpret_cast<uint32_t&>(fval);
                fprintf(yyout, "=%u\n", temp);
            } else {
                fprintf(yyout, "=%d\n", this->use_list[0]->getVal());
            }
            return;
        }

        // Load address
        if (this->use_list[0]->isReg() || this->use_list[0]->isVReg())
            fprintf(yyout, "[");

        this->use_list[0]->output();
        if (this->use_list.size() > 1) {
            fprintf(yyout, ", ");
            this->use_list[1]->output();
        }

        if (this->use_list[0]->isReg() || this->use_list[0]->isVReg())
            fprintf(yyout, "]");
        fprintf(yyout, "\n");

    } else if (op == LoadMInstruction::VLDR) {
        fprintf(yyout, "\tvldr.32 ");
        this->def_list[0]->output();
        fprintf(yyout, ", ");
        // Load immediate num, eg: ldr r1, =8
        if (this->use_list[0]->isImm()) {
            if (this->use_list[0]->isFloat()) {
                float fval = this->use_list[0]->getFVal();
                uint32_t temp = reinterpret_cast<uint32_t&>(fval);
                fprintf(yyout, "=%u\n", temp);
            } else {
                fprintf(yyout, "=%d\n", this->use_list[0]->getVal());
            }
            return;
        }

        // Load address
        if (this->use_list[0]->isReg() || this->use_list[0]->isVReg())
            fprintf(yyout, "[");

        this->use_list[0]->output();
        if (this->use_list.size() > 1) {
            fprintf(yyout, ", ");
            this->use_list[1]->output();
        }

        if (this->use_list[0]->isReg() || this->use_list[0]->isVReg())
            fprintf(yyout, "]");
        fprintf(yyout, "\n");
    }
}

StoreMInstruction::StoreMInstruction(MachineBlock* p,int op,
    MachineOperand* src1, MachineOperand* src2, MachineOperand* src3, 
    int cond)
{
    // TODO
    this->parent = p;
    this->op = op;
    this->type = MachineInstruction::STORE;
    this->cond = cond;
    // this->def_list.push_back(dst);
    this->use_list.push_back(src1);
    this->use_list.push_back(src2);
    // dst->setParent(this);
    src1->setParent(this);
    src2->setParent(this);
    if(src3!=nullptr){
        this->use_list.push_back(src3);
        src3->setParent(this);
    }
}

void StoreMInstruction::output()
{
    printma("StoreMInstruction");
    if (op == StoreMInstruction::STR) {
        fprintf(yyout, "\tstr ");
        this->use_list[0]->output();
        fprintf(yyout, ", ");
        // store address
        if (this->use_list[1]->isReg() || this->use_list[1]->isVReg())
            fprintf(yyout, "[");
        this->use_list[1]->output();
        if (this->use_list.size() > 2) {
            fprintf(yyout, ", ");
            this->use_list[2]->output();
        }
        if (this->use_list[1]->isReg() || this->use_list[1]->isVReg())
            fprintf(yyout, "]");
        fprintf(yyout, "\n");
    } else if (op == StoreMInstruction::VSTR) {
        // TODO
        fprintf(yyout, "\tvstr.32 ");
        this->use_list[0]->output();
        fprintf(yyout, ", ");
        // store address
        if (this->use_list[1]->isReg() || this->use_list[1]->isVReg())
            fprintf(yyout, "[");
        this->use_list[1]->output();
        if (this->use_list.size() > 2) {
            fprintf(yyout, ", ");
            this->use_list[2]->output();
        }
        if (this->use_list[1]->isReg() || this->use_list[1]->isVReg())
            fprintf(yyout, "]");
        fprintf(yyout, "\n");
    }
}

MovMInstruction::MovMInstruction(MachineBlock* p, int op, 
    MachineOperand* dst, MachineOperand* src,
    int cond)
{
    // TODO
    this->parent = p;
    this->type = MachineInstruction::MOV;
    this->op = op;
    this->cond = cond;
    this->def_list.push_back(dst);
    this->use_list.push_back(src);
    dst->setParent(this);
    src->setParent(this);
}

void MovMInstruction::output() 
{
printma("MovMInstruction");
    switch (this->op) {
        case MovMInstruction::MOV:
        case MovMInstruction::MOVLSL:
        case MovMInstruction::MOVLSR:
        case MovMInstruction::MOVASR:
            fprintf(yyout, "\tmov");
            break;
        case MovMInstruction::MOVT:
            fprintf(yyout, "\tmovt");
            break;
        case MovMInstruction::VMOV:
            fprintf(yyout, "\tvmov");
            break;
        case MovMInstruction::VMOVF32:
            fprintf(yyout, "\tvmov.f32");
            break;
        default:
            break;
    }
    PrintCond();
    fprintf(yyout, " ");
    this->def_list[0]->output();
    fprintf(yyout, ", ");
    this->use_list[0]->output();
    if (op == MOVLSL) {
        fprintf(yyout, ", LSL");
        this->use_list[1]->output();
    }
    if (op == MOVLSR) {
        fprintf(yyout, ", LSR");
        this->use_list[1]->output();
    }
    if (op == MOVASR) {
        fprintf(yyout, ", ASR");
        this->use_list[1]->output();
    }
    fprintf(yyout, "\n");
}

BranchMInstruction::BranchMInstruction(MachineBlock* p, int op, 
    MachineOperand* dst, 
    int cond)
{
    // TODO
    this->parent = p;
    this->type = MachineInstruction::BRANCH;
    this->op = op;
    this->cond = cond;
    this->use_list.push_back(dst);
    dst->setParent(this);
}


void BranchMInstruction::output()
{
printma("BranchMInstruction");
    // TODO
    switch (op) {
        case B:
            fprintf(yyout, "\tb");
            PrintCond();
            fprintf(yyout, " ");
            this->use_list[0]->output();
            fprintf(yyout, "\n");
            break;
        case BL:
            fprintf(yyout, "\tbl");
            PrintCond();
            fprintf(yyout, " ");
            this->use_list[0]->output();
            fprintf(yyout, "\n");
            break;
        case BX:
            fprintf(yyout, "\tbx");
            PrintCond();
            fprintf(yyout, " ");
            this->use_list[0]->output();
            fprintf(yyout, "\n");
            break;
    }
}

CmpMInstruction::CmpMInstruction(MachineBlock* p,int op, MachineOperand* src1, MachineOperand* src2, 
    int cond)
{
    // TODO
    this->parent = p;
    this->type = MachineInstruction::CMP;
    this->op = op;
    this->cond = cond;
    p->setCmpCond(cond);
    this->use_list.push_back(src1);
    this->use_list.push_back(src2);
    src1->setParent(this);
    src2->setParent(this);
}

void CmpMInstruction::output()
{
    printma("CmpMInstruction");
    // TODO
    // Jsut for reg alloca test
    // delete it after test
    switch (this->op) {
        case CmpMInstruction::CMP:
            fprintf(yyout, "\tcmp ");
            break;
        case CmpMInstruction::VCMP:
            fprintf(yyout, "\tvcmp.f32 ");
            break;
        default:
            break;
    }
    this->use_list[0]->output();
    fprintf(yyout, ", ");
    this->use_list[1]->output();
    fprintf(yyout, "\n");
}

StackMInstruction::StackMInstruction(MachineBlock* p,int op,std::vector<MachineOperand*> srcs,
                MachineOperand* src,MachineOperand* src1,int cond) {
    this->parent = p;
    this->type = MachineInstruction::STACK;
    this->op = op;
    this->cond = cond;
    if (srcs.size()) {
        for (auto it = srcs.begin(); it != srcs.end(); it++) {
            this->use_list.push_back(*it);
        }
    }
    if (src) {
        this->use_list.push_back(src);
        src->setParent(this);
    }
    if (src1) {
        this->use_list.push_back(src1);
        src1->setParent(this);
    }
}

VcvtMInstruction::VcvtMInstruction(MachineBlock* p,
                                   int op,
                                   MachineOperand* dst,
                                   MachineOperand* src,
                                   int cond) {
    this->parent = p;
    this->type = MachineInstruction::VCVT;
    this->op = op;
    this->cond = cond;
    this->def_list.push_back(dst);
    this->use_list.push_back(src);
    dst->setParent(this);
    src->setParent(this);
    dst->setDef(this);
}

VmrsMInstruction::VmrsMInstruction(MachineBlock* p) {
    this->parent = p;
    this->type = MachineInstruction::VMRS;
}

void VmrsMInstruction::output() {
    fprintf(yyout, "\tvmrs APSR_nzcv, FPSCR\n");
}

void VcvtMInstruction::output() {
    switch (this->op) {
        case VcvtMInstruction::F2S:
            fprintf(yyout, "\tvcvt.s32.f32 ");
            break;
        case VcvtMInstruction::S2F:
            fprintf(yyout, "\tvcvt.f32.s32 ");
            break;
        default:
            break;
    }
    PrintCond();
    fprintf(yyout, " ");
    this->def_list[0]->output();
    fprintf(yyout, ", ");
    this->use_list[0]->output();
    fprintf(yyout, "\n");
}

// StackMInstruction::StackMInstruction(MachineBlock* p, int op, 
//     MachineOperand* src,
//     int cond)
// {
//     // TODO
//     this->parent = p;
//     this->type = MachineInstruction::STACK;
//     this->op = op;
//     this->cond = cond;
//     this->use_list.push_back(src);
//     src->setParent(this);
// }
// StackMInstruction::StackMInstruction(MachineBlock* p,int op, 
//     MachineOperand* src, MachineOperand* src2,
//     std::vector<MachineOperand*> opds, int cond)
// {
//     // TODO
//     this->parent = p;
//     this->type = MachineInstruction::STACK;
//     this->op = op;
//     this->cond = cond;
//     if (!opds.empty())
//         for (auto opd:opds)
//             this->use_list.push_back(opd);
//     this->use_list.push_back(src);
//     this->use_list.push_back(src2);
//     src->setParent(this);
//     src2->setParent(this);
// }

void StackMInstruction::output() {
    if (!this->use_list.empty()) {
        switch (op) {
            case PUSH:
                fprintf(yyout, "\tpush ");
                break;
            case POP:
                fprintf(yyout, "\tpop ");
                break;
            case VPUSH:
                fprintf(yyout, "\tvpush ");
                break;
            case VPOP:
                fprintf(yyout, "\tvpop ");
                break;
        }
        fprintf(yyout, "{");
        auto size = use_list.size();
        if (size <= 16) {
            this->use_list[0]->output();
            for (long unsigned int i = 1; i < use_list.size(); i++) {
                fprintf(yyout, ", ");
                this->use_list[i]->output();
            }
        } else {
            if (op == VPUSH) {
                this->use_list[0]->output();
                for (long unsigned int i = 1; i < 16; i++) {
                    fprintf(yyout, ", ");
                    this->use_list[i]->output();
                }
                fprintf(yyout, "}\n");
                fprintf(yyout, "\tvpush ");
                fprintf(yyout, "{");
                this->use_list[16]->output();
                for (long unsigned int i = 17; i < size; i++) {
                    fprintf(yyout, ", ");
                    this->use_list[i]->output();
                }
            } else if (op == VPOP) {
                this->use_list[16]->output();
                for (long unsigned int i = 17; i < size; i++) {
                    fprintf(yyout, ", ");
                    this->use_list[i]->output();
                }
                fprintf(yyout, "}\n");
                fprintf(yyout, "\tvpop ");
                fprintf(yyout, "{");
                this->use_list[0]->output();
                for (long unsigned int i = 1; i < 16; i++) {
                    fprintf(yyout, ", ");
                    this->use_list[i]->output();
                }
            }
        }
        fprintf(yyout, "}\n");
    }
}

MachineFunction::MachineFunction(MachineUnit* p, SymbolEntry* sym_ptr) 
{ 
    //FunctionType* func = (FunctionType*) sym_ptr->getType();
    this->parent = p; 
    this->sym_ptr = sym_ptr; 
    this->stack_size = 0;
    this->paramNum =
        ((FunctionType*)(sym_ptr->getType()))->getParamSe().size();

    auto paramsSe = ((FunctionType*)(sym_ptr->getType()))->getParamSe();

    int float_num = 0;
    int int_num = 0;
    int push_num = 0;
    for (auto se : paramsSe) {
        if (se->getType()->isFloat()) {
            float_num++;
        } else {
            int_num++;
        }
    }

    if (float_num > 4) {
        push_num += float_num - 4;
    }
    if (int_num > 4) {
        push_num += int_num - 4;
    }
    if (push_num % 2 != 0) {
        need_align = true;
    } else {
        need_align = false;
    }
};
void MachineFunction::addSavedRegs(int regno){
    // this->saved_regs.insert(regno);
    // if (regno <= 11 && regno % 2 != 0) {
    //     saved_regs.insert(regno + 1);
    // } else if (regno <= 11 && regno > 0 && regno % 2 == 0) {
    //     saved_regs.insert(regno - 1);
    // }
    if (regno < 16) {
        // Q&A about this alignment:
        // https://forums.raspberrypi.com/viewtopic.php?t=169192
        saved_regs.insert(regno);
        if (regno <= 11 && regno % 2 != 0) {
            saved_regs.insert(regno + 1);
        } else if (regno <= 11 && regno > 0 && regno % 2 == 0) {
            saved_regs.insert(regno - 1);
        }
    } else {
        saved_fpregs.insert(regno);
    }
}

void MachineBlock::output()
{
printma("MachineBlock");
    fprintf(yyout, ".L%d:\n", this->no);
    bool first = true;
    int count = 0;
    std::vector<MachineOperand*> regs;
    for (auto it:parent->getRegs()) 
    {
        MachineOperand * reg = new MachineOperand(MachineOperand::REG, it);
        regs.push_back(reg);
    }
    // int offset = (regs.size() + 2) * 4;
    int offset =
        (parent->getSavedRegs().size() + parent->getSavedFpRegs().size() + 2) *
        4;
    // int baseOffset = offset;
    for(auto it = inst_list.begin(); it != inst_list.end(); it++){
        // z1227 状态栈帧切换pop
        if ((*it)->isBX()) {
            auto fp = new MachineOperand(MachineOperand::REG, 11);
            auto lr = new MachineOperand(MachineOperand::REG, 14);
            auto cur_inst = new StackMInstruction(this, StackMInstruction::VPOP,
                                                  parent->getSavedFpRegs());
            cur_inst->output();
            cur_inst = new StackMInstruction(this, StackMInstruction::POP,
                                             parent->getSavedRegs(), fp, lr);
            cur_inst->output();
        }
        if (parent->getParamNum() > 4 && (*it)->isStore())
        {   
            MachineOperand* operand = (*it)->getUse()[0];
            if (operand->isReg() && operand->getReg() == 3) {
                if (first) {
                    first = false;
                } else {
                    auto fp = new MachineOperand(MachineOperand::REG, 11);
                    auto r3 = new MachineOperand(MachineOperand::REG, 3);
                    auto off =
                        new MachineOperand(MachineOperand::IMM, offset);
                    offset += 4;
                    auto cur_inst = new LoadMInstruction(this, LoadMInstruction::LDR,r3, fp, off);
                    cur_inst->output();
                }
            }
            else if (operand->isReg() && operand->getReg() == 20 &&
                       operand->isParam()) {
                if (parent->needAlign() && first) {
                    first = false;
                } else {
                    // floating point
                    auto fp = new MachineOperand(MachineOperand::REG, 11);
                    auto s4 = new MachineOperand(MachineOperand::REG, 20, true);
                    // 这里的getOffset需要检查
                    int temp = offset + operand->getOffset();
                    auto off = new MachineOperand(MachineOperand::IMM, temp);
                    // auto off = new MachineOperand(MachineOperand::IMM,
                    // offset); 
                    offset += 4;
                    auto cur_inst = new LoadMInstruction(
                        this, LoadMInstruction::VLDR, s4, fp, off);
                    cur_inst->output();
                }
            }
        }
        // if ((*it)->isStore()) {
        //     MachineOperand* operand = (*it)->getUse()[0];
        //     if (operand->isReg() && operand->getReg() == 3 &&
        //         operand->isParam()) {
        //         auto fp = new MachineOperand(MachineOperand::REG, 11);
        //         auto r3 = new MachineOperand(MachineOperand::REG, 3);
        //         int temp = baseOffset + operand->getOffset();
        //         auto off = new MachineOperand(MachineOperand::IMM, temp);
        //         // auto off = new MachineOperand(MachineOperand::IMM, offset);
        //         // offset += 4;
        //         auto cur_inst = new LoadMInstruction(
        //             this, LoadMInstruction::LDR, r3, fp, off);
        //         cur_inst->output();
        //     } else if (operand->isReg() && operand->getReg() == 20 &&
        //                operand->isParam()) {
        //         if (parent->needAlign() && first) {
        //             first = false;
        //         } else {
        //             // floating point
        //             auto fp = new MachineOperand(MachineOperand::REG, 11);
        //             auto s4 = new MachineOperand(MachineOperand::REG, 20, true);

        //             int temp = baseOffset + operand->getOffset();
        //             auto off = new MachineOperand(MachineOperand::IMM, temp);
        //             // auto off = new MachineOperand(MachineOperand::IMM,
        //             // offset); offset += 4;
        //             auto cur_inst = new LoadMInstruction(
        //                 this, LoadMInstruction::VLDR, s4, fp, off);
        //             cur_inst->output();
        //         }
        //     }
        // }
        if ((*it)->isAdd()) 
            {
                auto dst = (*it)->getDef()[0];
                auto src1 = (*it)->getUse()[0];
                if (dst->isReg() && dst->getReg() == 13 && src1->isReg() &&
                    src1->getReg() == 13 && (*(it + 1))->isBX()) {
                    // 注: 这里少了一条判断条件 && (iter+1)->isBX()
                    int size = parent->AllocSpace(0);
                    if (size < -255 || size > 255) {
                        auto r1 = new MachineOperand(MachineOperand::REG, 1);
                        auto off =
                            new MachineOperand(MachineOperand::IMM, size);
                        (new LoadMInstruction(nullptr, LoadMInstruction::LDR,r1, off))->output();
                        (*it)->getUse()[1]->setReg(1);
                    } else
                        (*it)->getUse()[1]->setVal(size);
                }
            }
        (*it)->output();
        count++;
        if (count % 500 == 0) {
            fprintf(yyout, "\tb .B%d\n", label);
            fprintf(yyout, ".LTORG\n");
            parent->getParent()->printGlobal();
            fprintf(yyout, ".B%d:\n", label++);
        }
    
    }
}
void MachineFunction::output()
{
printma("MachineFunction");
    // const char *func_name = this->sym_ptr->toStr().c_str() + 1;
    string func_name = this->sym_ptr->toStr().substr(1,this->sym_ptr->toStr().size()-1);
    fprintf(yyout, "\t.global %s\n", func_name.c_str());
    fprintf(yyout, "\t.type %s , %%function\n", func_name.c_str());
    fprintf(yyout, "%s:\n", func_name.c_str());
    // TODO
    /* Hint:
    *  1. Save fp
    *  2. fp = sp
    *  3. Save callee saved register
    *  4. Allocate stack space for local variable */
    
    // Traverse all the block in block_list to print assembly code.
    // for(auto iter : block_list)
    //     iter->output();
    std::vector<MachineOperand*> regs;
    for (auto it = saved_regs.begin(); it != saved_regs.end(); it++) {
        auto reg = new MachineOperand(MachineOperand::REG, *it);
        regs.push_back(reg);
    }
    auto fp = new MachineOperand(MachineOperand::REG, 11);
    auto sp = new MachineOperand(MachineOperand::REG, 13);
    auto lr = new MachineOperand(MachineOperand::REG, 14);
    (new StackMInstruction(nullptr, StackMInstruction::PUSH, getSavedRegs(), fp,
                           lr))
        ->output();
    (new StackMInstruction(nullptr, StackMInstruction::VPUSH, getSavedFpRegs()))
        ->output();
    (new MovMInstruction(nullptr, MovMInstruction::MOV, fp, sp))->output();
    
    int off = AllocSpace(0);
    // 这里%8不懂原理
    if (off % 8 != 0) {
        off = AllocSpace(4);
    }
    if (off) {
        auto size = new MachineOperand(MachineOperand::IMM, off);
        if (off < -255 || off > 255) {
            auto r4 = new MachineOperand(MachineOperand::REG, 4);
            (new LoadMInstruction(nullptr, LoadMInstruction::LDR, r4, size))
                ->output();
            (new BinaryMInstruction(nullptr, BinaryMInstruction::SUB, sp, sp,
                                    r4))
                ->output();
        } else {
            (new BinaryMInstruction(nullptr, BinaryMInstruction::SUB, sp, sp,
                                    size))
                ->output();
        }
    }

    int count = 0;
    for (auto block : block_list) {
        block->output();
        count += block->getSize();
        if(count > 160){
            fprintf(yyout, "\tb .F%d\n", parent->getGlobalNum());
            fprintf(yyout, ".LTORG\n");
            parent->printGlobal();
            fprintf(yyout, ".F%d:\n", parent->getGlobalNum()-1);
            count = 0;
        }
    }
    fprintf(yyout, "\n");
}
void MachineUnit::insertGlobal(SymbolEntry* se) 
{
    global_list.push_back(se);
}
void MachineUnit::PrintGlobalDecl()
{
    // TODO:
    // You need to print global variable/const declarition code;
    std::vector<int> constIdx;
    std::vector<int> zeroIdx;
    if (global_list.empty() == false)           //打印全局变量列表
        fprintf(yyout, ".data\n\n");
    for (long unsigned int i = 0; i < global_list.size(); i++) 
    {
        printma(global_list.size());
        IdentifierSymbolEntry* se = (IdentifierSymbolEntry*)global_list[i];
        if(se==nullptr)continue;
        if (se->isConstant()) 
        {
            constIdx.push_back(i);
        }  
        else if (se->isAllZero()) 
        {
            zeroIdx.push_back(i);
        } 
        else
        {
            fprintf(yyout, "\t.global %s\n", se->toStr().c_str());
            if(se->getType()->isArray()){
                int n = se->getType()->getSize() / 32;
                ArrayType* arrTy = (ArrayType*)(se->getType());
                fprintf(yyout, "\t.size %s, %d\n", se->toStr().c_str(), arrTy->getSize() / 8);
                fprintf(yyout, "%s:\n", se->toStr().c_str());
                if(arrTy->getEleType()->isInt()){
                    std::vector<int> arrayValue = arrTy->getValueVec();
                    for (int i = 0; i < arrayValue.size(); i++) {
                        fprintf(yyout, "\t.word %d\n", arrayValue[i]);
                    }
                }
                else if(arrTy->getEleType()->isFloat()){
                    std::vector<float> arrayValue = arrTy->getFloatValueVec();
                    for (int i = 0; i < arrayValue.size(); i++) {
                        float v=arrayValue[i];
                        uint32_t fval = reinterpret_cast<uint32_t&>(v);
                        fprintf(yyout, "\t.word %u\n", fval);
                    }
                }
            }else{
                fprintf(yyout, "\t.size %s, %d\n", se->toStr().c_str(), se->getType()->getSize() / 8);
                fprintf(yyout, "%s:\n", se->toStr().c_str());
                if(se->getType()->isFloat()){
                    float v=se->getFloatValue();
                    uint32_t fval = reinterpret_cast<uint32_t&>(v);
                    fprintf(yyout, "\t.word %u\n", fval);
                }
                else
                    fprintf(yyout, "\t.word %d\n", se->getIntValue());
            }
        }
    }
    if (zeroIdx.empty() == false) 
    {
        for (long unsigned int i = 0; i < zeroIdx.size(); i++) 
        {
            IdentifierSymbolEntry* se = (IdentifierSymbolEntry*)global_list[zeroIdx[i]];
            if (se->getType()->isArray()) 
            {
                ArrayType *arr=(ArrayType *)se->getType();
                arr->setSize();
                fprintf(yyout, "\t.comm %s, %d, 4\n", se->toStr().c_str(), se->getType()->getSize() / 8);
            }
        }
    }
    if (constIdx.empty() == false) 
    {        //打印常量列表
        fprintf(yyout, ".section .rodata\n\n");
        for (long unsigned int i = 0; i < constIdx.size(); i++) 
        {
            IdentifierSymbolEntry* se = (IdentifierSymbolEntry*)global_list[constIdx[i]];
            fprintf(yyout, "\t.global %s\n", se->toStr().c_str());
            if(se->getType()->isArray()){
                ArrayType* arrTy = (ArrayType*)(se->getType());
                fprintf(yyout, "\t.size %s, %d\n", se->toStr().c_str(), arrTy->getSize() / 8);
                fprintf(yyout, "%s:\n", se->toStr().c_str());
                if(arrTy->getEleType()->isInt()){
                    std::vector<int> arrayValue = arrTy->getValueVec();
                    for (int i = 0; i < arrayValue.size(); i++) {
                        fprintf(yyout, "\t.word %d\n", arrayValue[i]);
                    }
                }
                else if(arrTy->getEleType()->isFloat()){
                    std::vector<float> arrayValue = arrTy->getFloatValueVec();
                    for (int i = 0; i < arrayValue.size(); i++) {
                        float v=arrayValue[i];
                        uint32_t fval = reinterpret_cast<uint32_t&>(v);
                        fprintf(yyout, "\t.word %u\n", fval);
                    }
                }
            }else{
                fprintf(yyout, "\t.size %s, %d\n", se->toStr().c_str(), se->getType()->getSize() / 8);
                fprintf(yyout, "%s:\n", se->toStr().c_str());

                if(se->getType()->isFloat()){
                    float v=se->getFloatValue();
                    uint32_t fval = reinterpret_cast<uint32_t&>(v);
                    fprintf(yyout, "\t.word %u\n", fval);
                }
                else
                    fprintf(yyout, "\t.word %d\n", se->getIntValue());
                
            }
        }
    }
}

void MachineUnit::output()
{
printma("MachineUnit");
    // TODO
    /* Hint:
    * 1. You need to print global variable/const declarition code;
    * 2. Traverse all the function in func_list to print assembly code;
    * 3. Don't forget print bridge label at the end of assembly code!! */
    fprintf(yyout, "\t.cpu cortex-a72\n");
    fprintf(yyout, "\t.arch armv8-a\n");
    fprintf(yyout, "\t.fpu vfpv3-d16\n");
    fprintf(yyout, "\t.arch_extension crc\n");
    PrintGlobalDecl();
    fprintf(yyout, "\t.text\n");
    for(auto iter : func_list)
        iter->output();
    printGlobal();
    fprintf(yyout, "\t.ident \"zm\"\n");
}
void MachineUnit::printGlobal(){
    for (auto s : global_list) {
        IdentifierSymbolEntry* se = (IdentifierSymbolEntry*)s;
        fprintf(yyout, "addr_%s%d:\n", se->toStr().c_str(), global_num);
        fprintf(yyout, "\t.word %s\n", se->toStr().c_str());
    }
    global_num++;
    // std::cout<<"global_num "<<global_num<<"\n";
}

void MachineInstruction::insertBefore(MachineInstruction* inst) {
    auto& instructions = parent->getInsts();
    auto it = std::find(instructions.begin(), instructions.end(), this);
    instructions.insert(it, inst);
}

void MachineInstruction::insertAfter(MachineInstruction* inst) {
    auto& instructions = parent->getInsts();
    auto it = std::find(instructions.begin(), instructions.end(), this);
    instructions.insert(++it, inst);
}

std::vector<MachineOperand*> MachineFunction::getSavedRegs() {
    std::vector<MachineOperand*> regs;
    for (auto it = saved_regs.begin(); it != saved_regs.end(); it++) {
        // remove r3..
        // if (*it < 4)
        //     continue;
        auto reg = new MachineOperand(MachineOperand::REG, *it);
        regs.push_back(reg);
    }
    return regs;
}

std::vector<MachineOperand*> MachineFunction::getSavedFpRegs() {
    int min_regno = 31 + 16;
    int max_regno = 0 + 16;
    for (auto it = saved_fpregs.begin(); it != saved_fpregs.end(); it++) {
        if (*it > max_regno) {
            max_regno = *it;
        }
        if (*it < min_regno) {
            min_regno = *it;
        }
    }
    min_regno = 4 + 16;

    int cnt = max_regno - min_regno + 1;
    if (cnt % 2 != 0) {
        max_regno += 1;
    }

    std::vector<MachineOperand*> regs;
    for (int i = min_regno; i <= max_regno; ++i) {
        auto reg = new MachineOperand(MachineOperand::REG, i, true);
        regs.push_back(reg);
    }
    return regs;
}