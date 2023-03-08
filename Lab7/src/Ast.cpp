#include "Ast.h"
#include "SymbolTable.h"
#include <string>
#include "Type.h"
#include "Unit.h"
#include "Instruction.h"
#include "IRBuilder.h"
extern FILE *yyout;
int Node::counter = 0;
IRBuilder *Node::builder = nullptr;
// AsmBuilder *Node::mbuilder = nullptr;
BasicBlock *end_bb_cur = nullptr;

void Node::backPatch(std::vector<Instruction *> &list, BasicBlock *bb)
{
    for (auto &inst : list)
    {
        if (inst->isCond())
            dynamic_cast<CondBrInstruction *>(inst)->setTrueBranch(bb);
        else if (inst->isUncond())
        {
            dynamic_cast<UncondBrInstruction *>(inst)->setBranch(bb);
        }
    }
}

std::vector<Instruction *> Node::merge(std::vector<Instruction *> &list1, std::vector<Instruction *> &list2)
{
    std::vector<Instruction *> res(list1);
    res.insert(res.end(), list2.begin(), list2.end());
    return res;
}

void Ast::genCode(Unit *unit)
{
    IRBuilder *builder = new IRBuilder(unit);
    Node::setIRBuilder(builder);

    printg("AST");
    root->genCode();
}

void FunctionDef::genCode()
{
    printg("FunctionDef");
    Unit *unit = builder->getUnit();
    Function *func = new Function(unit, se);
    BasicBlock *entry = func->getSymbolEntry();
    // set the insert point to the entry basicblock of this function.
    // SymbolTable::resetLabel();
    builder->setInsertBB(entry);
    Type *type = dynamic_cast<FunctionType *>(se->getType())->getRetType();
    // 不需要return
    // TemporarySymbolEntry *temp = new TemporarySymbolEntry(type, SymbolTable::getLabel());
    // Operand *temp_op = new Operand(temp);
    // if (type != TypeSystem::voidType)
    // {
    //     AllocaInstruction *alloca = new AllocaInstruction(temp_op, temp);
    //     entry->insertFront(alloca);
    // }

    printg("==========entry=========");
    printg(se->toStr().c_str());

    printg("== before decl gen ==");
    if (decl)
        decl->genCode();
    printg("== after decl gen == ");
    // function中的stmt节点是用compoundstmt进行初始化的
    printg("== before stmt gen ==");
    if (stmt)
    {
        stmt->genCode();
    }
    printg("== after stmt gen == ");
    /**
     * Construct control flow graph. You need do set successors and predecessors for each basic block.
     * Todo
     */

    BasicBlock *bb = builder->getInsertBB();
    // if (bb->empty() && type != TypeSystem::voidType)
    // {
        // Operand *addr = dynamic_cast<IdentifierSymbolEntry *>(temp)->getAddr();
        // SymbolEntry *temp3 = new TemporarySymbolEntry(type, SymbolTable::getLabel());
        // SymbolEntry *temp2 = new TemporarySymbolEntry(new PointerType(type), temp->getLabel());
        // Operand *temp_op2 = new Operand(temp2);
        // Operand *temp_op3 = new Operand(temp3);
        // new LoadInstruction(temp_op3, temp_op2, bb);
        // new RetInstruction(temp_op3, bb);
    // }
    if (bb->empty() && type == TypeSystem::voidType)
    {
        new RetInstruction(nullptr, bb);
    }
    else if (!bb->rbegin()->isRet() && type == TypeSystem::voidType)
    {
        new RetInstruction(nullptr, bb);
    }
    printg("out funcdef");
}

