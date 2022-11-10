# 实验二Yacc的简单说明文档

> 本次实验要实现简单的词法处理`Yacc`程序, 包含两大实验内容:
> 1. 实现表达式计算`Yacc程序`
> 2. 实现中缀表达式变换为后缀表达式`Yacc`程序

> **说明**
> 
> 实现的每一个程序文件夹中都有配套的`Makefile`文件, 可直接执行`make`命令生成需要的`Yacc`可执行程序, 也可执行`make test`命令直接执行程序, 运行给定的测试样例.

## 实现表达式计算语法处理程序

程序目录及内容如下:
```
Lab2
|> yacc_sublab1
|   | yacc_expr1: 实现最简单的表达式计算词法处理程序:只能处理简单的四则运算, 不能处理空格等特殊符号, 不能处理多位整数, 无词法处理部分
|   | yacc_expr2: 进行词法分析token处理, 处理空格等特殊符号, 处理多位整数
|   | yacc_expr3: 使用C++, 构建符号表, 实现赋值运算符
```

## 实现中缀表达式变换为后缀表达式`Yacc程序`

程序目录及内容如下:
```
Lab2
|> yacc_sublab2
|   | yacc_format1: 进行简单的中缀表达式向后缀表达式进行转化
|   | yacc_format2: 使用C++进行简单的中缀表达式向后缀表达式进行转化
```
**注:** 在进行C++程序的Yacc程序生成时，需要用`g++`进行链接生成可执行文件

## 程序编写说明

> 程序在编写过程中经过了几次迭代, 最终做成了现在比较满意的结果:

1. **完成基本要求:** 实现了`yacc_expr1`, `yacc_expr2`, `yacc_format1`, `yacc_format2`的基本功能
2. **完成拓展要求:** 实现了`yacc_expr3`中的符号表和赋值运算符
3. **更加方便测试:** 原来的测试过程中尽管增加了`Makefile`文件能够自动生成可执行程序, 但是对应的表达式还是要一个一个手敲, 太麻烦, 这里采用了直接读入文件中的表达式的方法.

**一些啰嗦**: 在第2步中我遇到了一个从来没有遇到过的问题卡了很长时间, 将问题呈现在这里, 加深印象:

在最初的版本中, 为了使得`yylval`变量可以输入多种类型, 查阅资料后, 我在程序中定义了这样的联合体:
```cpp
%union {
    double d_val;
    string s_val;
}
```
结果出现了诸如`s_val定义找不到`的一大堆错误, 最初我以为是程序本身逻辑的问题, 最后发现原来是**C++11中不可以在union中使用string, vector**

> 原因是union中不能包含存在构造函数的类型, 有也会被编译器删除掉, 参考[(28条消息) 【c++】关于在联合体中使用string_laohehehe的博客-CSDN博客](https://blog.csdn.net/e345ug/article/details/112252951)
> 踩坑解决 https://stackoverflow.com/questions/67073659/why-string-vector-etc-does-not-work-in-union-in-bison

> 当然程序中还有很多不完善的地方, 值得探索的地方: 结合`Flex`工具进行词法分析, 添加其他标识符等的定义等等......暂时懒得写了,姑且到这里.

## 致谢

程序编写过程中还参考了以下资料:
1. [手把手教程-lex与yacc/flex与bison入门（一）](https://blog.csdn.net/weixin_44007632/article/details/108666375)
2. [yacc学习笔记（三）变量和有类型的标记](https://blog.csdn.net/sxqinjh/article/details/104656057)
