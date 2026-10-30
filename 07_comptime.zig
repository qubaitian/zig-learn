// ============================================================
// 07_comptime.zig —— 编译期执行 comptime 和泛型
//
// 运行:  zig test 07_comptime.zig
//
// comptime = compile time(编译期)
// Zig 可以在"编译的时候"就执行一部分代码。
// 最重要的用途:写"泛型"——一份代码适用于多种类型。
//
// 在 Zig 里,"类型"本身也是一种值(它的类型叫 type),
// 可以当作参数传给函数,也可以作为函数的返回值。
// ============================================================

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

// ============================================================
// 第一部分:类型也是值
// ============================================================

test "类型可以存进常量" {
    // MyInt 是一个常量,它的值是类型 i32
    const MyInt = i32;
    const x: MyInt = 5; // 等价于 const x: i32 = 5;
    try expectEqual(5, x);

    // @TypeOf(值) 拿到一个值的类型
    try expect(@TypeOf(x) == i32);

    // @typeName(类型) 把类型名变成字符串
    try expectEqualStrings("i32", @typeName(MyInt));
}

// ============================================================
// 第二部分:泛型函数 —— 把类型当参数传进去
// ============================================================

// comptime T: type 的意思:
//   T          —— 参数名(类型参数习惯用大写字母)
//   type       —— 这个参数的类型是 type,也就是说"传进来的是一个类型"
//   comptime   —— 这个参数必须在编译期就知道
//
// 后面的 a: T, b: T 表示 a 和 b 的类型就是传进来的 T,
// 返回值类型也是 T。
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

test "泛型函数 max" {
    // 第一个参数传类型,后面传值
    try expectEqual(9, max(i32, 3, 9));
    try expectEqual(2.5, max(f64, 2.5, 1.0));
    try expectEqual(200, max(u8, 200, 100));

    // 编译器会为每种用到的 T 各生成一份代码,
    // 运行时没有任何额外开销。
}

// ============================================================
// 第三部分:anytype —— 让编译器自己推断参数类型
// ============================================================

// anytype 表示"任意类型都行,调用时传什么就是什么"
// @TypeOf(x) 得到 x 的实际类型,用作返回类型
fn double(x: anytype) @TypeOf(x) {
    return x * 2;
}

test "anytype" {
    const a: i32 = 21;
    const b: f64 = 1.5;
    try expectEqual(42, double(a));
    try expectEqual(3.0, double(b));

    // 传一个不能乘以 2 的东西(比如 bool),编译时就会报错
}

// ============================================================
// 第四部分:泛型结构体 —— 返回一个类型的函数
// 这是 Zig 最有特色的写法,标准库里的 ArrayList 就是这么做的。
// ============================================================

// 这个函数接收一个类型 T,返回一个新的类型(type)
// 所以函数名习惯用大写开头,因为它"像一个类型名"。
fn Pair(comptime T: type) type {
    // 返回一个 struct 类型,里面的字段用到了 T
    return struct {
        // @This() 是"当前这个 struct 类型",起名 Self 方便方法里使用
        const Self = @This();

        first: T,
        second: T,

        // 交换两个值,要修改自己,所以 self 是指针 *Self
        pub fn swap(self: *Self) void {
            const tmp = self.first;
            self.first = self.second;
            self.second = tmp;
        }
    };
}

test "泛型结构体 Pair(T)" {
    // Pair(i32) 是一次函数调用,在编译期执行,结果是一个类型。
    // 把它存进常量 IntPair,之后就像普通类型一样用。
    const IntPair = Pair(i32);

    var p = IntPair{ .first = 1, .second = 2 };
    p.swap();
    try expectEqual(2, p.first);
    try expectEqual(1, p.second);

    // 也可以不起名字,直接用
    var s = Pair([]const u8){ .first = "hello", .second = "world" };
    s.swap();
    try expectEqualStrings("world", s.first);

    // 回想一下 06 里的 std.ArrayList(i32),是不是一模一样的写法?
}

// ============================================================
// 第五部分:comptime 表达式 —— 在编译期算好结果
// ============================================================

// 一个普通的递归函数:斐波那契数列
fn fib(n: u32) u32 {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

test "comptime:在编译期算出结果" {
    // 在调用前加 comptime,表示"在编译的时候就算好"。
    // 编译出来的程序里,result 直接就是 55,运行时不用再算。
    const result = comptime fib(10);
    try expectEqual(55, result);

    // 不加 comptime 的话,就是普通的运行时调用,结果一样
    try expectEqual(55, fib(10));
}

test "comptime 代码块" {
    // comptime { ... } 里的代码全部在编译期执行
    const squares = comptime blk: {
        // blk: 是给这个代码块起的"标签"名字(名字随便起,blk 是惯例)
        var arr: [5]u32 = undefined;
        for (0..5) |i| {
            arr[i] = @intCast(i * i);
        }
        // break :blk 值  →  跳出名为 blk 的代码块,并把"值"作为整个块的结果
        break :blk arr;
    };

    try expectEqual(16, squares[4]);
}

// ============================================================
// 第六部分:inline for —— 在编译期展开循环
// 普通 for 不能遍历"类型列表",因为类型只在编译期存在。
// inline for 会在编译期把循环展开成多份代码。
// ============================================================

test "inline for 遍历多个类型" {
    // 一个数组,里面放的是类型
    const types = [_]type{ u8, i32, u64 };

    inline for (types) |T| {
        // 每一轮 T 是一个不同的类型
        // @sizeOf(T) 返回这个类型占多少字节
        try expect(@sizeOf(T) >= 1);
        try expectEqual(0, max(T, 0, 0));
    }
}

// 小结:
//   type            —— "类型"的类型,类型本身也是值
//   comptime T: type —— 泛型参数:传进来一个类型
//   anytype         —— 任意类型参数,让编译器推断
//   fn X(T) type    —— 返回一个新类型 → 泛型结构体
//   comptime 表达式 —— 编译期执行
//   inline for      —— 编译期展开循环
//   @TypeOf / @typeName / @sizeOf / @This —— 常用的类型相关内置函数
