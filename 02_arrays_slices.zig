// ============================================================
// 02_arrays_slices.zig —— 数组、切片、字符串、循环
//
// 运行:  zig test 02_arrays_slices.zig
// ============================================================

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
// expectEqualStrings(期望字符串, 实际字符串) —— 专门比较两个字符串
const expectEqualStrings = std.testing.expectEqualStrings;

// ============================================================
// 第一部分:数组(Array)
// 数组 = 一排"长度固定"的同类型数据。长度写在类型里。
// ============================================================

test "数组:基本写法" {
    // 类型 [3]i32 读作:"3 个 i32 组成的数组"
    //
    //   const a: [3]i32 = [3]i32{ 1, 2, 3 };
    //            ^^^^^^   ^^^^^^^^^^^^^^^^^^
    //            类型      值:类型名 + 花括号里放元素
    const a: [3]i32 = [3]i32{ 1, 2, 3 };

    // 嫌自己数长度麻烦?把长度写成 _ ,让编译器自己数:
    const b = [_]i32{ 4, 5, 6 };

    // .len 拿到长度
    try expectEqual(3, a.len);
    try expectEqual(3, b.len);

    // 用 [下标] 访问元素,下标从 0 开始
    try expectEqual(1, a[0]);
    try expectEqual(5, b[1]);

    // 越界访问(比如 a[3])在 debug 模式下会直接崩溃,不会读到乱七八糟的内存。
}

test "数组:修改元素需要用 var" {
    // const 数组里的元素也不能改,想改就要用 var
    var arr = [_]i32{ 0, 0, 0 };
    arr[0] = 7;
    arr[2] = 9;
    try expectEqual(7, arr[0]);
    try expectEqual(0, arr[1]);
    try expectEqual(9, arr[2]);
}

test "数组:全部填同一个值 @splat,拼接 ++" {
    // @splat(值) 把数组的每个元素都填成同一个值。
    // 长度从左边的类型 [4]u8 得知。
    const zeros: [4]u8 = @splat(0); // 等于 [_]u8{ 0, 0, 0, 0 }
    try expectEqual(4, zeros.len);
    try expectEqual(0, zeros[3]);

    // ++ 把两个数组拼起来
    const x = [_]i32{ 1, 2 };
    const y = [_]i32{ 3, 4, 5 };
    const xy = x ++ y; // [_]i32{ 1, 2, 3, 4, 5 }
    try expectEqual(5, xy.len);
    try expectEqual(3, xy[2]);
}

// ============================================================
// 第二部分:循环
// ============================================================

test "for 循环:遍历每个元素" {
    const nums = [_]i32{ 1, 2, 3, 4 };
    var sum: i32 = 0;

    // for (要遍历的东西) |每次取出的元素| { ... }
    //
    // 两条竖线 |n| 叫 "capture"(捕获):
    // 每一轮循环,把当前元素"抓出来"放进名字 n 里。
    for (nums) |n| {
        sum += n;
    }
    try expectEqual(10, sum);
}

test "for 循环:同时拿到下标" {
    const nums = [_]i32{ 10, 20, 30 };
    var index_sum: usize = 0;

    // 在 for 里多写一个 0.. ,表示"从 0 开始数的计数器"
    // 竖线里就能接住两个值:元素 n 和下标 i
    for (nums, 0..) |n, i| {
        _ = n; // 这里只想用下标,n 用 _ 丢掉,否则会报"未使用"
        index_sum += i; // 0 + 1 + 2
    }
    try expectEqual(3, index_sum);
}

test "for 循环:遍历一个数字范围" {
    var count: usize = 0;

    // 0..5 表示 0,1,2,3,4(包含 0,不包含 5)
    for (0..5) |i| {
        count += i;
    }
    try expectEqual(10, count); // 0+1+2+3+4
}

test "for 循环:通过指针修改每个元素" {
    var nums = [_]i32{ 1, 2, 3 };

    // &nums 表示"nums 的地址"(指针)
    // |*n|  表示每次拿到的是"指向元素的指针",而不是元素的副本
    // n.*   表示"指针 n 指向的那个值"(解引用)
    //
    // 简单记:想在循环里改元素,就写 &数组 和 |*名字|,用 名字.* 来改
    for (&nums) |*n| {
        n.* *= 10; // 每个元素乘以 10
    }
    try expectEqual(10, nums[0]);
    try expectEqual(30, nums[2]);
}

