fn foo(){
	var x: bool = true;
	print(x);
}

fn main(){
	var y: bool = false;
	y = true;
	print(y);
	foo();
	bar();
}

fn bar(){
	var z: float = 5.0;
	print(z);
//	print(z/2.0); this doesn't work (give false negative) ;(
}