void BinaryExpr::genCode()
{
    // const直接结束
    printg("++++++++++++++++++++++++++++++++++++++BinaryInstruction");
    if (this->getSymbolEntry()->isConstant())
        return;
    BasicBlock *bb = builder->getInsertBB();
    // BasicBlock *then_BB, *end_BB;
    Function *func = bb->getParent();

    if (op == AND)
    {
        expr1->genCode();
        BasicBlock *thenBB, *endBB;
        thenBB = new BasicBlock(func);
        endBB = new BasicBlock(func);
        thenBB->addPred(builder->getInsertBB());
        builder->getInsertBB()->addSucc(thenBB); 
        // endBB->addPred(thenBB);
        // thenBB->addSucc(endBB);
        backPatch(expr1->trueList(), thenBB);
        Type *btype = getBasicType(expr1->getSymbolEntry());
        if (btype == TypeSystem::intType || btype == TypeSystem::boolType)
        {
            Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, tem, expr1->getOperand(),
                new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                builder->getInsertBB());
            new CondBrInstruction(thenBB, endBB, tem, builder->getInsertBB());
        }
        else if (btype == TypeSystem::floatType)
        {
            Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, tem, expr1->getOperand(),
                new Operand(new ConstantSymbolEntry(TypeSystem::floatType, 0)),
                builder->getInsertBB());
            new CondBrInstruction(thenBB, endBB, tem, builder->getInsertBB());
        }
        else
        {
            new CondBrInstruction(thenBB, endBB, expr1->getOperand(), builder->getInsertBB());
        }

        builder->setInsertBB(thenBB); // set the insert point to the trueBB so that intructions generated by expr2 will be inserted into it.
        expr2->genCode();
        new UncondBrInstruction(endBB, builder->getInsertBB());
        endBB->addPred(builder->getInsertBB());
        builder->getInsertBB()->addSucc(endBB);

        builder->setInsertBB(endBB);
        if (endBB->empty())
        {
            // 这个的计算方式用expr1->getOperand()&expr2->getOperand()来生成
            int op = BinaryInstruction::AND;
            Operand *temp = new Operand(new TemporarySymbolEntry(
                TypeSystem::boolType, SymbolTable::getLabel()));
            Operand *tem1, *tem2;
            if (expr1->getSymbolEntry()->getType() != TypeSystem::boolType)
            {
                tem1 = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
                new CmpInstruction(
                    CmpInstruction::NE, tem1, expr1->getOperand(),
                    new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                    builder->getInsertBB());
            }
            else
            {
                tem1 = expr1->getOperand();
            }
            if (expr2->getSymbolEntry()->getType() != TypeSystem::boolType)
            {
                tem2 = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
                new CmpInstruction(
                    CmpInstruction::NE, tem2, expr2->getOperand(),
                    new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                    builder->getInsertBB());
            }
            else
            {
                tem2 = expr2->getOperand();
            }
            new BinaryInstruction(op, temp, tem1, tem2, builder->getInsertBB());
            new CmpInstruction(
                CmpInstruction::E, temp, temp,
                new Operand(new ConstantSymbolEntry(TypeSystem::intType, 1)),
                builder->getInsertBB());
            // new BinaryInstruction(op, temp, expr1->getOperand(), expr2->getOperand(), builder->getInsertBB());
            this->dst = temp;
        }
        true_list = expr2->trueList();
        false_list = merge(expr1->falseList(), expr2->falseList());
    }
    else if (op == OR)
    {

        expr1->genCode();
        BasicBlock *thenBB, *endBB;
        thenBB = new BasicBlock(func);
        endBB = new BasicBlock(func);
        thenBB->addPred(builder->getInsertBB());
        builder->getInsertBB()->addSucc(thenBB);
        // endBB->addPred(thenBB);
        // thenBB->addSucc(endBB);

        backPatch(expr1->falseList(), thenBB);
        Type *btype = getBasicType(expr1->getSymbolEntry());
        if (btype == TypeSystem::intType || btype == TypeSystem::boolType)
        {
            Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, tem, expr1->getOperand(),
                new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                builder->getInsertBB());
            new CondBrInstruction(endBB, thenBB, tem, builder->getInsertBB());
        }
        else if (btype == TypeSystem::floatType)
        {
            Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, tem, expr1->getOperand(),
                new Operand(new ConstantSymbolEntry(TypeSystem::floatType, 0)),
                builder->getInsertBB());
            new CondBrInstruction(endBB, thenBB, tem, builder->getInsertBB());
        }
        else
        {
            new CondBrInstruction(endBB, thenBB, expr1->getOperand(), builder->getInsertBB());
        }
        // new CondBrInstruction(endBB, thenBB, expr1->getOperand(), builder->getInsertBB());

        builder->setInsertBB(thenBB);
        expr2->genCode();
        new UncondBrInstruction(endBB, builder->getInsertBB());
        endBB->addPred(builder->getInsertBB());
        builder->getInsertBB()->addSucc(endBB);

        builder->setInsertBB(endBB);

        if (endBB->empty())
        {
            // 这个的计算方式用expr1->getOperand()|expr2->getOperand()来生成
            int op = BinaryInstruction::OR;
            Operand *temp = new Operand(new TemporarySymbolEntry(
                TypeSystem::boolType, SymbolTable::getLabel()));
            Operand *tem1, *tem2;
            if (expr1->getSymbolEntry()->getType() != TypeSystem::boolType)
            {
                tem1 = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
                new CmpInstruction(
                    CmpInstruction::NE, tem1, expr1->getOperand(),
                    new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                    builder->getInsertBB());
            }
            else
            {
                tem1 = expr1->getOperand();
            }
            if (expr2->getSymbolEntry()->getType() != TypeSystem::boolType)
            {
                tem2 = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
                new CmpInstruction(
                    CmpInstruction::NE, tem2, expr2->getOperand(),
                    new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                    builder->getInsertBB());
            }
            else
            {
                tem2 = expr2->getOperand();
            }
            new BinaryInstruction(op, temp, tem1, tem2, builder->getInsertBB());
            new CmpInstruction(
                CmpInstruction::NE, temp, temp,
                new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                builder->getInsertBB());
            // new BinaryInstruction(op, temp, expr1->getOperand(), expr2->getOperand(), builder->getInsertBB());
            dst = temp;
        }
        true_list = merge(expr1->trueList(), expr2->trueList());
        false_list = expr2->falseList();
        // new CondBrInstruction(true_bb, end_bb, dst, bb);
    }

    else if (op >= LESS && op <= NOTEQUAL)
    {
        printg("++++++++++++++++++++++++++++++++++++++LESS");
        Type *type1 = getBasicType(expr1->getSymbolEntry());
        Type *type2 = getBasicType(expr2->getSymbolEntry());
        if (type1->isFloat() && type2->isInt()) {
            ImplictCastExpr* temp =
                new ImplictCastExpr(expr2, TypeSystem::floatType);
            this->expr2 = temp;
        } else if (type1->isInt() && type2->isFloat()){
            ImplictCastExpr* temp =
                new ImplictCastExpr(expr1, TypeSystem::floatType);
            this->expr1 = temp;
            type = TypeSystem::floatType;
        }
        expr1->genCode();
        expr2->genCode();
        Operand *src1 = expr1->getOperand();
        Operand *src2 = expr2->getOperand();
        if (src1->getType() == TypeSystem::boolType)
        {
            Operand *dst = new Operand(new TemporarySymbolEntry(
                TypeSystem::intType, SymbolTable::getLabel()));
            new ZextInstruction(dst, src1, bb);
            src1 = dst;
        }
        if (src2->getType() == TypeSystem::boolType)
        {
            Operand *dst = new Operand(new TemporarySymbolEntry(
                TypeSystem::intType, SymbolTable::getLabel()));
            new ZextInstruction(dst, src2, bb);
            src2 = dst;
        }
        int cmpopcode;
        switch (op)
        {
        case LESS:
            cmpopcode = CmpInstruction::L;
            break;
        case LESSEQUAL:
            cmpopcode = CmpInstruction::LE;
            break;
        case GREATER:
            cmpopcode = CmpInstruction::G;
            break;
        case GREATEREQUAL:
            cmpopcode = CmpInstruction::GE;
            break;
        case EQUAL:
            cmpopcode = CmpInstruction::E;
            break;
        case NOTEQUAL:
            cmpopcode = CmpInstruction::NE;
            break;
        }
        new CmpInstruction(cmpopcode, dst, src1, src2, bb);
    }
    else if (op >= ADD && op <= MOD)
    {
        printg("++++++++++++++++++++++++++++++++++++++ADD");
        Type *type1 = getBasicType(expr1->getSymbolEntry());
        Type *type2 = getBasicType(expr2->getSymbolEntry());
        if (type1->isFloat() && type2->isInt()) {
            ImplictCastExpr* temp =
            new ImplictCastExpr(expr2, TypeSystem::floatType);
            this->expr2 = temp;
            type = TypeSystem::floatType;
        }
        else if (type1->isInt() && type2->isFloat()) {
            ImplictCastExpr* temp =
            new ImplictCastExpr(expr1, TypeSystem::floatType);
            this->expr1 = temp;
            type = TypeSystem::floatType;
        }
        else if (type1->isFloat() && type2->isFloat()) {
            type = TypeSystem::floatType;
        } else {
            type = TypeSystem::intType;
        }
        expr1->genCode();
        expr2->genCode();
        printinfo("cal gencode");
        Operand *src1 = expr1->getOperand();
        Operand *src2 = expr2->getOperand();
        int opcode;
        switch (op)
        {
        case ADD:
            opcode = BinaryInstruction::ADD;
            break;
        case SUB:
            opcode = BinaryInstruction::SUB;
            break;
        case MUL:
            opcode = BinaryInstruction::MUL;
            break;
        case DIV:
            opcode = BinaryInstruction::DIV;
            break;
        case MOD:
            opcode = BinaryInstruction::MOD;
            break;
        }
        new BinaryInstruction(opcode, dst, src1, src2, bb);
    }
    printg("------------------------------------BinaryInstruction");
}

