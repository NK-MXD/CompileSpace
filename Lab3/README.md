# 实验三ZM_flex词法分析器的简单说明文档

> 本次实验为ZM两人合作完成🥰

## 基础要求

1. 利用Lex工具实现词法分析器识别所有单词,能将源程序转化为单词流;
2. 设计符号表,输出单词流中每个单词的词素内容, 单词的类别和属性(常数的属性为数值, 标识符的属性为指向符号表的指针);

**另外, 我们完成了对思考题的思考, 思考题可以在这里找到:
https://gitlab.eduxiji.net/z-m/compilespace/-/tree/master/Lab4/thinking**


## 我们实现的SysY词法分析器支持的SysY语言特性

+ 八进制, 十进制, 十六进制的整型, 十进制浮点数, 十六进制浮点数;
+ 常量和变量的声明和初始化;
+ 算术运算, 逻辑运算, 关系运算表达式;
+ 赋值（=）、表达式语句、语句块、if、while、return等语句的识别;
+ 注释;
+ 变量、常量作用域;
+ 在函数中、语句块（嵌套）中包含变量、常量声明的处理，break、continue语句;

另外, 我们实现了符号表, 用两种方式实现了对不同作用域变量的存储。第一种方式为二维数组的实现方式; 第二种方式为哈希表实现符号表。

我们的项目支持Makefile, 目前使用方式如下：

- make testlabfour: 编译lexer.l，测试test/lab4下所有sy文件。
- make testlevel1-1: 编译lexer.l，测试test/level1-1下所有sy文件。
- make testlevel2-6: 编译lexer.l，测试test/level2-6下所有sy文件。
- make cleanlabfour: 清理编译出的二进制文件及测试结果。
- make cleanlevel1-1: 清理编译出的二进制文件及测试结果。
- make cleanlevel2-6: 清理编译出的二进制文件及测试结果。

这里借鉴了 https://github.com/shm0214/2022NKUCS-Compilers-Lab/tree/lab4 的编写方式和测试样例。

## 项目进度

1. 正则表达式进度管理

- [X] 实现识别各种运算符, 以及识别这些运算符做出相应的动作;
- [X] 能识别各种关键字, 以及这些关键字做出的动作;
- [X] 编写各种进制的数,浮点数等的正则表达式的定义,以及相应的语义动作;
- [X] 能识别各种注释;
- [X] 编写对应的token出现的位置(行号和偏移值);

2. 符号表进度管理

- [X] 实现一个简单的符号表;
- [X] 输出对应的符号的地址指针;
- [X] 实现单个函数判定各种标识符的作用域;
- [X] 实现判断所有函数的标识符的作用域;
- [X] 改进符号表的实现方式;

3. 程序测试进度管理

- [X] 编写程序进行简单测试;

4. 完善进度

- [ ] 写对应的哈希表的实现方式;
- [ ] 写对应的测试样例进行测试;

## 注意事项说明

1. 正则表达式

生成的扫描程序(scanner)运行的时候，它会分析输入来寻找与模式(pattern)匹配的字符串。如果找到多个匹配字符串，它会匹配文本最多的那一个(for trailing context rules，包括trailing部分的长度)。如果找到多个长度相同的匹配字符串，则按照flex输入文件中最先列出的规则选择。

2. 符号表与作用域

这里采用的组织结构是使用两层哈希表, 第一层哈希表是为了存储每一个不同的作用域的符号表,第二层哈希表是为了找到其中每个作用域的符号;
对于不同函数的作用域如何区分????

有以下参考资料可以参考:
> 1.https://lotabout.me/2015/write-a-C-interpreter-3/
> 2.https://blog.csdn.net/weixin_30432579/article/details/102132694
> 3.https://www.cnblogs.com/chuganghong/p/15901809.html

3. 测试用例

有以下参考资料可以参考:
> 1.https://gitlab.eduxiji.net/nscscc/compiler2021/-/tree/master/%E5%85%AC%E5%BC%80%E7%94%A8%E4%BE%8B%E4%B8%8E%E8%BF%90%E8%A1%8C%E6%97%B6%E5%BA%93/2021%E5%88%9D%E8%B5%9B%E6%89%80%E6%9C%89%E7%94%A8%E4%BE%8B/functional
> 
> 2.https://github.com/shm0214/2022NKUCS-Compilers-Lab/tree/lab7/test/level2-6

