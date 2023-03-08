# 类型检查 & 中间代码生成

> Author: Zヾ(≧▽≦*)oM
> Date: 22/11/22——22/12/1

## 实现语法分析器功能


## 小组分工和项目进度管理

本实验由朱、孟二人合作完成，如下是我们的小组分工和进度管理：

朱璟钰负责部分：

1. 实现变量、常量的连续赋值与初始化，以及相应的检查：
   * [X] 使用性检查
   * [X] 类型检查
2. 实现函数声明、定义、调用：
   * [X] 函数调用时的实参、形参的类型检查；
     * [X] 数组参数的维度匹配
3. 实现数组的声明、初始化，元素赋值及相应的检查：
   1. [X] 数组维度声明整型、常量检查；
   2. [X] 左值数组的维度检查；
   3. [X] 数组使用的下标整型检查；
4. 实现浮点数，及相应的类型检查：
   * [X] 赋值时标识符的类型检查；
     * [ ] 隐式类型转换


孟笑朵负责部分：

1. 算术表达式计算过程检查
    * [ ] 数值运算中有数组和函数参与的处理;
    * [ ] 数值运算中隐式转换;
2. 条件判断表达式计算过程检查
    * [ ] 条件判断表达式作为赋值语句的右值;
    * [ ] 条件判断表达式中间过程的类型检查;

## 编译器命令
```
Usage：build/compiler [options] infile
Options:
    -o <file>   Place the output into <file>.
    -t          Print tokens.
    -a          Print abstract syntax tree.
    -i          Print intermediate code
```

## VSCode调试

提供了VSCode调试所需的json文件，使用前需正确设置launch.json中miDebuggerPath中gdb的路径。launch.json中args值即为编译器的参数，可自行调整。

## Makefile使用

* 修改测试路径：

默认测试路径为test，你可以修改为任意要测试的路径。我们已将最终所有测试样例分级上传。

如：要测试level1-1下所有sy文件，可以将makefile中的

```
TEST_PATH ?= test
```

修改为

```
TEST_PATH ?= test/level1-1
```

* 编译：

```
    make
```
编译出我们的编译器。

* 运行：
```
    make run
```
以example.sy文件为输入，输出相应的中间代码到example.ast文件中。

* 测试：
```
    make testlab6
```
该命令会默认搜索test目录下所有的.sy文件，逐个输入到编译器中，生成相应的中间代码.ll文件到test目录中。你还可以指定测试目录：
```
    make testlab6 TEST_PATH=dirpath
```

* 批量测试：
```
    make test
```
对TEST_PATH目录下的每个.sy文件，编译器将其编译成中间代码.ll文件， 再使用llvm将.ll文件汇编成二进制文件后执行， 将得到的输出与标准输出对比， 验证编译器实现的正确性。错误信息描述如下：
|  错误信息   | 描述  |
|  ----  | ----  |
| Compile Timeout  | 生成中间代码超时， 可能是编译器实现错误导致， 也可能是源程序过于庞大导致(可调整超时时间) |
| Compile Error  | 编译错误， 源程序有错误或编译器实现错误 |
|Assemble Error| 汇编错误， 编译器生成的中间代码不能由llvm正确汇编|
| Execute Timeout  |执行超时， 可能是编译器生成了错误的中间代码|
|Execute Error|程序运行时崩溃， 可能原因同Execute Timeout|
|Wrong Answer|答案错误， 执行程序得到的输出与标准输出不同|

具体的错误信息可在对应的.log文件中查看。

* LLVM IR
```
    make llvmir
```
使用llvm编译器生成中间代码。

* 清理:
```
    make clean
```
清除所有可执行文件和测试输出。

