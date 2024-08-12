
//fn main() void {
//    var x: float = 2.0;
//    var y: float = 3.0;
//    print(x + y);
//}

//fn main() void {
//    var x: float = 3.0;
//    var y: float = 4.0;
//    var z: float = add(x + y, y + x);
//    print(z);
//    sub(x - y, y - x);
//}
//
//fn add(a: float, b: float) float {
//    //var c: float = a + b;
//    return a + b;
//}
//
//fn sub(a: float, b: float) void {
//    print(a - b);
//}

//fn main() void {
//	var y: float = 2.0;
//    print(y);
//	y = bar();
//    print(y);
//    var x: bool = foo();
//    print(x);
//    taz();
//    lala(5, 2.1);
//}
//
//fn bar() float {
//	var z: float = 5.0;
//	print(z);
//    return z;
//}
//
//fn foo() bool {
//    return true;
//}
//
//fn taz() void {
//    var po: int = 39;
//    print(po);
//}
//
//fn lala(ref: int, refn: float) void {
//    var a: int = 5;
//    print(ref);
//    var b: bool = false;
//}
//

//fn main() void {
//    var x: float = 3.0;
//    var y: float = 4.0;
//
//    var i: float = 10.0;
//    var j: float = 8.0;
//
//    var xi: float = sub(x, i); // -7.0
//    var yj: float = sub(y, j); // -4.0
//
//    var norA: float = normX(xi, yj);
//    var norB: float = normY(xi, yj);
//
//    print(norA);
//    print(norB);
//}
//
//fn sub(a: float, b: float) float {
//    return a - b;
//}
//
//fn normX(a: float, b: float) float {
//    var sqrA: float = a*a + b*b;
//    return a/sqrA;
//}
//
//fn normY(a: float, b: float) float {
//    var sqrB: float = a*a + b*b;
//    return b/sqrB;
//}

fn main() void {
    var x: float = 3.3;
    var y: int = 4;

    x = incrementFloat(incrementFloat(x));
    y = incrementInt(y);

    print(x);
    print(y);
}

fn incrementInt(a: int) int {
    return a + 1;
}

fn incrementFloat(b: float) float {
    return b + 1.0;
}
