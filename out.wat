(module
  (type (;0;) (func))
  (type (;1;) (func (param i32)))
  (import "std" "print" (func (;0;) (type 1)))
  (func (;1;) (type 0)
    (local i32 i32 i32)
    i32.const 5
    local.set 0
    i32.const 2
    local.set 1
    local.get 0
    local.get 1
    i32.add
    local.set 2
    local.get 2
    i32.const 3
    i32.div_s
    call 0)
  (start 1))
