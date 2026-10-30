// ============================================================
// 06_allocator.zig —— 内存分配器 Allocator
//
// 运行:  zig test 06_allocator.zig
//
// 前面的数组都是"长度在写代码时就确定"的。
// 如果长度要到运行时才知道(比如读文件、用户输入),
// 就需要在运行时向系统"申请"一块内存,用完再"还回去"。
//
// Zig 的规则:任何需要申请内存的函数,都要你显式传入一个 Allocator(分配器)。
// 所以只看函数参数,就知道它会不会申请内存。
// ============================================================

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

// ------------------------------------------------------------
// std.testing.allocator 是测试专用的分配器,它有一个超级有用的功能:
// 测试结束时,如果你申请的内存没有全部还回去(内存泄漏),
// 测试会直接失败,并告诉你是哪一行申请的。
// 学习阶段用它来练习,非常合适。
// ------------------------------------------------------------

test "alloc / free:申请一块数组内存" {
    const allocator = std.testing.allocator;

    // allocator.alloc(元素类型, 个数)
    // 申请能放 3 个 i32 的内存,返回一个切片 []i32
    //
    // 为什么要 try?因为申请内存可能失败(内存不够),
    // 失败时会返回 error.OutOfMemory
    const buf = try allocator.alloc(i32, 3);

    // defer:离开这个测试时自动释放。
    // 习惯:申请完的下一行,马上写 defer 释放,就不会忘。
    defer allocator.free(buf);

    // 刚申请的内存里是什么值不确定(类似 undefined),先赋值再用
    buf[0] = 1;
    buf[1] = 2;
    buf[2] = 3;
    try expectEqual(3, buf.len);
    try expectEqual(2, buf[1]);
}

test "create / destroy:申请单个对象" {
    const allocator = std.testing.allocator;

    // alloc 申请"一组",create 申请"一个"
    // 返回的是指针 *i32(指向这块内存的地址)
    const p = try allocator.create(i32);
    defer allocator.destroy(p); // create 对应 destroy

    // p.* 表示"指针 p 指向的那个值"
    p.* = 42;
    try expectEqual(42, p.*);
}

// ============================================================
// 函数需要申请内存时:把 allocator 当参数传进去
// ============================================================

// std.mem.Allocator 是分配器的类型。
// 这个函数返回一个新申请的切片 [0, 1, 2, ..., n-1]。
//
// 返回类型 ![]usize:可能出错(内存不够),成功时返回 usize 切片。
//
// 重要约定:函数返回了申请的内存,"谁调用,谁负责释放"。
fn makeRange(allocator: std.mem.Allocator, n: usize) ![]usize {
    const result = try allocator.alloc(usize, n);
    for (result, 0..) |*item, i| {
        item.* = i;
    }
    return result;
}

test "函数接收 allocator 参数" {
    const allocator = std.testing.allocator;

    const r = try makeRange(allocator, 4);
    defer allocator.free(r); // 调用者负责释放

    try expectEqual(4, r.len);
    try expectEqual(3, r[3]);
}

// ============================================================
// ArrayList:可以自动变长的数组(类似其他语言的 vector / list)
// ============================================================

test "ArrayList:动态数组" {
    const allocator = std.testing.allocator;

    // std.ArrayList(i32) 是"元素为 i32 的动态数组"类型。
    // .empty 表示"一个空列表"。
    var list: std.ArrayList(i32) = .empty;

    // 用完要释放它内部申请的内存,同样要传 allocator
    defer list.deinit(allocator);

    // append 往末尾加元素。
    // 加元素时可能需要扩容(申请更大的内存),所以要传 allocator,也要 try
    try list.append(allocator, 10);
    try list.append(allocator, 20);
    try list.append(allocator, 30);

    // list.items 是一个切片,里面就是当前所有元素
    try expectEqual(3, list.items.len);
    try expectEqual(20, list.items[1]);

    // pop() 取出并删掉最后一个元素,返回 ?i32(列表为空时返回 null)
    const last = list.pop();
    try expectEqual(30, last.?);
    try expectEqual(2, list.items.len);
}

// ============================================================
// 运行时拼字符串:std.fmt.allocPrint
// ============================================================

test "allocPrint:格式化生成一个新字符串" {
    const allocator = std.testing.allocator;

    // 类似其他语言的 sprintf / format。
    //   第 2 个参数是格式字符串:
    //     {d} —— 以十进制显示一个数字
    //     {s} —— 显示一个字符串
    //   第 3 个参数 .{ ... } 是要填进去的值,按顺序对应每个 {}
    //
    // .{ 1, 2, "Zig" } 是一个"匿名元组",就是一组值打包在一起
    const s = try std.fmt.allocPrint(allocator, "{d} + {d} = {s}", .{ 1, 2, "Zig" });
    defer allocator.free(s);

    try expectEqualStrings("1 + 2 = Zig", s);
}

// ============================================================
// ArenaAllocator:一次性全部释放
// 适合"申请很多小东西,最后一起扔掉"的场景,不用一个一个 free。
// ============================================================

test "ArenaAllocator:最后一起释放" {
    // arena 建在另一个分配器之上(这里用 testing.allocator)
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    // deinit 时,通过 arena 申请的所有内存一次性全部释放
    defer arena.deinit();

    // 从 arena 拿到一个 Allocator 接口来用
    const allocator = arena.allocator();

    // 随便申请,不用写 free
    const a = try allocator.alloc(u8, 100);
    const b = try allocator.alloc(u8, 200);
    _ = a;
    _ = b;
}

// ============================================================
// 想看看内存泄漏会怎样?
//
// 把上面第一个测试里的这一行注释掉:
//     defer allocator.free(buf);
// 然后运行 zig test 06_allocator.zig
// 你会看到测试失败,并提示 "memory address ... leaked",
// 还会显示是哪一行申请的。试完记得改回来。
// ============================================================

// 常用分配器速查:
//   std.testing.allocator         —— 测试用,能检测泄漏
//   std.heap.ArenaAllocator       —— 一次性统一释放
//   std.heap.page_allocator       —— 直接向操作系统要内存,简单但较慢
//   std.heap.DebugAllocator       —— 写正式程序时调试用,也能检测泄漏