4. 列的计数

有以下参考资料可以参考:
> https://blog.csdn.net/lishichengyan/article/details/79512373

## 我们遇到的一些细节问题

1. 在{EOL}之前添加<\*>表示所有的换行符可识别(主要是可以识别注释内的换行符);
2. 在词法分析阶段是否要考虑变量的声明和定义的区别?

如果我们在词法分析阶段忽略声明和变量的区别, 例如如下的程序片段:
```cpp
int a;
a = 0;
while(a<10){
	a = a * 2345;
}
return a;
```

```cpp
int a;
a = 0;
while(a<10){
	int a = 1;
	a = a * 2345;
}
return a;
```

如果我们简单地将两种情况看做一种情况, 构建相同的符号表, 相对应的判断代码应当在语义分析当中进行分析;

如果我们区别开来,那么词法分析器就必须处理很多类似的情形, 以及判断程序的正误, 词法分析器所做的事情未免也太多了。

因此，在这里我们简单地考虑一对`{}`当中的变量, 即一个作用域中的变量，将词法分析器所做的工作尽可能减少，将声明与定义的问题留到语义分析中判断。如下为我们建立符号表的关键代码：

```cpp
struct SymTab{
    char ident[20];
    int scope;
    int row;
    int col;
    unsigned long int addr;
}symTab[15][15];

vector<int> globalFrame;
int frameSize[10];
int currentFrame = 0;

...
"{" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACE\t\t{");
        offsets += strlen("{");
        frameSize[stackIdx] = stackAddr + 1;
        globalFrame.push_back(++stackIdx);
        currentFrame=stackIdx;
        stackAddr = 0;
    #else
        return LBRACE;
    #endif
}
"}" {
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACE\t\t}");
        offsets += strlen("}");
        // 切换作用域
        globalFrame.pop_back();
        currentFrame=globalFrame.back();
        int curAddr = frameSize[currentFrame];
        stackAddr = max(curAddr-1,0);
    #else
        return RBRACE;
    #endif
}
...

{ID} {
	bool flag = false;
    for(int i=0;i<=frameSize[stackIdx];i++){
        // 如果查找到（此处已限制在当前作用域）
        if(!strcmp(symTab[stackIdx][i].ident,yytext)){
            DEBUG_FOR_LAB4(string("ID\t\t") + string(yytext), (symTab[stackIdx][i]));
            flag = true;
            break;
        }
    }
    // 当前作用域不存在则新建变量
    if(!flag){
        strcpy(symTab[currentFrame][stackAddr].ident,yytext);
        symTab[currentFrame][stackAddr].row=yylineno;
        symTab[currentFrame][stackAddr].col=offsets;
        symTab[currentFrame][stackAddr].scope=currentFrame;
        symTab[currentFrame][stackAddr].addr=(long unsigned int)&(symTab[currentFrame][stackAddr]);
        DEBUG_FOR_LAB4(string("ID\t\t") + string(yytext),symTab[currentFrame][stackAddr]);
        stackAddr++;
	}
}
```

更近一步的,我们考虑到了数组的局限性(遍历太慢, 存储不便), 我们又考虑了以下两种实现方案:

**第一种方式: 不同作用域用链表来实现, 同一作用域中用哈希表来实现**

如下图所示为我们的实现方式:

