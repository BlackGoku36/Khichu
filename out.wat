(module
  (type (;0;) (func))
  (type (;1;) (func (param f32)))
  (type (;2;) (func (param i32)))
  (import "std" "print" (func (;0;) (type 1)))
  (import "std" "print" (func (;1;) (type 2)))
  (func (;2;) (type 0)
    (local f32 f32)
    f32.const 0x1.8p+1 (;=3;)
    local.set 0
    f32.const 0x1.4p+2 (;=5;)
    local.set 1
    local.get 0
    f32.const 0x1.8p+1 (;=3;)
    f32.add
    f32.neg
    local.get 1
    f32.neg
    f32.add
    f32.neg
    f32.const 0x1.8p+0 (;=1.5;)
    f32.neg
    f32.mul
    call 0)
  (start 2))
