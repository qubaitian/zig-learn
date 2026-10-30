# zig-learn

一个语法一个文件、用测试来学 Zig 的练习仓库。每个文件都有大量中文注释,适合初学者。

基于 **Zig 0.16.0** 编写并测试通过。

| 文件 | 内容 |
|---|---|
| `01_variables.zig` | `const`/`var`、整数与浮点、类型转换、溢出、除法、`undefined` |
| `02_arrays_slices.zig` | 数组、`for`/`while`、切片、字符串 |
| `03_structs.zig` | 结构体、方法、`Self`、枚举、`switch`、tagged union |
| `04_errors.zig` | `error`、`!T`、`try`、`catch`、`defer`、`errdefer` |
| `05_optionals.zig` | `?T`、`null`、`orelse`、`.?`、解包 |
| `06_allocator.zig` | `alloc`/`free`、`ArrayList`、`allocPrint`、Arena |
| `07_comptime.zig` | 泛型函数、`anytype`、泛型结构体、`comptime`、`inline for` |

## 运行

```bash
zig test 01_variables.zig

# 只运行名字里包含某段文字的测试
zig test 01_variables.zig --test-filter "整数"
```
