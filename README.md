# OCMethodTrace - Trace Any Objective-C Method Calls

跟踪打印Objective-C任何实例(类)方法

## 功能：
1. 支持任意OC实例(类)方法的跟踪打印
2. 支持多架构(arm32，arm64，i386，x86_64)
3. 支持跟踪存在继承关系的类的方法调用
4. 支持各种灵活配置，包括方法黑白名单等

## 配置说明：
1. 全局配置：
1. 1. LogLevel：Trace日志级别，对应MDTraceLogLevel，必须定义，默认值：0
    0：MDTraceLogLeveError，错误级别
    1：MDTraceLogLeveDebug，调试级别

1. 2. LogWhen：Trace日志输出时机，对应MDTraceLogWhen，必须定义，默认值：0
    0：MDTraceLogWhenStartup ，启动即输出日志
    1：MDTraceLogWhenVolume ，根据音量键控制输出日志(增加音量:输出日志;降低音量:关闭日志;默认时关闭日志)
    2：MDTraceLogWhenMatchString ，输出日志包含匹配字符串才输出日志
         LogMatchString：日志正则匹配字符串，仅当logWhen=MDTraceLogWhenMatchString有效。当日志匹配该字符串时才输出

1. 3. TraceFlag：Trace控制位(尽量在该处扩展)，对应MDTraceFlag，全局必须定义，默认值：0x02，指定类可选定义，默认值：0x00
    0x01：MDTraceFlagDoesNotUseDescription，跳过调用对象description方法，避免不正规的description实现导致递归
    0x02：MDTraceFlagDumpClassListInfo，打印类列表信息，便于调试
    0x04：MDTraceFlagDumpClassMethod，打印某个类的方法(不包括父类方法)，便于调试
    0x08：MDTraceFlagDumpSuperClassMethod，打印某个类的父类方法(包括递归父类的方法)，便于调试

1. 4. TraceObject：Trace对象，对应TraceObject，必须定义，默认值：1
    0：MDTraceObjectNone，屏蔽trace所有类
    1：MDTraceObjectUserClass，trace用户指定类的方法，需要考虑USER_CLASS_LIST+"CORE_CLASS_LIST和USER_CLASS_LIST交集"
    2：MDTraceObjectCoreClass，trace引擎指定类的方法(仅测试验证使用)，仅需要考虑CORE_CLASS_LIST
    3：MDTraceObjectAllClass，trace所有类的方法(仅测试验证使用)，需要考虑USER_CLASS_LIST+CORE_CLASS_LIST两者所有的类
    MDTraceObjectUserClasse和MDTraceObjectAllClass的区别：
        MDTraceObjectUserClasse：在考虑USER_CLASS_LIST指定的类的时候，如果USER_CLASS_LIST和CORE_CLASS_LIST存在部分交集，
    交集对应的类需要合并，合并算法详见：+[MDTraceClassInfo mergeInfoWithCoreInfo:userInfo:userInfo:]
        MDTraceObjectAllClass：需要考虑USER_CLASS_LIST和CORE_CLASS_LIST包含的所有类(不仅交集)。区别详细算法详见：-[ MDMethodTrace parseClassListInfo]

2. 指定类配置：
2. 1. USER_CLASS_LIST：用户指定类列表，必须定义
TraceMode： Trace模式，对应MDTraceMode，可选定义，默认值：1
    0：MDTraceModeOff，屏蔽trace方法
    1：MDTraceModeAll，trace所有方法
    2：MDTraceModeIncludeWhiteList，trace包含"白名单方法列表"的方法
    3：MDTraceModeExcludeBlackList，trace排除"黑名单方法列表"的方法
TraceFlag：定义同全局配置，但是粒度更小，属于某个类范围内，可选定义，默认值：0x00
MethodWhiteList：白名单方法列表，可选定义，但MDTraceModeIncludeWhiteList时必须定义
MethodBlackList：黑名单方法列表，可选定义，但MDTraceModeExcludeBlackList时必须定义

