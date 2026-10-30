// ============================================================
// 03_structs.zig —— 结构体、方法、枚举、switch
//
// 运行:  zig test 03_structs.zig
// ============================================================

const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

// ============================================================
// 第一部分:结构体(struct)
// 结构体 = 把几个相关的数据打包在一起,起一个名字。
// ============================================================

// 在 Zig 里,定义结构体的写法是:
//
//   const 名字 = struct { 字段... };
//
// 也就是说:struct { ... } 本身是一个"类型",我们把这个类型存进常量 Point。
// 类型名习惯用大写字母开头。
const Point = struct {
    // 字段:  名字: 类型,
    x: i32,
    // 字段可以有默认值:创建时不写 y,y 就是 0
    y: i32 = 0,

    // ----------------------------------------------------
    // 方法:写在 struct 里面的函数
    // ----------------------------------------------------

    // pub = public(公开),表示别的文件也能调用这个函数。
    // 不写 pub 的话,只有这个文件能用。
    //
    // init 是一个约定俗成的名字,用来"创建一个新对象",
    // 这不是语法要求,只是大家都这么写。
    //
    // 返回类型 Point:返回一个 Point
    pub fn init(x: i32, y: i32) Point {
        // .{ .x = x, .y = y } 是"匿名结构体字面量":
        //   开头的 .  表示"类型让编译器自己推断"(这里推断为 Point,因为返回类型是 Point)
        //   .x = x   表示"把字段 x 设为参数 x"
        return .{ .x = x, .y = y };
    }

    // 第一个参数叫 self,类型是 Point,表示"调用这个方法的那个对象"。
    // 这里 self 是一份"拷贝",只能读,不能改原对象。
    pub fn sum(self: Point) i32 {
        return self.x + self.y;
    }

    // 想修改原对象,第一个参数要写成 *Point(指向 Point 的指针)。
    //   *  表示"指针",*Point 就是"指向一个 Point 的地址"
    // 通过指针访问字段时直接写 self.x 就行,Zig 会自动帮你解引用。
    pub fn move(self: *Point, dx: i32, dy: i32) void {
        // void 表示这个函数不返回任何东西
        self.x += dx;
        self.y += dy;
    }
};

test "结构体:创建和读取字段" {
    // 创建方式 1:写上类型名
    const p = Point{ .x = 1, .y = 2 };
    try expectEqual(1, p.x);
    try expectEqual(2, p.y);

    // 创建方式 2:左边写好类型,右边用 .{ } 省略类型名
    const q: Point = .{ .x = 3 }; // y 没写,用默认值 0
    try expectEqual(0, q.y);
}

test "结构体:调用方法" {
    // 用 init 创建
    const p = Point.init(3, 4);

    // p.sum() 等价于 Point.sum(p),Zig 自动把 p 传给 self
    try expectEqual(7, p.sum());
}

test "结构体:用 *Self 方法修改对象" {
    // 要修改,所以必须是 var
    var p = Point.init(0, 0);

    // move 的 self 是 *Point,Zig 会自动传 &p(p 的地址)进去
    p.move(5, -2);

    try expectEqual(5, p.x);
    try expectEqual(-2, p.y);
}

// ============================================================
// @This() 和 Self:一个很常见的写法
// ============================================================

const Counter = struct {
    // @This() 返回"当前所在的这个类型",也就是 Counter 自己。
    // 很多代码习惯把它叫 Self,这样方法里就不用反复写 Counter。
    const Self = @This();

    count: u32 = 0,

    pub fn increment(self: *Self) void {
        self.count += 1;
    }

    pub fn get(self: Self) u32 {
        return self.count;
    }
};

test "使用 Self 的结构体" {
    // .{} 表示所有字段都用默认值
    var c: Counter = .{};
    c.increment();
    c.increment();
    try expectEqual(2, c.get());
}

// ============================================================
// 第二部分:枚举(enum)
// 枚举 = 一个类型,它的值只能是你列出来的那几个之一。
// ============================================================

const Color = enum {
    red,
    green,
    blue,

    // 枚举里也可以写方法
    pub fn isWarm(self: Color) bool {
        return self == .red;
    }
};

test "枚举:基本用法" {
    const c: Color = .green;
    // .green 是 Color.green 的简写,左边已经知道类型是 Color,所以能省略

    try expect(c == .green);
    try expect(c != Color.red);
    try expect(!c.isWarm());

    // @tagName(枚举值) 把枚举值变成字符串
    try std.testing.expectEqualStrings("green", @tagName(c));
}

// ============================================================
// 第三部分:switch
// switch 根据值走不同的分支,常和枚举一起用。
// ============================================================

fn colorCode(c: Color) u8 {
    // switch 必须"穷尽"所有可能的值,漏掉一个编译就报错。
    // 这样以后给 Color 加一个新颜色,编译器会提醒你所有要改的地方。
    //
    //   值 => 结果,
    return switch (c) {
        .red => 1,
        .green => 2,
        .blue => 3,
    };
}

test "switch:匹配枚举" {
    try expectEqual(1, colorCode(.red));
    try expectEqual(3, colorCode(.blue));
}

test "switch:匹配整数" {
    const n: u8 = 7;

    // 整数有太多可能的值,列不完,所以要用 else 接住"其他所有情况"
    const kind = switch (n) {
        0 => "zero",
        1, 2, 3 => "small", // 多个值用逗号分开
        4...9 => "medium", // 三个点 ... 表示一个范围(包含两头)
        else => "big",
    };
    try std.testing.expectEqualStrings("medium", kind);
}

// ============================================================
// 第四部分:带标签的联合(tagged union)—— 选学
// 一个值"要么是 A 形状、要么是 B 形状",每种形状带的数据不同。
// 第一次看不懂可以先跳过。
// ============================================================

const Shape = union(enum) {
    // 每一种可能:名字: 携带的数据类型
    circle: f64, // 圆:带一个半径
    square: f64, // 正方形:带一个边长

    pub fn area(self: Shape) f64 {
        // switch 一个 union 时,用 |r| 把里面携带的数据取出来
        return switch (self) {
            .circle => |r| 3.0 * r * r, // 简化一下,π 用 3
            .square => |side| side * side,
        };
    }
};

test "tagged union" {
    const s1: Shape = .{ .circle = 2.0 };
    const s2: Shape = .{ .square = 3.0 };
    try expectEqual(12.0, s1.area());
    try expectEqual(9.0, s2.area());
}