test "while 循环" {
    var i: i32 = 0;
    var sum: i32 = 0;

    // while (条件) { ... } —— 条件为 true 就一直循环
    while (i < 5) {
        sum += i;
        i += 1;
    }
    try expectEqual(10, sum);

    // 另一种写法:冒号后面的 (j += 1) 在每轮结束时执行,类似 C 的 for 第三段
    var j: i32 = 0;
    var total: i32 = 0;
    while (j < 3) : (j += 1) {
        total += j;
    }
    try expectEqual(3, total);
}

test "break 和 continue" {
    var sum: i32 = 0;
    for (0..10) |i| {
        if (i == 5) break; // break:立刻跳出整个循环
        if (i % 2 == 0) continue; // continue:跳过这一轮剩下的代码,进入下一轮
        sum += @intCast(i); // 只有 1 和 3 会被加上(i 是 usize,转成 i32)
    }
    try expectEqual(4, sum);
}

// ============================================================
// 第三部分:切片(Slice)
// 切片 = 指向"一段连续元素"的视图,长度在运行时才知道。
// 它本身不存数据,只是记住两件事:从哪开始、有多长。
// ============================================================

test "切片:从数组中截取一段" {
    const arr = [_]i32{ 10, 20, 30, 40, 50 };

    // arr[1..4] 表示取下标 1、2、3 的元素(包含开头,不包含结尾)
    //
    // 类型 []const i32 读作:"一个 i32 切片,里面的元素只读"
    //   []      —— 切片(注意方括号里没有数字,和数组 [3] 区分)
    //   const   —— 不能通过这个切片修改元素
    //   i32     —— 元素类型
    const s: []const i32 = arr[1..4];

    try expectEqual(3, s.len);
    try expectEqual(20, s[0]); // 切片的下标从它自己的开头算起
    try expectEqual(40, s[2]);

    // 省略结尾表示"一直到最后"
    const tail: []const i32 = arr[3..];
    try expectEqual(2, tail.len);
}

test "切片:修改切片就是修改原数组" {
    var arr = [_]i32{ 1, 2, 3 };

    // 这里用 []i32(没有 const),就可以通过切片去改元素
    const s: []i32 = arr[0..2];
    s[0] = 99;

    // 切片只是"窗口",改的是原数组
    try expectEqual(99, arr[0]);
}

// 函数参数经常用切片,这样不管多长的数组都能传进来。
// 数组的长度是类型的一部分([3]i32 和 [4]i32 是不同类型),
// 但切片 []const i32 可以接住任意长度。
fn sumSlice(items: []const i32) i32 {
    var total: i32 = 0;
    for (items) |x| total += x; // 循环体只有一行时可以不写花括号
    return total;
}

test "切片:当作函数参数" {
    const a = [_]i32{ 1, 2, 3 };
    const b = [_]i32{ 1, 1, 1, 1, 1 };

    // &a 把数组变成指针,Zig 会自动把它当成切片传进去
    try expectEqual(6, sumSlice(&a));
    try expectEqual(5, sumSlice(&b));
    // 也可以只传一部分
    try expectEqual(2, sumSlice(b[0..2]));
}

// ============================================================
// 第四部分:字符串
// Zig 没有专门的 string 类型。字符串就是"一串字节",也就是 u8 切片。
// ============================================================

test "字符串就是 []const u8" {
    // 双引号 "..." 写出来的是字符串字面量
    const hello: []const u8 = "hello";

    try expectEqual(5, hello.len);

    // 单引号 'h' 是一个字符,本质上是一个整数(ASCII 码)
    try expectEqual('h', hello[0]);

    // 比较字符串不能用 ==(那是比较地址),要用:
    //   std.mem.eql(元素类型, 字符串1, 字符串2)
    try expect(std.mem.eql(u8, hello, "hello"));

    // 测试里用 expectEqualStrings 更方便,失败时会把两个字符串都打印出来
    try expectEqualStrings("hello", hello);

    // 中文是 UTF-8 编码,一个汉字通常占 3 个字节,所以 .len 是字节数,不是字数
    const zh: []const u8 = "你好";
    try expectEqual(6, zh.len);
}

test "字符串拼接(编译期)" {
    // 编译期就知道的字符串,可以直接用 ++ 拼接
    const greeting = "Hello, " ++ "Zig";
    try expectEqualStrings("Hello, Zig", greeting);

    // 运行时拼接需要分配内存,在 06_allocator.zig 里讲。
}
