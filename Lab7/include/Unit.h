#ifndef __UNIT_H__
#define __UNIT_H__
#include <sstream>
#include <vector>
#include "Function.h"
#include "Type.h"


class Unit
{
    typedef std::vector<Function *>::iterator iterator;
    typedef std::vector<Function *>::reverse_iterator reverse_iterator;

private:
    std::vector<Function *> func_list;
    //保存全局变量
    std::vector<SymbolEntry* > global_list;
    std::vector<SymbolEntry*> declare_list;
public:
    Unit() = default;
    ~Unit() ;
    void insertFunc(Function *);
    void removeFunc(Function *);
    void output() const;
    void insertGlobal(SymbolEntry*);
    void insertDeclare(SymbolEntry*);
    iterator begin() { return func_list.begin(); };
    iterator end() { return func_list.end(); };
    reverse_iterator rbegin() { return func_list.rbegin(); };
    reverse_iterator rend() { return func_list.rend(); };
    void genMachineCode(MachineUnit* munit);
    std::vector<Function* > &get_functions() {return func_list;};
};
/*z1215 global arr init*/
/**
 * 1. float a[100]={0};
 *    @a = dso_local global [100 x float] zeroinitializer, align 16
 * 2. float a[100];
 *    @a = common dso_local global [100 x float] zeroinitializer, align 16
 * // 似乎当维度切片达到一定界限就会出现<{, 好像也并不是可以直接跟[]等价代换？？
 * // i see , 用于wrap整个array跟重复单位
 * 3. int a[100]={1};
 *    @a = dso_local global <{ i32, [99 x i32] }> 
 *      <{ i32 1, [99 x i32] zeroinitializer }>, align 16
 * 4. int a[100]={1,2,3,4,5};
 *    @a = dso_local global <{ i32, i32, i32, i32, i32, [95 x i32] }> 
 *      <{ i32 1, i32 2, i32 3, i32 4, i32 5, [95 x i32] zeroinitializer }>, align 16
 */
inline std::string genInitializer(ArrayType *arr)
{
    std::ostringstream buffer;
    int fullDimen = 0;
    std::vector<int> vec = arr->getLenVec();
    int size = (int)vec.size();
    int v_size = arr->getValueVec().size();
    int sum = 1;
    for (int i = size - 1; i >= 0; i++)
    {
        sum = sum * vec[i];
        if (sum <= v_size)
        {
            break;
        }
        else
        {
            fullDimen++;
        }
    }
    int rest = vec[size - 1] - v_size;
    std::string basicType_str = arr->getEleType()->toStr();
    if(rest==0){
        buffer<<arr->toStr()<<" ";
        buffer<<"[ ";
        for (int i = 0; i < v_size; i++)
        {
            buffer << basicType_str<< " " << arr->getValueVec()[i];
            if(i!=v_size-1)buffer<< ", ";
        }
        buffer<<" ]";

    }
    else{
        buffer << "<{ ";
        for (int i = 0; i < v_size; i++)
        {
            buffer << basicType_str;
            if(i!=v_size-1)buffer<< ", ";
        }
        if(rest&&v_size)
            buffer<<", ";
        if(rest){
            buffer << "[" << rest << " x " << basicType_str << "]";
        }
        buffer << " }> ";

    if (arr->getZeroInit())
    {
        buffer << "zeroinitializer";
    }
    else
    {
        buffer << "<{ ";
        for (int i = 0; i < v_size; i++)
        {
            buffer << basicType_str << " " << arr->getValueVec()[i];
            if(i!=v_size-1)buffer << ", ";
        }
        if(rest&&v_size)
        buffer<<", ";
        if(rest)
        buffer << "[" << rest << " x " << basicType_str << "] zeroinitializer";
        buffer << " }>";
    }
    }
    return buffer.str();
}
/**
 * ///////////////////////////////////////////////////////////
 * 
 * 5. int a[3][2]={1};
 *    @a = dso_local global [3 x [2 x i32]] [[2 x i32] [i32 1, i32 0], [2 x i32] zeroinitializer, [2 x i32] zeroinitializer], align 16
 * 6. int a[3][2]={1,2,3};
 *    @a = dso_local global [3 x [2 x i32]] [[2 x i32] [i32 1, i32 2], [2 x i32] [i32 3, i32 0], [2 x i32] zeroinitializer], align 16
 *  
 */
#endif