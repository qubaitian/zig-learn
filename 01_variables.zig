// ============================================================
// 01_variables.zig —— 变量、常量、基本类型
//
// 怎么运行(在终端里,先 cd 到这个目录):
//     zig test 01_variables.zig
//
// 只跑名字里包含某段文字的测试:
//     zig test 01_variables.zig --test-filter "整数"
//
// 小提示:Zig 里 // 开头的是注释,编译器会忽略它。
// ============================================================

// ------------------------------------------------------------
// 第一行几乎每个 Zig 文件都有:
//
//   const std = @import("std");
//
// 拆开来看:
//   const       —— 声明一个"常量"(值以后不能改)
//   std         —— 常量的名字,你可以随便起,但大家都叫 std
//   =           —— 赋值
//   @import     —— 以 @ 开头的都是"内置函数"(builtin),编译器自带的
//   ("std")     —— 要导入的东西:"std" 代表标准库
//   ;           —— 每条语句以分号结尾
//
// 导入之后,就可以用 std.xxx 来使用标准库里的东西了。
// ------------------------------------------------------------
const std = @import("std");

// 标准库里的测试工具都在 std.testing 里面。
// 每次都写 std.testing.expect 太长,这里起两个短名字。
//
//   expect(条件)            —— 条件是 true 就通过;是 false 测试就失败
//   expectEqual(期望, 实际) —— 两个值相等就通过;不等就失败,并打印两个值
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// ------------------------------------------------------------
// 什么是 test 块?
//
//   test "名字" {
//       ...代码...
//   }
//
// 只有在运行 `zig test 文件名` 时才会执行。
// 正常编译程序时,test 块会被忽略,所以放心写。
// ------------------------------------------------------------

test "const 常量:赋值后不能改" {
    // const 声明的值永远不能改变。
    const a = 10;

    // 如果你把下面这行的 // 去掉,编译会报错:
    //   error: cannot assign to constant
    // a = 20;

    // ---- 关于 try ----
    // expectEqual 在失败的时候会"返回一个错误"。
    // try 的意思是:如果右边返回了错误,就立刻把错误往外抛(这里就是让测试失败)。
    // 现在你只要记住:写断言时前面加 try 就对了。
    // (错误处理会在 04_errors.zig 里详细讲)
    try expectEqual(10, a);
}

test "var 变量:可以修改" {
    // var 声明的是"变量",之后可以修改。
    //
    //   var b: i32 = 5;
    //       ^  ^^^   ^
    //       |   |    └── 初始值
    //       |   └── 类型:i32 = 32 位有符号整数
    //       └── 名字
    //
    // 冒号 : 后面写的是"类型"。
    var b: i32 = 5;

    // += 是"加上再赋值",等价于 b = b + 1;
    b += 1;
    try expectEqual(6, b);

    // 注意:Zig 很严格——
    //   1. 声明了 var 却从来没改过它,会报错,让你改成 const
    //   2. 声明了变量却从来没用过,也会报错
    // 如果真的想暂时不用某个值,可以写 `_ = 变量名;` 把它"丢掉"。
}

test "类型推断:不写类型也行" {
    // 不写类型时,编译器会根据右边的值自己推断。
    const x = 100; // 推断为 comptime_int(编译期整数,下面会解释)
    const y = 3.14; // 推断为 comptime_float
    const ok = true; // 推断为 bool

    // @TypeOf(值) 是内置函数,返回这个值的"类型"。
    // 在 Zig 里,类型本身也可以当作值来比较。
    try expect(@TypeOf(ok) == bool);

    // 用掉 x 和 y,不然编译器会说"没被使用"
    _ = x;
    _ = y;

    // 注意:var 变量必须写明类型,因为编译器不知道你以后会存多大的数。
    //   var n = 5;       // ❌ 报错
    //   var n: i32 = 5;  // ✅
}

