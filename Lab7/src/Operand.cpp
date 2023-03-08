#include "Operand.h"
#include <sstream>
#include <algorithm>
#include <string.h>

std::string Operand::toStr() const
{
    return se->toStr();
}

void Operand::removeUse(Instruction *inst)
{
    auto i = std::find(uses.begin(), uses.end(), inst);
    if(i != uses.end())
        uses.erase(i);
}

int32_t Operand::getValue(){ 
    if(isConstant()){
        ConstantSymbolEntry* cs  = dynamic_cast<ConstantSymbolEntry*>(se);
        if(this->getType()->isFloat()){
            return cs->getFloatValue();
        }else{
            return cs->getIntValue();
        }
    }
    return -1;
};