void Constant::genCode()
{
    printg("Constant");

    // we don't need to generate code.
}

void Id::genCode()
{
    printg("== id : " << name << " ==\n");
    // if(this->getSymbolEntry()->isConstant())return;
    IdentifierSymbolEntry *se = (IdentifierSymbolEntry *)this->getSymbolEntry();
    BasicBlock *bb = builder->getInsertBB();
    Operand *addr = dynamic_cast<IdentifierSymbolEntry *>(symbolEntry)->getAddr();
    /* z1204 todo 需要区分浮点 */
    if (!isArray)
    {
        // if(!dynamic_cast<IdentifierSymbolEntry *>(symbolEntry)->isGlobal()&&!dynamic_cast<IdentifierSymbolEntry *>(symbolEntry)->isConstant())
        if (!isLeft)
            new LoadInstruction(dst, addr, bb);
        //}
    }
    // ref:https://buaa-se-compiling.github.io/miniSysY-tutorial/lab7/help.html
    /** GEP 指令的工作是“计算地址”，本身并不进行任何数据的访问和修改。
     * GEP 指令的最基本语法为 <result> = getelementptr <ty>, <ty>* <ptrval>, {<ty> <index>}*
     * 其中第一个 <ty> 表示第一个索引所指向的类型
     * 第二个 <ty> 表示后面的指针基址 <ptrval> 的类型，<ty> <index> 表示一组索引的类型和值。
     * 要注意索引的类型和索引指向的基本类型是不一样的，索引的类型一般为 i32 或 i64 ，而索引指向的基本类型确定的是增加索引值时指针的偏移量。
     */

    // z1204 todo 高维缺省怎么办?规范是什么？
    // z1204 todo 得区分下左值跟声明，那Id加个成员？
    // z1214 增加 bool isLeft=0;
    else
    {
        printg("start gep arr");
        ArrayType *arrType = (ArrayType *)this->getSymbolEntry()->getType();
        ArrayType *eletype = arrType;
        Operand *indice_dst = dst;
        Operand *indice_src = addr;
        bool first = 1;
        printg(eletype->toStr() << "\n");
        ExprNode *idx = index;
        if (arrFlag || idx == nullptr)
        {
            // 一维数组参数的idx为nullptr
            printg("idx == nullptr");
            TemporarySymbolEntry *tse = new TemporarySymbolEntry(eletype, SymbolTable::getLabel());
            indice_dst = new Operand(tse);
            // indice_dst = new Operand(new TemporarySymbolEntry(arrType->getEleType(), SymbolTable::getStillLabel()));
            if (se->isParam())
                new LoadInstruction(indice_dst, addr, bb);
            else
            {
                GepInstruction *gep = new GepInstruction(indice_dst, addr, bb, nullptr);
                gep->setIdxFirst(1);
            }

            // new LoadInstruction(indice_dst, dst, bb);
            // dst = new Operand(new TemporarySymbolEntry(
            //         new PointerType(arrType->getEleType()), SymbolTable::getLabel()));
            dst = new Operand(new TemporarySymbolEntry(
                new PointerType(arrType->getEleType()), tse->getLabel()));

            return;
        }
        int idxCnt = 0;
        for (; idx != nullptr;)
        {
            printg("idx+++++");
            idxCnt++;
            idx->genCode();
            printg("letype->getDimen() " << eletype->getDimen() << "\n");

            printg(eletype->toStr() << "\n");
            if (se->isParam() && first)
            {
                indice_src = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
                new LoadInstruction(indice_src, addr, bb, 8);
            }
            indice_dst = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
            indice_src->setType(eletype->getStripEleType());
            printg("==========================");
            eletype = (ArrayType *)eletype->getStripEleType();

            GepInstruction *gep = new GepInstruction(indice_dst, indice_src, bb, idx->getOperand());
            if (se->isParam())
            {
                gep->setParam(1);
                // idx->setNext(new ExprNode(new ConstantSymbolEntry(TypeSystem::intType, 0)));
            }
            if (first)
            {
                gep->setIdxFirst(1);
                first = 0;
            }
            indice_src = indice_dst;
            // eletype=(ArrayType *)eletype->getStripEleType();
            printg("idx--------");
            // std::cout<<arrType->getDimen();
            idx = (ExprNode *)idx->getNext();
        }

        if (!isLeft && idxCnt == arrType->getDimen())
        {
            dst = new Operand(new TemporarySymbolEntry(arrType->getEleType(), SymbolTable::getLabel()));
            new LoadInstruction(dst, indice_dst, bb);
        }
        else
            dst = new Operand(new TemporarySymbolEntry(new PointerType(arrType->getEleType()), SymbolTable::getStillLabel() - 1));
    }
}
void IfStmt::genCode()
{
    printg("IfStmt");
    BasicBlock *then_bb, *end_bb;

    Function *func = builder->getInsertBB()->getParent();
    then_bb = new BasicBlock(func);
    end_bb = new BasicBlock(func);

    cond->genCode();

    then_bb->addPred(builder->getInsertBB());
    builder->getInsertBB()->addSucc(then_bb);
    end_bb->addPred(then_bb);
    then_bb->addSucc(end_bb);

    backPatch(cond->trueList(), then_bb);
    backPatch(cond->falseList(), end_bb);
    if (end_bb->empty() && builder->getInsertBB()->succ_begin() == builder->getInsertBB()->pred_end())
    {
        new UncondBrInstruction(*builder->getInsertBB()->succ_begin(), end_bb);
    }
    if (cond->getSymbolEntry())
    {
        Type *btype = getBasicType(cond->getSymbolEntry());
        if (btype == TypeSystem::intType || btype == TypeSystem::boolType)
        {
            Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, tem, cond->getOperand(),
                new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                builder->getInsertBB());
            new CondBrInstruction(then_bb, end_bb, tem, builder->getInsertBB());
        }
        else if (btype == TypeSystem::floatType) {
            Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, tem, cond->getOperand(),
                new Operand(new ConstantSymbolEntry(TypeSystem::floatType, 0)),
                builder->getInsertBB());
            new CondBrInstruction(then_bb, end_bb, tem, builder->getInsertBB());
        }
        else
        {
            new CondBrInstruction(then_bb, end_bb, cond->getOperand(), builder->getInsertBB());
        }
    }
    builder->setInsertBB(then_bb);
    thenStmt->genCode();
    then_bb = builder->getInsertBB();
    // if(!end_bb->empty()){
    new UncondBrInstruction(end_bb, then_bb);
    // }else{
    //     end_bb->removePred(then_bb);
    //     then_bb->removeSucc(end_bb);
    // }

    builder->setInsertBB(end_bb);
}

