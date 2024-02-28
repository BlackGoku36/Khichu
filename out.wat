(module
  (type (;0;) (func))
  (type (;1;) (func (param f32)))
  (import "std" "print" (func (;0;) (type 1)))
  (func (;1;) (type 0)
    (local f32 f32)
    f32.const 0x1.533334p+2 (;=5.3;)
    f32.const 0x1p+1 (;=2;)
    f32.div
    local.set 0
    f32.const 0x1.433334p+3 (;=10.1;)
    local.set 1
    local.get 0
    f32.const 0x1p+0 (;=1;)
    f32.add
    local.get 1
    f32.add
    call 0)
  (start 1))
