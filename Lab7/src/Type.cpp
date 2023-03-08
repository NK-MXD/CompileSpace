#include "Type.h"
#include <sstream>
bool debug=0;
std::vector<Type*> paramsType;
// IntType TypeSystem::commonInt = IntType(4);
IntType TypeSystem::commonInt = IntType(32);
IntType TypeSystem::commonInt8 = IntType(8);
IntType TypeSystem::commonBool = IntType(1);
VoidType TypeSystem::commonVoid = VoidType();
FloatType TypeSystem::commonFloat = FloatType(32);
ArrayType TypeSystem::commonARRAY = ArrayType(nullptr);
FunctionType TypeSystem::commonFunc = FunctionType("",nullptr,paramsType);

Type* TypeSystem::intType = &commonInt;
Type* TypeSystem::int8Type = &commonInt8;
Type* TypeSystem::voidType = &commonVoid;
Type* TypeSystem::floatType = &commonFloat;
Type* TypeSystem::arrayType = &commonARRAY;
Type* TypeSystem::boolType = &commonBool;
Type* TypeSystem::funcType = &commonFunc;

std::string PointerType::toStr()
{
    std::ostringstream buffer;
    buffer << valueType->toStr() << "*";
    return buffer.str();
}

std::string IntType::toStr()
{
    std::ostringstream buffer;
    buffer << "i" << size;
    return buffer.str();
}

std::string VoidType::toStr()
{
    return "void";
}

std::string FunctionType::toStr()
{
    std::ostringstream buffer;
    // buffer << returnType->toStr() << "(";
    buffer << "(";
    for (int i=0;i<(int)paramsType.size()-1;i++)
        buffer << paramsType[i]->toStr()<<", ";
    if((int)paramsType.size()-1>=0)
        buffer << paramsType[(int)paramsType.size()-1]->toStr();
    buffer << ")";
    return buffer.str();
} 

// z1213 更新函数参数检查
// z1213 更新funccall隐式类型转换
bool FunctionType::checkParam(std::vector<SymbolEntry*> rParamsSE){
    
    std::vector<Type*> rparams;
    for (size_t i = 0; i < rParamsSE.size(); i++){
        rparams.push_back(rParamsSE[i]->getType());
    }
    /*if need debug type check*/
    // std::cout<<"p = "<<paramsType.size()<<" r = "<<rparams.size()<<"\n";
    if(paramsType.size()!=rparams.size()){
        // std::cout<<"function params number not match!\n";
        assert(paramsType.size()==rparams.size());
        return false;
        
    }
    int retCode=0;
    std::vector<Type*> typeVec;
    // std::cout<<rparams.size()<<std::endl;
    for (size_t i = 0; i < paramsType.size(); i++)
    {
        /*if need debug type check*/
        typeVec.clear();
        // printf("<<<<<<<<<<<<<<\n%d\n%s\n%s\n<<<<<<<<<<<<<<\n",i, paramsType[i]->toStr().c_str(),rparams[i]->toStr().c_str());
        typeVec.push_back(paramsType[i]);
        typeVec.push_back(rparams[i]);
        transItem * item;
        retCode = pairTypeCheck(typeVec);
        switch(retCode){
            case 0:
                item=new transItem();
                item->func_name=this->func_name;
                rParamsSE[i]->appendTransItem(item);
                break;
            case 1:
                break;
            /*f to i*/
            case 2:
                item=new transItem();
                item->func_name=this->func_name;
                item->isTrans=1;
                item->transType=paramsType[i];
                rParamsSE[i]->appendTransItem(item);
                if(rParamsSE[i]->isConstant()){
                    int value=dynamic_cast<ConstantSymbolEntry*>(rParamsSE[i])->getFloatValue();
                    dynamic_cast<ConstantSymbolEntry*>(rParamsSE[i])->setIntValue(value);
                }
                break;
            /*i to f*/
            case 3:
                item=new transItem();
                item->func_name=this->func_name;
                item->isTrans=1;
                item->transType=paramsType[i];
                rParamsSE[i]->appendTransItem(item);
                if(rParamsSE[i]->isConstant()){
                    float value=dynamic_cast<ConstantSymbolEntry*>(rParamsSE[i])->getIntValue();
                    dynamic_cast<ConstantSymbolEntry*>(rParamsSE[i])->setFloatValue(value);
                }
                break;
            case 4:
                break;
        }
    }
    return true;
}
    
PointerType::PointerType(ArrayType* arrtype,int idx) : Type(Type::PTR) {
        Type *type=arrtype;
        if(idx==0){
            this->valueType=arrtype->getEleType();
        }
        if (idx==arrtype->getDimen()){
            this->valueType=arrtype->getEleType();
        }
        else{
            while(idx--){
                type=dynamic_cast<ArrayType*>(type)->getStripEleType();
            }
            this->valueType=type;
        }
        std::cout<<"dimen = "<<dynamic_cast<ArrayType*>(valueType)->getLenVec().size()<<"\n";
    }
std::string FloatType::toStr()
{
    return "float";
}
bool ArrayType::calHighestDimen(){
    if(arrayValue.size()==0||len[0]!=0)
        return 1;
    size_t sum = 1;

    for(size_t i=1;i<len.size();i++){
        sum*=dimen;
    }
    if(arrayValue.size()<sum){
        return 1;
    }
    else if(arrayValue.size()%sum==0){
        len[0]=arrayValue.size()/sum;
    }
    else 
        return 0;

}
void ArrayType::genArr(std::ostringstream &buffer,int dim){
    if(dim>=getDimen()){
        return;
    }
    else if(len[dim]!=0)
        buffer<<"["<<len[dim]<<" x";
    genArr(buffer,dim+1);
    if(dim==getDimen()-1)
        buffer<<" "<<eletype->toStr();
    if(len[dim]!=0)
        buffer<<"]";
    return;
}

void ArrayType::setSize(){
    int sum=1;
    for(size_t i=0;i<len.size();i++){
        sum*=len[i];
    }
    this->size = sum * eletype->getSize();
}

std::string ArrayType::toStr() {
    std::ostringstream buffer;
    if(len[0]==0){
        // buffer<<(eletype)->toStr();
        buffer<<(new PointerType(eletype))->toStr();
        return buffer.str();

    }
    // buffer<<eletype->toStr();
    // for (int i=0;i<(int)len.size();i++) 
    //         buffer << '[' << len[i] << ']';
    // if((int)len.size()==0)
    //     buffer<<"[]";

    if(debug)std::cout<<"in arr gen\n";
    genArr(buffer,0);
    //const char* buffer_str = buffer.str().c_str();
    return buffer.str();
}
Type* ArrayType::getStripEleType(){
    Type* strip_arr=nullptr;
    if(!this->len.empty()){
        int new_dimen=this->getDimen()-1;
        if(new_dimen!=-1){
            strip_arr=new ArrayType(this->getEleType(),new_dimen);
            ArrayType *arr=(ArrayType *)strip_arr;
            for(int i=1;i<len.size();i++){
                (arr->getLenVec()).push_back(len[i]);
            }
            // arr->getLenVec().assign(this->len.begin(), this->len.end());
            // arr->getLenVec().erase(arr->getLenVec().begin());
        }
        else{
            strip_arr=this->getEleType();
        }
    }

    return strip_arr;
    
}