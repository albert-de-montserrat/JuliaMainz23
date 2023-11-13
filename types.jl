# # Types / struct
# As opposed to Object-Oriented-Perogramming, one of the key features of Julia is the so-called multiple dispatch. It is a powerful
# code dessign pattern that allows to write (typically highly abstract) generic code. 
# From a simple point of view, multiple dispatch means that you can write several functions
# with the same name, but with different methods depending on the number and types of the arguments

foo(x::Float64) = 2*x
foo(x::Int64) = 4*x
foo(x) = "Hello"
#
foo(1)
#
foo(1.0)
#
foo(2f0)

# This means that I could extend a given method for a type that is defined in an external package.
# Typical one wants to create its own dat type, this is done with `struct`. For example I can create a
# `Dual` number type and define the rules for addition (basically the so-called operator overloading approach for forward mode auto-differentiation)
struct Dual1
    val
    partial
end
import Base: +, *, ^
(+)(x::Dual1, y::Dual1)  = Dual1(x.val + y.val, x.partial + y.partial)
(+)(x::Dual1, y::Number) = x + Dual1(y, 0.0)
(+)(x::Number, y::Dual1) = y + Dual1(x, 0.0)
(*)(x::Dual1, y::Dual1)  = Dual1(x.val * y.val, x.val * y.partial + y.val * x.partial)
(*)(x::Dual1, y::Number) = x * Dual1(y, 0.0)
(*)(x::Number, y::Dual1) = y * Dual1(x, 0.0)
(^)(x::Dual1, n::Number) = Dual1(x.val^n, n*x.partial * x.val^(n-1))
#
f(x) = x^2 + 2*x + 1
x1 = Dual1(3.0, 1.0)
f(x1)
# Ok, it works. Now lets benchmark it, the operations are trivial so we should expect speed and no allocations....
@btime f($x1)
# or not. Unexpected allocations are usually due to some type instability, so lets see what `@code_warntype` says
@code_warntype f(x1)
# it seems it's not bad, everything is in blue. Lets take a better look using JET.jl
using JET
@report_opt f(x1)
# it seems that the problem is that the compiler is not able to infer the types of `Dual1.val` and `Dual1.partial`, leading to runtime dispatch.
# This is due to the fact that we did not specify the type of the fields of the struct. We can do it in the following way by parameterizing the `struct`
struct Dual2{T}
    val::T
    partial::T
end
(+)(x::Dual2, y::Dual2)  = Dual2(x.val + y.val, x.partial + y.partial)
(+)(x::Dual2{T}, y::Number) where T = x + Dual2(T(y), 0.0)
(+)(x::Number, y::Dual2{T}) where T = y + Dual2(T(x), 0.0)
(*)(x::Dual2, y::Dual2)  = Dual2(x.val * y.val, x.val * y.partial + y.val * x.partial)
(*)(x::Dual2{T}, y::Number) where T = x * Dual2(T(y), 0.0)
(*)(x::Number, y::Dual2{T}) where T = y * Dual2(T(x), 0.0)
(^)(x::Dual2, n::Number) = Dual2(x.val^n, n*x.partial * x.val^(n-1))
#
x2 = Dual2(3.0, 1.0)
f(x2)
#
@btime f($x2)
#
@code_warntype f(x2)

# # # Note on structs
# - structs are immutable by default, but you can make them mutable by adding `mutable struct`
mutable struct Foo1{T}
    a::T
end
a = Foo1(5)
a.a = 6
# - Array *values* are mutable, but the array itself is not. 
struct Foo2{T}
    a::T
end
b = Foo2(zeros(5))
b.a[1] = 1.0
# - We can also use references to mutate scalar values in immutable structs 
struct Bar{T}
    a::Ref{T}
end
c = Bar(Ref(5))
c.a[] = 6
#
@btime $a.a = 6
@btime $c.a[] = 6
