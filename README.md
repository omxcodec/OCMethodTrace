# OCMethodTrace - Trace Any Objective-C Method Calls

跟踪打印Objective-C任何实例(类)方法

## 功能：
1. 支持任意OC实例(类)方法的跟踪打印
2. 支持多架构(arm32，arm64，i386，x86_64)
3. 避免跟踪基类super调用导致的递归死循环
4. 避免输出打印时调用-[description]导致的递归死循环

## TODO：
1. 完善struct类型参数的自动解析

## 感谢：
1. https://github.com/qhd/ANYMethodLog
2. https://github.com/SatanWoo/MainThreadChecker.git
3. https://opensource.apple.com/tarballs/objc4/objc4-723.tar.gz

欢迎提Issues和Pull requests，如有问题，可以联系 Michael Chen (omxcodec@gmail.com)