void IfElseStmt::genCode()
{

    Function *func = builder->getInsertBB()->getParent();
    BasicBlock *then_bb, *end_bb, *else_bb;
    then_bb = new BasicBlock(func);
    end_bb = new BasicBlock(func);
    else_bb = new BasicBlock(func);

    then_bb->addPred(builder->getInsertBB());
    builder->getInsertBB()->addSucc(then_bb);
    end_bb->addPred(then_bb);
    then_bb->addSucc(end_bb);

    else_bb->addPred(builder->getInsertBB());
    builder->getInsertBB()->addSucc(else_bb);
    end_bb->addPred(else_bb);
    else_bb->addSucc(end_bb);

    cond->genCode();

    backPatch(cond->trueList(), then_bb);
    backPatch(cond->falseList(), else_bb);
    Type *btype = getBasicType(cond->getSymbolEntry());
    if (btype == TypeSystem::intType || btype == TypeSystem::boolType)
    {
        Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        new CmpInstruction(
            CmpInstruction::NE, tem, cond->getOperand(),
            new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
            builder->getInsertBB());
        new CondBrInstruction(then_bb, else_bb, tem, builder->getInsertBB());
    }
    else if (btype == TypeSystem::floatType) {
        Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        new CmpInstruction(
            CmpInstruction::NE, tem, cond->getOperand(),
            new Operand(new ConstantSymbolEntry(TypeSystem::floatType, 0)),
            builder->getInsertBB());
        new CondBrInstruction(then_bb, else_bb, tem, builder->getInsertBB());
    }
    else
    {
        new CondBrInstruction(then_bb, else_bb, cond->getOperand(), builder->getInsertBB());
    }

    builder->setInsertBB(then_bb);
    thenStmt->genCode();
    then_bb = builder->getInsertBB();
    // if(!end_bb->empty()){
    new UncondBrInstruction(end_bb, then_bb);
    // }else{
    //     end_bb->removePred(then_bb);
    //     then_bb->removeSucc(end_bb);
    // }

    builder->setInsertBB(else_bb);
    elseStmt->genCode();
    else_bb = builder->getInsertBB();
    // if(!end_bb->empty()){
    new UncondBrInstruction(end_bb, else_bb);
    builder->setInsertBB(end_bb);
    // }else{
    //     end_bb->removePred(else_bb);
    //     else_bb->removeSucc(end_bb);
    // }
}

void CompoundStmt::genCode()
{
    printg("CompoundStmt");
    if (stmt)
    {
        stmt->genCode();
    }
}

