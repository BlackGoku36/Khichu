fn main() void {
    var x: int = 0;
    while (x < 5) {
        if(x > 2){
            printInt(x);
        }
        x = x + 1;
    }
}

fn printInt(a: int) void {
    print(a);
}