2. 2. CORE_CLASS_LIST：引擎指定类列表，必须定义
TraceMode：定义同USER_CLASS_LIST的TraceMode，但是仅支持MDTraceModeOff和MDTraceModeExcludeBlackList
TraceFlag：定义同全局配置，但是粒度更小，属于某个类范围内，可选定义，默认值：0x00
MethodBlackList：黑名单方法列表，可选定义，但MDTraceModeExcludeBlackList时必须定义

USER_CLASS_LIST和CORE_CLASS_LIST的关系：
CORE_CLASS_LIST：存在的意义在于，OCMethodTrace框架(引擎)内部也需要调用一些OC类方法，为了保证整个框架可以跑起来，
    避免trace到框架内部使用到的类导致的打印递归循环，所以，需排除这些指定类的全部方法或者部分方法。
USER_CLASS_LIST：用户自己指定的类，可以任意发挥。但是如果CORE_CLASS_LIST有相同的类，会优先CORE_CLASS_LIST中
    的配置。合并算法详见"+[MDTraceClassInfo mergeInfoWithCoreInfo:userInfo:userInfo:]"

## 技术要点：
1. 支持跟踪存在继承关系的类的方法调用
    SatanWoo提出了一个方法(见感谢2)，使用“runtime的消息转发机制+跳板原理(桥)”实现，流程：
    每个方法置换到不同的IMP桥上 -> 从桥上反推出当前的调用关系（class和selector）-> 构造一个中间态新名字 -> forwardingTargetForSelector(self, 中间态新名字) 。
    但是SatanWoo的demo(见感谢3)有两个比较大的缺陷：仅支持arm64平台，不支持多架构；仅支持实例方法，不支持类方法。为此我做了一些改进，如下：
    支持多架构：参考objc4(见感谢4)的objc-block-trampolines.m，编写了一个通用的跳板实现，其中通过汇编支持多架构。
    支持类方法：NSObject (OCMethodTrace)需hook类方法"+[NSObject forwardingTargetForSelector:]"
2. trach输出无限循环递归的特殊处理
    递归调用都发生在"-[OCMethodTrace omt_forwardInvocation:]"函数内部，有两个地方：
    对象调用自身的description导致的无限递归：
            为了打印对象的描述，需要调用对象的description方法，而该方法内部很可能会调用对象的其它内部方法，继而递归又调用"-[OCMethodTrace omt_forwardInvocation:]"，
        于是无限循环。当前解决的方法是：在"-[OCMethodTrace omt_forwardInvocation:]"开始处通过遍历函数堆栈链查找"OMTBlockRunBeforeSelector"和"OMTBlockRunAfterSelector"
        这两个方法，可以知道是否存在递归，发现递归就不要再调用runBefore和runAfter回调即可。缺点：遍历函数堆栈链的方法实在不优雅，而且性能也受影响，需要优化！
    OCMethodTrace框架使用到的基础类导致的无限递归：
            比如"-[OCMethodTrace omt_forwardInvocation:]"函数范围内用到一些类：如NSDate，NSString或者runBefore或runAfter回调用到的方法等，一旦他们也被trace，也会导致循环递归。
        解决的思路是：把这些类放在黑名单里，不再trace。当然还有降低循环递归的方式是，内部实现尽量使用C或者C++实现。

## TODO：
1. 通过遍历堆栈链，判断是否存在循环递归调用的算法性能太差，需优化。
2. 开启跟踪所有类(MDTraceObjectAllClass)容易导致异常，不建议开启。
3. 开启全局dump类方法(MDTraceFlagDumpClassMethod)容易导致异常，不建议开启。

## 感谢：
1. https://github.com/qhd/ANYMethodLog
2. https://satanwoo.github.io/2017/09/24/mainthreadchecker1
3. https://github.com/SatanWoo/MainThreadChecker.git
4. https://opensource.apple.com/tarballs/objc4/objc4-723.tar.gz

欢迎提Issues和Pull requests，如有问题，可以联系 Michael Chen (omxcodec@gmail.com)