[![x4hATe.png](https://s1.ax1x.com/2022/10/28/x4hATe.png)](https://imgse.com/i/x4hATe)

关键代码如下:

```cpp
/*单个符号*/
struct SymTab{
    string name;
    int row;
    int col;
};
/*单个作用域*/
struct ScopeNode{
    unordered_map<string,SymTab> ScopeTab;
    ScopeNode* back;
};
/*全局符号表*/
ScopeNode gloNode;
/*符号表指针*/
ScopeNode* curNode = &gloNode;

...

{ID} {
    /*NODE:这里的逻辑如下:
    * 1. 判断是否存在该变量:先遍历该符号表中当前作用域的符号;再遍历该符号表中全局变量作用域中的符号
    * 2. 加入变量
    */  
    bool flag = true;
    unordered_map<string,SymTab> nowTab;
    nowTab = curNode->ScopeTab;
    if(nowTab.find(yytext)!=nowTab.end()){
        cout<<&(nowTab.find(yytext)->second)<<endl;
        flag = false;
    }
    if(flag){
        nowTab = gloNode.ScopeTab;
        if(nowTab.find(yytext)!=nowTab.end()){
            cout<<&(nowTab.find(yytext)->second)<<endl;
            flag = false;
        }
    }
    
    if(flag){
        unordered_map<string,SymTab>* table = &(curNode->ScopeTab);
        SymTab newID;
        newID.row = yylineno;
        newID.col = column;
        newID.name = yytext;
        table->insert(pair<string,SymTab>(yytext, newID));
    }
}
```

但我们发现在lex中我们很难动态分配内存, 它的每一个动作就相当于一个函数, 而动态分配的Node节点会在函数作用域结束时被释放掉.

```cpp
{LBRACE} {
    /*这里的逻辑是: 只要遇到{就新增加一个节点*/
    ScopeNode newNode;
    newNode.back = curNode;
    curNode = &newNode;
	//这里新定义的newNode会在函数结束时被释放掉
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("LBRACE","{");
    #else
        return LBRACE;
    #endif
}
{RBRACE} {
    /*nowscope--;*/
    /*这里的逻辑是: 只要遇到}就回溯到上一个节点*/
    curNode=curNode->back;
    #ifdef ONLY_FOR_LEX
        DEBUG_FOR_LAB4("RBRACE","}");
    #else
        return RBRACE;
    #endif
}
```

**第二种方式: 同一作用域中用哈希表来实现, 不同作用域的哈希表也用一个哈希表来实现**

为了解决上述问题, 我们采用了俩层哈希表来实现, 核心代码如下:

```cpp
/*定义一个scope变量用于标识作用域*/
struct symbol
{
    int row;
    int col;
    int scope;
    string name;
    unsigned long int addr;
};
/*定义所有作用域的符号表*/
unordered_map<int,unordered_map<string,symbol>> allTab;
...

{ID} {
    /*NODE:这里的逻辑如下:
    * 1. 判断是否存在该变量:先遍历该符号表中当前作用域的符号;再遍历该符号表中全局变量作用域中的符号
    * 2. 加入变量
    */  
    /*1. 判断是否存在该变量*/
    bool flag = true;
    unordered_map<string,symbol> nowTab;
    if(allTab.find(nowscope)!=allTab.end()){
        nowTab = allTab.find(nowscope)->second;
        if(nowTab.find(yytext)!=nowTab.end()){
            flag = false;
        }
    }
    if(flag){
        if(allTab.find(0)!=allTab.end()){
            nowTab = allTab.find(0)->second;
            if(nowTab.find(yytext)!=nowTab.end()){
                flag = false;
            }
        }
    }
    /*2. 没有则添加变量*/
    if(flag){
        /*2.1 如果对应的符号表不存在,则添加符号表*/
        if(allTab.find(nowscope)==allTab.end()){
            unordered_map<int,unordered_map<string,symbol>>* allcur = &allTab;
            unordered_map<string,symbol> newTab;
            symbol newid;
            newid.row = yylineno;
            newid.col = column;
            newid.scope = nowscope;
            newTab[yytext] = newid;
            allcur->insert(pair<int,unordered_map<string,symbol>>(nowscope, newTab));
            newid.addr = (long unsigned int)&(allTab.find(nowscope)->second.find(yytext)->second);
            
            // allTab[nowscope]=newTab;
        }else{
            /*如果对应的符号表存在,则找到符号表向其中加入对应的项*/
            unordered_map<string,symbol>* table = &(allTab.find(nowscope)->second);
            symbol newid;
            newid.row = yylineno;
            newid.col = column;
            newid.scope = nowscope;
            newid.addr = (long unsigned int)&(allTab.find(nowscope)->second);
            table->insert(pair<string,symbol>(yytext, newid));
            // cout<<"我加了新的"<<endl;
            // nowTab[yytext]=newid;
        }
    }
}
```





