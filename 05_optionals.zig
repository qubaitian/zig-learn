// ============================================================
// 05_optionals.zig —— 可选类型 ?T 和 null
//
// 运行:  zig test 05_optionals.zig
//
// 很多语言里,任何东西都可能是 null,一不小心就崩溃。
// Zig 里,普通类型永远不可能是 null。
// 只有你明确写了 ?T(T 是任意类型),它才"可能是 null"。
// ============================================================

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// ============================================================
// 第一部分:?T 是什么
// ============================================================

test "?i32:要么是一个 i32,要么是 null" {
    // ?i32 读作"可选的 i32"(optional i32)
    //   ?    —— 表示"可能没有"
    //   i32  —— 有的话,它是一个 i32
    //
    // null 表示"没有值"
    var maybe: ?i32 = null;
    try expect(maybe == null);

    // 也可以放一个正常值进去
    maybe = 5;
    try expect(maybe != null);

    // 普通的 i32 不能赋值为 null,下面这行会编译报错:
    // const n: i32 = null;
}

// ============================================================
// 第二部分:怎么把值"取出来"
// ?i32 不能直接当 i32 用,必须先确认它不是 null,把值取出来。
// ============================================================

test "方式 1:orelse —— 是 null 就用默认值" {
    const a: ?i32 = null;
    const b: ?i32 = 7;

    // 表达式 orelse 默认值
    // 如果左边是 null,就用右边的默认值;否则用左边的值
    // 结果的类型是 i32(不再是 ?i32)
    const x = a orelse 42;
    const y = b orelse 42;

    try expectEqual(42, x);
    try expectEqual(7, y);
}

test "方式 2:if 解包 —— 不是 null 时才执行" {
    const maybe: ?i32 = 10;

    // if (可选值) |取出来的值| { ... } else { ... }
    //
    // 竖线 |v| 和 for 循环里的一样,叫"捕获":
    // 如果 maybe 不是 null,把里面的 i32 取出来,起名 v
    if (maybe) |v| {
        // 在这里 v 的类型是 i32,可以放心用
        try expectEqual(10, v);
    } else {
        // maybe 是 null 时走这里
        unreachable;
    }
}

test "方式 3:.? —— 我确定它不是 null" {
    const maybe: ?i32 = 3;

    // 值.? 表示"我保证它不是 null,直接取出来"
    // 如果它其实是 null,程序会崩溃(debug 模式)
    // 相当于 maybe orelse unreachable
    const v = maybe.?;
    try expectEqual(3, v);

    // 只在你 100% 确定的时候用 .?
    // 不确定就用 orelse 或 if
}

// ============================================================
// 第三部分:函数返回 ?T —— 表示"可能找不到"
// ============================================================

// 在切片里找一个数,找到返回它的下标,找不到返回 null
// 返回类型 ?usize:可能有下标,可能没有
fn find(items: []const i32, target: i32) ?usize {
    for (items, 0..) |item, i| {
        if (item == target) return i; // 找到了,返回下标
    }
    return null; // 循环结束都没找到
}

test "函数返回 ?T" {
    const nums = [_]i32{ 5, 8, 13 };

    try expectEqual(1, find(&nums, 8).?);
    try expect(find(&nums, 100) == null);

    // 实际使用时常见的写法:
    if (find(&nums, 13)) |index| {
        try expectEqual(2, index);
    }
}

// orelse 后面还可以跟 return,"找不到就直接从函数返回"
fn findOrMinusOne(items: []const i32, target: i32) i32 {
    const index = find(items, target) orelse return -1;
    // 走到这里说明找到了,index 是 usize
    return @intCast(index);
}

test "orelse return" {
    const nums = [_]i32{ 1, 2, 3 };
    try expectEqual(2, findOrMinusOne(&nums, 3));
    try expectEqual(-1, findOrMinusOne(&nums, 9));
}

// ============================================================
// 第四部分:while 解包 —— 一直取,直到 null
// 这是"迭代器"最常见的写法。
// ============================================================

// 一个简单的计数器:每次调用 next() 返回下一个数,数完了返回 null
const Countdown = struct {
    n: i32,

    fn next(self: *Countdown) ?i32 {
        if (self.n == 0) return null; // 数完了
        const current = self.n;
        self.n -= 1;
        return current;
    }
};

test "while 解包:循环到 null 为止" {
    var cd = Countdown{ .n = 3 };
    var sum: i32 = 0;

    // while (可选值) |v| { ... }
    // 每一轮调用 cd.next():
    //   不是 null → 取出来放进 v,执行循环体
    //   是 null   → 循环结束
    while (cd.next()) |v| {
        sum += v; // 3 + 2 + 1
    }
    try expectEqual(6, sum);
}

// ============================================================
// 附:?T 和 !T 的区别(很容易混)
//
//   ?T  —— 可能"没有值"(null),没有原因,只是没有
//          处理方式:orelse、if (x) |v|、.?
//
//   !T  —— 可能"出错了",会带着一个错误原因(error.Xxx)
//          处理方式:try、catch、if (x) |v| else |err|
// ============================================================
