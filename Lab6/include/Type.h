#ifndef __TYPE_H__
#define __TYPE_H__
#include <vector>
#include <string>
#include<iostream>
#include <assert.h>
class Type
{
private:
    int kind;

protected:
    enum {INT, VOID, FUNC, FLOAT, ARRAY};
    int size;/*z1104 整合子类size*/
public:
    Type(int kind,int size=0) : kind(kind),size(size) {};
    virtual ~Type() {};
    virtual std::string toStr() = 0;
    bool isInt() const {return kind == INT;};
    bool isFloat() const {return kind == FLOAT;};
    bool isVoid() const {return kind == VOID;};
    bool isFunc() const {return kind == FUNC;};
    bool isArray() const {return kind == ARRAY;};
    int getSize() const { return size; };

};


class IntType : public Type
{
private:
    //int size;
public:
    IntType(int size) : Type(Type::INT,size){};
    std::string toStr();
};

class FloatType : public Type
{
private:
    //int size;
public:
    FloatType(int size) : Type(Type::FLOAT,size){};
    std::string toStr();
};

class VoidType : public Type
{
public:
    VoidType() : Type(Type::VOID){};
    std::string toStr();
};

/*z1104 数组实现*/
class Array : public Type {
   private:
    Type* eletype;
    int dimen;
    std::vector<int> len;//不同维度大小
    //int size;
   public:
    Array(Type* eletype):Type(Type::ARRAY),eletype(eletype){};
    Array(Type* eletype,int dimen)
        : Type(Type::ARRAY),eletype(eletype),dimen(dimen){
        //size = len * eletype->getSize();
    };
    std::string toStr();
    int getLenNum(int n) const { return len[n]; };
    Type* getEleType() const { return eletype; };
    void setEleType(Type* eletype) { this->eletype = eletype; };
    std::vector<int> &getLenVec(){return len;}
    int getDimen(){return this->dimen;}
    void setDimen(int dimen){this->dimen=dimen;}
};

class FunctionType : public Type
{
private:
    Type *returnType;
    std::vector<Type*> paramsType;
public:
    FunctionType(Type* returnType, std::vector<Type*> paramsType) : 
    Type(Type::FUNC), returnType(returnType), paramsType(paramsType){};
    std::string toStr();
    Type* getreturnType(){return this->returnType;}
    bool checkParam(std::vector<Type*> rparams){
        if(paramsType.size()!=rparams.size()){
            std::cout<<"function params number not match!\n";
            return false;
            assert(paramsType.size()==rparams.size());
        }
        for (size_t i = 0; i < paramsType.size(); i++)
        {
            /*if need debug type check*/
            // printf("<<<<<<<<<<<<<<\n%s\n%s<<<<<<<<<<<<<<\n",paramsType[i]->toStr().c_str(),rparams[i]->toStr().c_str());

            if(paramsType[i]!=rparams[i]){
                if(paramsType[i]->isArray()&&rparams[i]->isArray()){
                    Array *arr1=(Array*)paramsType[i];
                    Array *arr2=(Array*)rparams[i];

                    assert(arr1->getEleType()==arr2->getEleType());

                    continue;
                }
                std::cout<<"The param number "<<i<<" not match\n";
                return false;
                assert(paramsType[i]==rparams[i]);
            }
        }
        return true;
    }
};




class TypeSystem
{
private:
    static IntType commonInt;
    static VoidType commonVoid;
    static FloatType commonFloat;
    static Array commonARRAY;
public:
    static Type *intType;
    static Type *voidType;
    static Type *floatType;
    static Type *arrayType;
};

#endif