void SeqNode::genCode()
{
    printg("SeqNode");
    if (stmt1)
        stmt1->genCode();
    if (stmt2)
        stmt2->genCode();
}
void ExprStmt::genCode()
{
    printg("ExprStmt");
    // Todo
    expr->genCode();
}
void FuncCall::genCode()
{
    printg("FuncCall");
    // Todo
    std::vector<Operand *> rParams;
    IdentifierSymbolEntry* se=(IdentifierSymbolEntry*)symbolEntry;
    for (auto paramExpr = dynamic_cast<ExprNode *>(param);
         paramExpr != nullptr;
         paramExpr = dynamic_cast<ExprNode *>(paramExpr->getNext()))
    {
        // m0112优化 改用哈希表
        unordered_multimap<string, transItem*> items = paramExpr->getSymbolEntry()->getTransItem();
        auto range = items.equal_range(se->getName());

        for (auto it = range.first; it != range.second; ++it) {
            if(it->second->transType == TypeSystem::floatType){
                ExprNode *paramExpr1 = new ImplictCastExpr(paramExpr, TypeSystem::floatType);
                paramExpr1->append(paramExpr->getNext());
                paramExpr = paramExpr1;
            }else if(it->second->transType == TypeSystem::intType){
                ExprNode *paramExpr1 = new ImplictCastExpr(paramExpr, TypeSystem::intType);
                paramExpr1->append(paramExpr->getNext());
                paramExpr = paramExpr1;
            }
        }

        // param_on = 1;
        paramExpr->genCode();
        // param_on = 0;
        rParams.push_back(paramExpr->getOperand());
    }
    BasicBlock *entry = builder->getInsertBB();

    /*z1208 fix 嘶似乎不用alloc？*/
    if(retType->isVoid()){
        dst = nullptr;
    }else{
        SymbolEntry *ret = new TemporarySymbolEntry(retType, SymbolTable::getLabel());
        // SymbolTable::counter++;
        dst = new Operand(ret);
    }
    new FuncCallInstruction(dst, symbolEntry, rParams, entry);
}
void ContinueStmt::genCode()
{
    printg("ContinueStmt");
    // Todo
    Function *func = builder->getInsertBB()->getParent();
    BasicBlock *bb = builder->getInsertBB();
    new UncondBrInstruction(whileStmt->getCond_bb(), bb);
    BasicBlock *then_bb = new BasicBlock(func);
    builder->setInsertBB(then_bb);
}
void BreakStmt::genCode()
{
    printg("BreakStmt");
    // Todo
    Function *func = builder->getInsertBB()->getParent();
    BasicBlock *bb = builder->getInsertBB();
    new UncondBrInstruction(whileStmt->getEnd_bb(), bb);
    BasicBlock *then_bb = new BasicBlock(func);
    builder->setInsertBB(then_bb);
}
void WhileStmt::genCode()
{

    printg("WhileStmt");
    Function *func = builder->getInsertBB()->getParent();
    // BasicBlock *end_bb;
    cond_bb = new BasicBlock(func);
    stmt_bb = new BasicBlock(func);
    end_bb = new BasicBlock(func);

    new UncondBrInstruction(cond_bb, builder->getInsertBB());
    // temp->output();

    cond_bb->addPred(builder->getInsertBB());
    builder->getInsertBB()->addSucc(cond_bb);
    stmt_bb->addPred(cond_bb);
    cond_bb->addSucc(stmt_bb);

    // builder -> getInsertBB() -> addSucc(stmt_bb);
    cond_bb->addPred(stmt_bb);
    stmt_bb->addSucc(cond_bb);

    end_bb->addPred(cond_bb);
    cond_bb->addSucc(end_bb);

    builder->setInsertBB(cond_bb);

    cond->genCode();
    backPatch(cond->trueList(), stmt_bb);
    backPatch(cond->falseList(), end_bb);
    // 类型转换
    Type *btype = getBasicType(cond->getSymbolEntry());
    if (btype == TypeSystem::intType)
    {
        Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        new CmpInstruction(
            CmpInstruction::NE, tem, cond->getOperand(),
            new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
            builder->getInsertBB());
        new CondBrInstruction(stmt_bb, end_bb, tem, builder->getInsertBB());
    }
    else if (btype == TypeSystem::floatType)
    {
        Operand *tem = new Operand(new TemporarySymbolEntry(TypeSystem::boolType, SymbolTable::getLabel()));
        new CmpInstruction(
            CmpInstruction::NE, tem, cond->getOperand(),
            new Operand(new ConstantSymbolEntry(TypeSystem::floatType, 0)),
            builder->getInsertBB());
        new CondBrInstruction(stmt_bb, end_bb, tem, builder->getInsertBB());
    }
    else
    {
        new CondBrInstruction(stmt_bb, end_bb, cond->getOperand(), builder->getInsertBB());
    }

    builder->setInsertBB(stmt_bb);
    stmt->genCode();
    stmt_bb = builder->getInsertBB();
    new UncondBrInstruction(cond_bb, stmt_bb);

    builder->setInsertBB(end_bb);
    // end_bb_cur=end_bb;
}
void DeclInitStmt::genCode()
{
    printg("DeclInitStmt");
    // BasicBlock *bb = builder->getInsertBB();

    InitStmt *is = this->initstmt;
    while (is != nullptr)
    {
        is->genCode();
        is = (InitStmt *)is->getNext();
    }
}
void FuncHead::genCode()
{
    printg("FuncHead");
    // Todo
}
void FuncStmt::genCode()
{
    printg("FuncStmt");
    // Todo
}
void CastExpr::genCode()
{
    printg("CastExpr");
    // 强制类型转换
}
void UnaryExpr::genCode()
{
    printg("UnaryExpr");
    if (this->getSymbolEntry()->isConstant())
        return;
    expr1->genCode();
    Operand *src = expr1->getOperand();
    // 分支控制?

    if (op == NOT)
    {
        BasicBlock *bb = builder->getInsertBB();
        Type *btype = getBasicType(expr1->getSymbolEntry());
        if (btype == TypeSystem::intType)
        {
            Operand *temp = new Operand(new TemporarySymbolEntry(
                TypeSystem::boolType, SymbolTable::getLabel()));
            new CmpInstruction(
                CmpInstruction::NE, temp, src,
                new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)),
                bb);
            src = temp;
        
        }

        new XorInstruction(dst, src, bb);
    }
    else
    {
        Operand *src1 = new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0));
        Operand *src2, *tem;
        BasicBlock *bb = builder->getInsertBB();
        int opcode;
        switch (op)
        {
        case PLUS:
            opcode = BinaryInstruction::ADD;
            break;
        case UMINUS:
            opcode = BinaryInstruction::SUB;
            break;
        }
        if (dst->getSymbolEntry()->getType() == TypeSystem::boolType)
        {
            tem = new Operand(new TemporarySymbolEntry(
                TypeSystem::intType, SymbolTable::getLabel()));
            dst = tem;
        }
        if (expr1->getSymbolEntry()->getType() == TypeSystem::boolType)
        {
            src2 = new Operand(new TemporarySymbolEntry(
                TypeSystem::intType, SymbolTable::getLabel()));
            new ZextInstruction(src2, expr1->getOperand(), bb);
        }
        else
            src2 = expr1->getOperand();
        new BinaryInstruction(opcode, dst, src1, src2, bb);
    }
}

void DeclStmt::genCode()
{
    printg("DeclStmt");
    DeclStmt *is = this;
    while (is != nullptr)
    {

        Id *declId = is->getId();
        IdentifierSymbolEntry *se = dynamic_cast<IdentifierSymbolEntry *>(declId->getSymbolEntry());
        if (se->isParam())
        {
            printg(se->toStr().c_str() << " " << se->isConstant());
            Function *func = builder->getInsertBB()->getParent();
            BasicBlock *entry = func->getSymbolEntry();
            Instruction *alloca;
            Operand *addr;
            SymbolEntry *addr_se;
            Type *type;
            type = new PointerType(se->getType());
            addr_se = new TemporarySymbolEntry(type, SymbolTable::getLabel());
            addr = new Operand(addr_se);
            alloca = new AllocaInstruction(addr, se); // allocate space for local id in function stack.
            printg("entry->insertFront")
                entry->insertFront(alloca); // allocate instructions should be inserted into the begin of the entry block.
                                            // set the addr operand in symbol entry so that we can use it in subsequent code generation
            Operand *ori_addr = new Operand(se);
            se->setAddr(addr);
            // if(se->getType()->isArray()){
            //     ori_addr->setType(new PointerType(dynamic_cast<ArrayType*>(se->getType())->getEleType()));
            // }
            // std::cout<<"++++++++++++++++++++++++\n";
            // addr_se = new TemporarySymbolEntry(type, SymbolTable::getLabel());
            // addr = new Operand(addr_se);
            BasicBlock *bb = builder->getInsertBB();
            new StoreInstruction(addr, ori_addr, bb);
        }
        is = (DeclStmt *)is->getNext();
    }
}

void SpaceStmt::genCode()
{
    printg("SpaceStmt");
}
void ReturnStmt::genCode()
{
    printg("ReturnStmt");
    // Todo
    Operand *src = nullptr;
    if (retValue != nullptr)
    {
        retValue->genCode();
        src = retValue->getOperand();
    }
    BasicBlock *bb = builder->getInsertBB();
    new RetInstruction(src, bb);
}
void ConstNode::genCode()
{
    printg("ConstNode");
    id->genCode();
    dst = id->getOperand();

}

