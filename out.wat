(module
  (type (;0;) (func))
  (type (;1;) (func (param f32)))
  (import "std" "print" (func (;0;) (type 1)))
  (func (;1;) (type 0)
    (local f32 f32)
    f32.const 0x1.6p+2 (;=5.5;)
    local.set 0
    f32.const 0x1.e66666p+0 (;=1.9;)
    local.set 1
    local.get 0
    local.get 1
    f32.add
    call 0)
  (start 1))