test "整数类型:i 有符号,u 无符号,后面的数字是位数" {
    // 常见的整数类型:
    //   u8   : 0 ~ 255            (u = unsigned,无符号,只能是 0 或正数)
    //   i8   : -128 ~ 127         (i = signed integer,有符号)
    //   i32  : 大约 ±21 亿
    //   u64  : 0 ~ 很大很大
    //   usize: 和 CPU 位数一样大的无符号整数,通常用来表示"长度"和"下标"
    const small: u8 = 200;
    const neg: i8 = -100;
    const index: usize = 3;

    try expectEqual(200, small);
    try expectEqual(-100, neg);
    try expectEqual(3, index);

    // 下面这行会编译失败,因为 u8 装不下 300:
    // const too_big: u8 = 300;
}

test "浮点数和布尔值" {
    // f32 / f64 是小数,数字表示位数,f64 更精确。
    const pi: f64 = 3.14159;
    try expect(pi > 3.0);

    // bool 只有两个值:true 和 false
    const is_ok: bool = true;
    try expect(is_ok);

    // 逻辑运算用英文单词,不是 && || !
    //   and  —— 并且
    //   or   —— 或者
    //   !    —— 取反(这个是符号)
    try expect(is_ok and !false);
    try expect(false or true);
}

test "类型转换:必须明确写出来" {
    // Zig 不会偷偷帮你转类型,需要转的时候要自己写。

    // ---- @as(类型, 值) ----
    // 用于"安全"的转换,比如小类型 → 大类型(不会丢数据)。
    const a: u8 = 10;
    const b: u32 = @as(u32, a); // u8 放进 u32 肯定装得下
    try expectEqual(10, b);

    // ---- @intCast(值) ----
    // 用于"可能装不下"的转换,比如大类型 → 小类型。
    // 目标类型由左边的变量类型决定。
    // 如果运行时真的装不下,程序会崩溃(debug 模式下),帮你提早发现 bug。
    const big: u32 = 42;
    const small: u8 = @intCast(big);
    try expectEqual(42, small);

    // ---- 整数 → 浮点数 ----
    const n: i32 = 7;
    const f: f64 = @floatFromInt(n);
    try expectEqual(7.0, f);
}

test "整数溢出:普通加法溢出会报错,要用 +% 包装运算" {
    const x: u8 = 255; // u8 的最大值

    // 如果写 x + 1,结果 256 超出了 u8 的范围:
    //   - 编译期能算出来时 → 编译报错
    //   - 运行时才发现     → 程序崩溃(debug 模式)
    // 这是 Zig 帮你抓 bug 的方式。

    // 如果你"就是想要"溢出后绕回去(像钟表一样 255 → 0),
    // 用 +%(加号后面跟一个百分号):
    try expectEqual(0, x +% 1);

    // 同理还有:-%(减)、*%(乘)
    const zero: u8 = 0;
    try expectEqual(255, zero -% 1);
}

test "整数除法要用内置函数" {
    // 对于有符号整数(可能是负数),直接写 a / b 在很多情况下会报错,
    // 因为负数除法有"往哪边取整"的歧义,Zig 要你明确说。
    //   @divTrunc —— 向 0 取整:-7 / 2 = -3
    //   @divFloor —— 向下取整:-7 / 2 = -4
    //   @mod      —— 取模(余数总是非负)
    const a: i32 = -7;
    const b: i32 = 2;
    try expectEqual(-3, @divTrunc(a, b));
    try expectEqual(-4, @divFloor(a, b));
    try expectEqual(1, @mod(a, b));
}

test "undefined:先占位,稍后再赋值" {
    // undefined 表示"这里先不放值,里面是什么都不确定"。
    // 读取一个 undefined 的值是 bug,一定要先赋值再读。
    var value: i32 = undefined;
    value = 99;
    try expectEqual(99, value);
}

test "if 也可以当表达式用,产生一个值" {
    const score: i32 = 85;

    // 很多语言里有 a ? b : c,Zig 没有,直接用 if ... else ...
    const passed = if (score >= 60) true else false;
    try expect(passed);
}

// ------------------------------------------------------------
// 附:你在其他文件里会看到的 ?i32 是什么?
//
//   const maybe: ?i32 = null;
//
//   ?i32 读作"可选的 i32":它要么是一个 i32,要么是 null(什么都没有)。
//   这个会在 05_optionals.zig 里专门讲,现在先不用管。
// ------------------------------------------------------------
