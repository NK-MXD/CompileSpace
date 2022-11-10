#include "Type.h"
#include <sstream>

IntType TypeSystem::commonInt = IntType(4);
VoidType TypeSystem::commonVoid = VoidType();
FloatType TypeSystem::commonFloat = FloatType(8);

Type* TypeSystem::intType = &commonInt;
Type* TypeSystem::voidType = &commonVoid;
Type* TypeSystem::floatType = &commonFloat;

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
    buffer << returnType->toStr() << "()";
    return buffer.str();
}

std::string FloatType::toStr()
{
    return "float";
}
