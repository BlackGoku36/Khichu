(module
  (type (;0;) (func))
  (type (;1;) (func (param i32)))
  (import "std" "print" (func (;0;) (type 1)))
  (func (;1;) (type 0)
    (local i32)
    i32.const 3
    local.set 0
    local.get 0
    i32.const 3
    i32.add
    i32.const -1
    i32.mul
    i32.const -1
    i32.mul
    call 0)
  (start 1))
