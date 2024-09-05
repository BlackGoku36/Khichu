fn main() void {
    var x: int = 0;
    while (x < 5) {
        print(x);
        var y: int = 0;
        while(y < 10){
            print(y);
            y = y + 1;
        }
        x = x + 1;
    }
}
