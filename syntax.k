// ------ Function syntax

fn main() void {
    var x: float = 5.0;
    print(x);
    var a: int = 2;
    var y, z: int, bool = foo(a);
    print(y);
    print(z);
}

fn foo(a: int) int, bool {
    a += 3;
    return a, true;
}

// It should output
// 5.0
// 5
// 1
// ------------------------
