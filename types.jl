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
Base.(+)(x::Dual1, y::Dual1) = Dual1(x.val + y.val, 0.0)
Base.(+)(x::Dual1, y::Number) = Dual1(x.val + y.val, 0.0)
Base.(+)(x::Number, y::Dual1) = Dual1(x.val + y.val, 0.0)
#
x = Dual1(1.0, 2.0)
x = Dual1(1.0, 2.0)