void InitStmt::genCode()
{
    printg("InitStmt");
    Operand *addr;
    IdentifierSymbolEntry *se = (IdentifierSymbolEntry *)dynamic_cast<IdentifierSymbolEntry *>(id->getSymbolEntry());
    /* Decl */
    if (se->isGlobal())
    {
        printg("se->isGlocal()");
        SymbolEntry *addr_se;
        Unit *unit = builder->getUnit();
        // MachineUnit *mUnit = mbuilder->getUnit();
        addr_se = new IdentifierSymbolEntry(*se);
        addr_se->setType(new PointerType(se->getType()));
        addr = new Operand(addr_se);
        se->setAddr(addr);
        // 添加对应的全局变量
        // 初始化var: @i = global i32 1, align 4
        // 未初始化var: @i = common global i32 0, align 4
        // const: @i = constant global i32 1, align 4
        // 后续使用时如果为全局变量: %t1 = load i32, i32* @i, align 4
        unit->insertGlobal(se);
        mUnit.insertGlobal(se);
    }
    else if (se->isLocal())
    {
        printg("se->isLocal()");
        printg(se->toStr().c_str() << " " << se->isConstant());
        Function *func = builder->getInsertBB()->getParent();
        BasicBlock *entry = func->getSymbolEntry();
        Instruction *alloca;
        SymbolEntry *addr_se;
        Type *type;
        type = new PointerType(se->getType());
        addr_se = new TemporarySymbolEntry(type, SymbolTable::getLabel());
        addr = new Operand(addr_se);
        alloca = new AllocaInstruction(addr, se); // allocate space for local id in function stack.
        entry->insertFront(alloca);               // allocate instructions should be inserted into the begin of the entry block.

        se->setAddr(addr); // set the addr operand in symbol entry so that we can use it in subsequent code generation.
    }
    else if (se->isParam())//没用
    {
        SymbolEntry *addr_se;

        // Type *type = new PointerType(se->getType());
        // addr_se = new TemporarySymbolEntry(type, SymbolTable::getLabel());

        addr_se = new IdentifierSymbolEntry(*se);
        addr_se->setType(new PointerType(se->getType()));

        addr = new Operand(addr_se);
        BasicBlock *bb = builder->getInsertBB();
        new StoreInstruction(addr, se->getAddr(), bb);
        
    }
    // z1204 适配declinit
    /* Init */
    if (is_init && expr != nullptr)
    {
        printg("INIT initstmt");
        // Function *func = builder->getInsertBB()->getParent();
        BasicBlock *bb = builder->getInsertBB();
        if (se->getType()->isArray())
        {
            ArrayType *arrType = (ArrayType *)se->getType();
            ArrayType *eletype = arrType;
            Operand *arr_dst;
            Operand *arr_src = se->getAddr();
            bool first_in = 1;
            dynamic_cast<ArrayType *>(se->getType())->setSize();
            // std::cout<<"ast : "<<se->getType()->getSize()<<"\n";
            // arr_dst = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
            // arr_src = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
            ConstantSymbolEntry *const_se;
            int dimen = arrType->getDimen();
            int *index = new int[dimen];
            int *arr_dimen = new int[dimen];
            Operand *init = nullptr;
            int cnt = 1;
            arrType->getValueVec().clear();

            for (int i = 0; i < dimen; i++)
            {
                index[i] = 0;
                arr_dimen[i] = arrType->getLenVec()[i];
                cnt *= arr_dimen[i];
                // std::cout<<"dimen "<<i<<" = "<<arr_dimen[i]<<"\n";
            }
            //std::vector<Operand *> idx_stack;
            // int dimen_marker=arrType->getLenVec().size()-1;
            while (expr != nullptr)
            {
                // idx_stack.clear();
                eletype = arrType;
                arr_src = se->getAddr();
                bool allInitZero = 0;
                if (expr->getNull())
                {
                    if (first_in && expr->getNext() == nullptr)
                    {
                        if(cnt<=256){
                            allInitZero = 1;
                        }
                        else{
                        SymbolEntry *func_se = globals->lookup("memset");
                        Type *int8PtrType = new PointerType(TypeSystem::int8Type);
                        
                        Operand *int8Ptr = new Operand(new TemporarySymbolEntry(int8PtrType, SymbolTable::getLabel()));

                        // Operand*dst = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
                        // new LoadInstruction(dst, addr, bb);
                        new BitcastInstruction(int8Ptr, se->getAddr(), bb);
                        if (func_se == nullptr){
                            std::vector<Type*> vec;
                            vec.push_back(int8PtrType);
                            vec.push_back(TypeSystem::int8Type);
                            vec.push_back(TypeSystem::intType);
                            vec.push_back(TypeSystem::boolType);
                            FunctionType* funcType = new FunctionType("memset",TypeSystem::voidType, vec);
                            func_se = new IdentifierSymbolEntry(funcType, "memset", 0);
                            globals->install("memset", func_se);
                            unit.insertDeclare(func_se);
                        }
                        std::vector<Operand*> params;
                        params.push_back(int8Ptr);
                        params.push_back(new Operand(
                            new ConstantSymbolEntry(TypeSystem::int8Type, 0)));
                        params.push_back(new Operand(
                            new ConstantSymbolEntry(TypeSystem::intType, cnt)));
                        params.push_back(new Operand(
                            new ConstantSymbolEntry(TypeSystem::boolType, 0)));
                        new FuncCallInstruction(nullptr, func_se, params, bb);


                        // delete int8PtrType;
                        // delete int8Ptr;
                        // std::vector<Operand *> rParams;
                        // rParams.push_back(se->getAddr());
                        // const_se = new ConstantSymbolEntry(TypeSystem::intType, cnt);
                        // Operand *tmp_idx = (new Constant(const_se))->getOperand();
                        // rParams.push_back(tmp_idx);
                        // SymbolEntry *ret = new TemporarySymbolEntry(TypeSystem::voidType, SymbolTable::getLabel());
                        // dst = new Operand(ret);
                        // new FuncCallInstruction(dst, func_se, rParams, bb);
                        expr = (ExprNode *)expr->getNext();
                        continue;
                    }
                    }
                }
                else
                {
                    if (!first_in)
                    {
                        index[dimen - 1]++;
                    }
                    else
                    {
                        first_in = 0;
                    }
                    for (int i = dimen - 1; i >= 0; i--)
                    {
                        if (index[i] >= arr_dimen[i])
                        {
                            index[i] = 0;
                            if(i-1>=0)
                            index[i - 1]++; // 程序正确就不会出问题
                        }
                    }

                    for (int i = 0; i < dimen; i++)
                    {
                        // std::cout<<"dimen "<<i<<" = "<<index[i]<<"\n";
                        arr_src->setType(eletype->getStripEleType());
                        const_se = new ConstantSymbolEntry(TypeSystem::intType, index[i]);
                        Operand *tmp_idx = (new Constant(const_se))->getOperand();
                        arr_dst = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
                        eletype = (ArrayType *)eletype->getStripEleType();
                        GepInstruction *gep = new GepInstruction(arr_dst, arr_src, bb, tmp_idx);
                        gep->setInit(init);
                        init=arr_dst;
                        if (i == 0)
                        {
                            gep->setIdxFirst(1);
                        }
                        if (i == dimen - 1)
                        {
                            gep->setIdxLast(1);
                        }
                        arr_src = arr_dst;

                        // idx_stack.push_back(tmp_idx);
                    }
                    Type *type1 = getBasicType(id->getSymbolEntry());
                    Type *type2 = getBasicType(expr->getSymbolEntry());
                    if (type1->isInt() && type2->isFloat()) {
                        ImplictCastExpr* temp =
                            new ImplictCastExpr(expr, TypeSystem::intType);
                        temp->genCode();
                    } else if (type1->isFloat() && type2->isInt()) {
                        ImplictCastExpr* temp =
                            new ImplictCastExpr(expr, TypeSystem::floatType);
                        temp->genCode();
                    }
                    else
                        expr->genCode();
                    Operand *src = expr->getOperand();
                    Type *expType = arrType->getEleType();
                    if (expr->getSymbolEntry()->isConstant())
                    {
                        if (expType->isInt())
                        {
                            int intvalue = (int)dynamic_cast<ConstantSymbolEntry *>(expr->getSymbolEntry())->getIntValue();
                            arrType->getValueVec().push_back(intvalue);
                        }
                        else if (expType->isFloat())
                        {
                            float floatvalue = (float)dynamic_cast<ConstantSymbolEntry *>(expr->getSymbolEntry())->getFloatValue();
                            arrType->getValueVec().push_back(floatvalue);
                        }
                    }
                    int lb = dynamic_cast<TemporarySymbolEntry *>(arr_dst->getSymbolEntry())->getLabel();
                    arr_dst = new Operand(new TemporarySymbolEntry(new PointerType(arrType->getEleType()), lb));
                    new StoreInstruction(arr_dst, src, bb);
                }
                bool fill = 0;
                first_in = 0;
                int max_cnt = 256;
                if(cnt>1024)max_cnt=16;
                // std::cout<<"-------------------\n"<<cnt<<"\n";
                while (allInitZero || (expr->getLast()))
                {
                    if (max_cnt<=0||(allInitZero && cnt <= 0))
                        break;
                    eletype = arrType;
                    arr_src = se->getAddr();

                    index[dimen - 1]++;
                    // std::cout<<"dimen"<<index[dimen-1]<<"\n";
                    for (int i = dimen - 1; i >= 0; i--)
                    {
                        if (index[i] >= arr_dimen[i])
                        {
                            index[i] = 0;
                            if(i-1>=0)
                            index[i - 1]++; // 程序正确就不会出问题
                            if (!allInitZero)
                                fill = 1;
                        }
                    }
                    if (fill)
                    {
                        index[dimen - 1]--;
                        // if(index[dimen-1]<0)
                        // index[dimen-1]=0;
                        break;
                    }

                    for (int i = 0; i < dimen; i++)
                    {
                        arr_src->setType(eletype->getStripEleType());
                        const_se = new ConstantSymbolEntry(TypeSystem::intType, index[i]);
                        Operand *tmp_idx = (new Constant(const_se))->getOperand();
                        arr_dst = new Operand(new TemporarySymbolEntry(eletype, SymbolTable::getLabel()));
                        eletype = (ArrayType *)eletype->getStripEleType();

                        GepInstruction *gep = new GepInstruction(arr_dst, arr_src, bb, tmp_idx);
                        gep->setInit(init);
                        init=arr_dst;
                        if (i == 0)
                        {
                            gep->setIdxFirst(1);
                        }
                        if (i == dimen - 1)
                        {
                            gep->setIdxLast(1);
                        }
                        arr_src = arr_dst;

                        // idx_stack.push_back(tmp_idx);
                    }
                    arrType->getValueVec().push_back(0);
                    const_se = new ConstantSymbolEntry(TypeSystem::intType, 0);
                    Operand *src = (new Constant(const_se))->getOperand();
                    int lb = dynamic_cast<TemporarySymbolEntry *>(arr_dst->getSymbolEntry())->getLabel();
                    arr_dst = new Operand(new TemporarySymbolEntry(new PointerType(arrType->getEleType()), lb));
                    new StoreInstruction(arr_dst, src, bb);
                    cnt--;
                    max_cnt--;
                }
                expr = (ExprNode *)expr->getNext();
            }
            if(index!=nullptr)delete index;
            // if(arr_dimen)delete arr_dimen;
        }
        else
        {
            Type *type1 = getBasicType(id->getSymbolEntry());
            Type *type2 = getBasicType(expr->getSymbolEntry());
            if (type1->isInt() && type2->isFloat()) {
                ImplictCastExpr* temp =
                    new ImplictCastExpr(expr, TypeSystem::intType);
                this->expr = temp;
            } else if (type1->isFloat() && type2->isInt()) {
                ImplictCastExpr* temp =
                    new ImplictCastExpr(expr, TypeSystem::floatType);
                this->expr = temp;
            } 
            expr->genCode();
            BasicBlock *bb = builder->getInsertBB();
            Operand *addr = dynamic_cast<IdentifierSymbolEntry *>(id->getSymbolEntry())->getAddr();
            Operand *src = expr->getOperand();
            new StoreInstruction(addr, src, bb);
        }
    }
}
void AssignStmt::genCode()
{
    printg("AssignStmt");
    Type *type1 = getBasicType(lval->getSymbolEntry());
    Type *type2 = getBasicType(expr->getSymbolEntry());
    if (type1->isInt() && type2->isFloat()) {
        ImplictCastExpr* temp =
            new ImplictCastExpr(expr, TypeSystem::intType);
        this->expr = temp;
    } else if (type1->isFloat() && type2->isInt()) {
        ImplictCastExpr* temp =
            new ImplictCastExpr(expr, TypeSystem::floatType);
        this->expr = temp;
    } 
    BasicBlock *bb = builder->getInsertBB();
    expr->genCode();
    Operand *addr;
    Operand *src = expr->getOperand();
    if (lval->getIsArray())
    {
        lval->genCode();
        addr = lval->getOperand();
    }
    else
    {
        addr = dynamic_cast<IdentifierSymbolEntry *>(lval->getSymbolEntry())->getAddr();
    }

    new StoreInstruction(addr, src, bb);
}

