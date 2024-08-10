fn main() void {
	var y: float = 2.0;
    print(y);
	y = bar();
    print(y);
    var x: bool = foo();
    print(x);
    taz();
}

fn bar() float {
	var z: float = 5.0;
	print(z);
    return z;
}

fn foo() bool {
    return true;
}

fn taz() void {
    var po: int = 39;
    print(po);
}
