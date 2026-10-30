// ============================================================
// 04_errors.zig —— 错误处理:error、!、try、catch、defer
//
// 运行:  zig test 04_errors.zig
//
// Zig 没有"异常"(exception)。
// 一个函数可能失败时,它的返回值就是"要么是错误,要么是正常结果"。
// 调用者必须处理这个错误,不能假装没看见——不处理编译就不通过。
// ============================================================

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// ============================================================
// 第一部分:定义错误、返回错误
// ============================================================

// error{ ... } 定义一个"错误集合":列出这个场景下可能出现的错误名字。
// 错误名字习惯用大写开头的驼峰写法。
const MathError = error{
    DivByZero,
    Negative,
};

// 返回类型 MathError!i32 读作:
//   "要么返回 MathError 里的某个错误,要么返回一个 i32"
//
//   MathError ! i32
//   ^^^^^^^^^   ^^^
//   可能的错误   正常结果
fn divide(a: i32, b: i32) MathError!i32 {
    if (b == 0) {
        // error.DivByZero 就是一个错误值,直接 return 出去
        return error.DivByZero;
    }
    return @divTrunc(a, b);
}

// 如果懒得定义错误集合,可以只写 !i32(前面什么都不写),
// 编译器会自己根据函数里出现过的错误推断出来。
fn checkPositive(n: i32) !i32 {
    if (n < 0) return error.Negative;
    return n;
}

// ============================================================
// 第二部分:处理错误的几种方式
// ============================================================

test "方式 1:try —— 出错就往上抛" {
    // try 表达式 等价于:
    //   如果 表达式 是错误 → 当前函数立刻返回这个错误
    //   如果 表达式 是正常值 → 取出正常值继续用
    //
    // 所以 r 的类型是 i32(已经把"可能是错误"的外壳剥掉了)
    const r = try divide(10, 2);
    try expectEqual(5, r);

    // 注意:用 try 的函数自己也必须能返回错误。
    // test 块默认就可以返回错误,所以这里能直接用。
    // 普通函数要写成 fn xxx() !void 这样。
}

test "方式 2:catch —— 出错时给一个默认值" {
    // 表达式 catch 默认值
    // 出错了就用 catch 后面的值代替
    const r = divide(10, 0) catch 0;
    try expectEqual(0, r);

    // 没出错就是正常结果
    const ok = divide(10, 5) catch 0;
    try expectEqual(2, ok);
}

test "方式 3:catch |err| —— 拿到具体是哪个错误" {
    // |err| 把错误"抓出来",放进名字 err
    // 然后用 switch 根据不同错误给不同的结果
    const r = divide(1, 0) catch |err| switch (err) {
        error.DivByZero => -1,
        error.Negative => -2,
    };
    try expectEqual(-1, r);
}

test "方式 4:if / else —— 分别处理成功和失败" {
    // if (可能出错的表达式) |成功的值| { ... } else |错误| { ... }
    if (divide(9, 3)) |value| {
        try expectEqual(3, value);
    } else |err| {
        // 失败时走这里。这次不会走到。
        // 注意:Zig 不允许用 `_ = err;` 把错误随手丢掉,
        // 必须真正处理它,这里选择把它继续往外返回。
        return err;
    }
}

test "检查函数是否返回了指定的错误" {
    // expectError(期望的错误, 表达式)
    // 用来测试"这个调用应该失败,而且失败原因是 X"
    try std.testing.expectError(error.DivByZero, divide(1, 0));
    try std.testing.expectError(error.Negative, checkPositive(-5));
}

// try 在函数之间是怎么"往上抛"的:
fn calc(a: i32, b: i32) !i32 {
    const x = try checkPositive(a); // a 是负数 → 直接返回 error.Negative
    const y = try divide(x, b); // b 是 0    → 直接返回 error.DivByZero
    return y + 1;
}

test "错误会沿着 try 一层层往上传" {
    try expectEqual(3, try calc(4, 2));
    try std.testing.expectError(error.Negative, calc(-4, 2));
    try std.testing.expectError(error.DivByZero, calc(4, 0));
}

// ============================================================
// 第三部分:defer 和 errdefer
// 用来做"清理工作",比如释放内存、关闭文件。
// ============================================================

test "defer:离开当前代码块时执行" {
    var x: i32 = 0;

    // 一对花括号 { } 就是一个"代码块"
    {
        // defer 后面的语句不会立刻执行,
        // 而是等到"离开这个代码块"的时候才执行。
        defer x += 1;

        // 此时 defer 还没执行,x 还是 0
        try expectEqual(0, x);
    } // ← 走到这里离开代码块,执行 x += 1

    try expectEqual(1, x);
}

test "多个 defer:后写的先执行(倒序)" {
    var buf: [3]u8 = undefined;
    var i: usize = 0;

    {
        defer {
            buf[i] = 'A';
            i += 1;
        }
        defer {
            buf[i] = 'B';
            i += 1;
        }
        defer {
            buf[i] = 'C';
            i += 1;
        }
    }

    // 执行顺序是 C、B、A,和书写顺序相反
    // 就像叠盘子:最后放上去的先拿下来
    try std.testing.expectEqualStrings("CBA", &buf);
}

// errdefer:只有在"函数因为错误而返回"时才执行。
// 正常返回时不执行。
//
// 参数 cleanup_count: *i32 是一个"指向 i32 的指针",
// 用来在函数里修改调用者那边的变量。
// cleanup_count.* 表示"指针指向的那个值"。
fn mayFail(fail: bool, cleanup_count: *i32) !void {
    errdefer cleanup_count.* += 1;

    if (fail) return error.Oops; // 出错返回 → errdefer 会执行
    // 走到这里就是正常返回 → errdefer 不执行
}

test "errdefer:只在出错时执行" {
    var count: i32 = 0;

    // &count 是 count 的地址,传给函数让它可以改 count
    try mayFail(false, &count);
    try expectEqual(0, count); // 没出错,errdefer 没执行

    // catch {} 表示"出错了也什么都不做,忽略它"
    mayFail(true, &count) catch {};
    try expectEqual(1, count); // 出错了,errdefer 执行了
}

// 小结:
//   T!U 或 !U      —— 返回类型:可能是错误,也可能是 U
//   error.Xxx      —— 一个错误值
//   try            —— 出错就往上抛
//   catch 值       —— 出错就用默认值
//   catch |e| ...  —— 拿到错误再决定怎么办
//   defer          —— 离开代码块时一定执行
//   errdefer       —— 因为错误离开时才执行