void ImplictCastExpr::genCode()
{
    expr->genCode();
    BasicBlock *bb = builder->getInsertBB();
    if (type == TypeSystem::boolType) {
        Function *func = bb->getParent();
        BasicBlock *trueBB = new BasicBlock(func);
        BasicBlock *tempbb = new BasicBlock(func);
        BasicBlock *falseBB = new BasicBlock(func);

        new CmpInstruction(
            CmpInstruction::NE, this->dst, this->expr->getOperand(),
            new Operand(new ConstantSymbolEntry(TypeSystem::intType, 0)), bb);
        this->trueList().push_back(
            new CondBrInstruction(trueBB, tempbb, this->dst, bb));
        this->falseList().push_back(new UncondBrInstruction(falseBB, tempbb));
    } else if (type->isInt()) {
        new FptosiInstruction(dst, this->expr->getOperand(), bb);
    } else if (type->isFloat()) {
        new SitofpInstruction(dst, this->expr->getOperand(), bb);
    } else {
        // error
        assert(false);
    }
}

Node::Node()
{
    seq = counter++;
    next = nullptr;
}

void FuncHead::output(int level)
{
}

void Ast::output()
{
    fprintf(yyout, "target triple = \"x86_64-pc-linux-gnu\"\n");
    print("program");
    fprintf(yyout, "program\n");
    if (root != nullptr)
        root->output(4);
}
/*m1102 定义单目运算符输出*/
void UnaryExpr::output(int level)
{
    print("UnaryExpr");
    std::string op_str;
    switch (op)
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
    if (expr1)
        expr1->output(level + 4);
}

