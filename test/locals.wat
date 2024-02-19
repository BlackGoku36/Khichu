(module
  (func $add (result i32) (local $lhs i32) (local $extra f32) (local $rhs i32)
    i32.const 2
    local.set $lhs
    i32.const 3
    local.set $rhs
    local.get $lhs
    local.get $rhs
    i32.add)
    (export "add" (func $add))
  )
