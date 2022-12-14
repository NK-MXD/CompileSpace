# 编译原理课程作业

> 这是我的编译原理课程的个人仓库，包含每一个实验Lab的全部代码以及最后的实验报告。

## Lab1了解编译器的工作

在本实验中，探究了语言处理系统的工作流程和机制，围绕以下几个方面展开：

1. 预处理器做了什么
2. **编译器做了什么**
3. 汇编器做了什么
4. 链接器做了什么
5. 编写了`LLVM IR`小程序实例，实现了SysY编译器支持的部分语言特性

具体可参考实验文档 [了解编译器实验报告](https://github.com/NK-MXD/CompileSpace/tree/main/Lab1/%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A)

## Lab2 SysY汇编与Yacc使用

本次实验共有两个工作要完成:

工作一:（两人合作完成）

1. 设计SysY编译器的上下文无关语法
2. 设计SysY程序，并给出等价的ARM汇编程序代码

工作二:（单人完成）

1. 实现表达式计算的词法分析Yacc程序
2. 实现将中缀表达式转化为后缀表达式的Yacc程序

## Lab3 最终大作业的flex词法生成器构建

本次实验为实现lex工具实现词法分析器,主要包含的功能如下:

1. 识别所有的单词, 将源程序转化为单词流;
2. 设计符号表, 需要考虑符号表的数据结构, 搜索算法, 词素的保存, 保留字的处理等问题. 常数的属性可以是数值, 标识符是指向符号表的指针;

> 课外探索的部分:
> 1. 设计实现正则表达式到NFA的转化;
> 2. 设计实现NFA到DFA的转化;
> 3. 设计实习DFA的化简;
> 4. 实现模拟DFA的运转的程序;

## Lab4 最终大作业的yacc语法生成器构建

本次实验为实现yacc工具实现的语法分析器, 主要包含的功能如下:

+ 语法树数据结构的设计：结点类型的设计，不同类型的节点应保存的信息。
+ 扩展上下文无关文法，设计翻译模式。
+ 设计 Yacc 程序，实现能构造语法树的分析器。
+ 以文本方式输出语法树结构，验证语法分析器实现的正确性。