void ExprNode::genCode()
{
    printg("ExprNode");
    // Todo
}

void CastExpr::output(int level)
{
    print("CastExpr");
    std::string op_str;
    std::string tname;
    if (this->symbolEntry->getType() == TypeSystem::intType)
    {
        if (this->old->getType() == TypeSystem::intType)
        {
            tname = "int";
            op_str = "Noop";
        }
        else
        {
            tname = "int";
            op_str = "floatToint";
        }
    }
    if (this->symbolEntry->getType() == TypeSystem::floatType)
    {
        if (this->old->getType() == TypeSystem::intType)
        {
            tname = "float";
            op_str = "intTofloat";
        }
        else
        {
            tname = "float";
            op_str = "Noop";
        }
    }
    fprintf(yyout, "%*cCastExpr\ttype: %s\t\top: %s\n", level, ' ', tname.c_str(), op_str.c_str());
    if (expr1)
        expr1->output(level + 4);
}

void BinaryExpr::output(int level)
{
    print("BinaryExpr");
    std::string op_str;
    switch (op)
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
    if (expr1)
        expr1->output(level + 4);
    if (expr2)
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
    scope = dynamic_cast<IdentifierSymbolEntry *>(symbolEntry)->getScope();
    print("Id");
    if (dynamic_cast<IdentifierSymbolEntry *>(symbolEntry)->isConstant())
    {
        fprintf(yyout, "%*cId\tname: %s\tscope: %d\ttype: const %s\n", level, ' ',
                sname.c_str(), scope, type.c_str());
    }
    else
    {
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
    scope = dynamic_cast<IdentifierSymbolEntry *>(id->getSymbolEntry())->getScope();
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
    // fprintf(yyout, "%*cSequence\n", level, ' ');
    //  stmt1->output(level + 4);
    //  stmt2->output(level + 4);
    stmt1->output(level);
    stmt2->output(level);
}

void DeclStmt::output(int level)
{
    print("DeclStmt");
    fprintf(yyout, "%*cDeclStmt\n", level, ' ');
    Id *p = this->id;
    while (p != nullptr)
    {
        print("before id");
        p->output(level + 4);
        p = (Id *)p->getNext();
    }
}
void DeclInitStmt::output(int level)
{
    print("DeclInitStmt");
    fprintf(yyout, "%*cDeclInitStmt\n", level, ' ');
    InitStmt *is = this->initstmt;
    print("DeclInitStmt while");
    while (is != nullptr)
    {
        print("init output +1");
        is->output(level + 4);
        is = (InitStmt *)is->getNext();
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
    if (expr != nullptr)
        expr->output(level + 4);
}

void IfStmt::output(int level)
{
    print("IfStmt");
    fprintf(yyout, "%*cIfStmt\n", level, ' ');
    cond->output(level + 4);
    if (thenStmt != nullptr)
    {
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

void WhileStmt::output(int level)
{
    print("WhileStmt");
    fprintf(yyout, "%*cWhileStmt\n", level, ' ');
    if (cond)
        cond->output(level + 4);
    stmt->output(level + 4);
}

void BreakStmt::output(int level)
{
    fprintf(yyout, "%*cBreakStmt\n", level, ' ');
}

void ContinueStmt::output(int level)
{
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

void FunctionDef::output(int level)
{
    print("FunctionDef");
    std::string name, type;
    name = se->toStr();
    type = se->getType()->toStr();
    fprintf(yyout, "%*cFunctionDef\tfunc name: %s\ttype: %s\n", level,
            ' ', name.c_str(), type.c_str());
    if (decl)
    {
        decl->output(level + 4);
    }
    stmt->output(level + 4);
}

void FuncCall::output(int level)
{
    print("FuncCall");
    std::string name, type;
    int scope;
    name = symbolEntry->toStr();
    type = symbolEntry->getType()->toStr();
    scope = dynamic_cast<IdentifierSymbolEntry *>(symbolEntry)->getScope();
    fprintf(yyout, "%*cFuncCall\tfunction name: %s\tscope: %d\ttype: %s\n",
            level, ' ', name.c_str(), scope, type.c_str());
    Node *temp = param;
    while (temp)
    {
        temp->output(level + 4);
        temp = temp->getNext();
    }
    print("FuncCall-end");
}

void ExprStmt::output(int level)
{
    print("ExprStmt");
    fprintf(yyout, "%*cExprStmt\n", level, ' ');
    expr->output(level + 4);
}

void ImplictCastExpr::output(int level)
{
    Type *type = TypeSystem::boolType;
    fprintf(yyout, "%*cImplictCastExpr\ttype: %s to %s\n", level, ' ',
            expr->getSymbolEntry()->getType()->toStr().c_str(), type->toStr().c_str());
    this->expr->output(level + 4);
}
