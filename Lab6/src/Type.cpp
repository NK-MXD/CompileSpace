#include "Type.h"
#include <sstream>

IntType TypeSystem::commonInt = IntType(4);
VoidType TypeSystem::commonVoid = VoidType();
FloatType TypeSystem::commonFloat = FloatType(8);
Array TypeSystem::commonARRAY = Array(nullptr);

Type* TypeSystem::intType = &commonInt;
Type* TypeSystem::voidType = &commonVoid;
Type* TypeSystem::floatType = &commonFloat;
Type* TypeSystem::arrayType = &commonARRAY;

std::string IntType::toStr()
{
    return "int";
}

std::string VoidType::toStr()
{
    return "void";
}

std::string FunctionType::toStr()
{
    std::ostringstream buffer;
    buffer << returnType->toStr() << "(";
    for (int i=0;i<(int)paramsType.size()-1;i++)
        buffer << paramsType[i]->toStr()<<", ";
    if((int)paramsType.size()-1>=0)
        buffer << paramsType[(int)paramsType.size()-1]->toStr();
    buffer << ")";
    return buffer.str();
}

std::string FloatType::toStr()
{
    return "float";
}

std::string Array::toStr() {
    std::ostringstream buffer;
    buffer<<eletype->toStr();
    for (int i=0;i<(int)len.size();i++) 
            buffer << '[' << len[i] << ']';
    if((int)len.size()==0)
        buffer<<"[]";
    return buffer.str();
}