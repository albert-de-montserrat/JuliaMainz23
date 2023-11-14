using BenchmarkTools

# # Row/Column-major
# Different programming languages use different memory layouts for arrays. For example matrices are stored in
# row-major format in C/C++, Rust or Python; whereas they are stored in column-major format in Julia, Fortran and MATLAB.
# Because of how data of these matrices is cached when we perform operations on them, the order in which we access the data 
# is important in terms of performance. In Julia we always want to iterate over the inner most index first, so we acces the arrays
# memory contiguously and avoid cache misses
n = 256
A, B, C = rand(n,n), rand(n,n), rand(n,n)
function row_major!(A, B, C)
    for i in axes(A, 1), j in axes(A, 2)
        A[i, j] = B[i, j] * C[i, j]
    end
    return nothing
end
@btime row_major!($A, $B, $C);
#
function column_major!(A, B, C)
    for j in axes(A, 2), i in axes(A, 1)
        A[i, j] = B[i, j] * C[i, j]
    end
    return nothing
end
@btime column_major!($A, $B, $C);

# Julia does biunds checking by default, but you can turn it off with the macro `@inbounds`, 
# usually resulting in faster code
function column_major_inbounds!(A, B, C)
    @inbounds for j in axes(A, 2), i in axes(A, 1)
        A[i, j] = B[i, j] * C[i, j]
    end
    return nothing
end
@btime column_major_inbounds!($A, $B, $C);

# # Stack vs Heap allocation
# These are the places in the memory where data is "stored". The stack is statically allocated and it is ordered.
# This order allows the compiler to know exactly where things are, yielding very quick access. Like everything else that is referred as static 
# the size of variables (i.e. type and length) has to be known at compile time. On the other hand, the heap is dynamically allocated, and not necessarily is unordered, resulting in slower acces. 
# An excellent explanation of the difference between stack and heap can be found in [Rust's docs](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/the-stack-and-the-heap.html).
allocate_heap() = [rand(); rand()]
@btime allocate_heap() # data size is a runtime parameter (~malloc)
#
allocate_stack() = (rand(), rand()) # a tuple of two floats, everything is known at compile time
@btime allocate_stack() 
#
# A very good performance-wise trick if we want to create non-allocating array-like objects is to use StaticArrays.jl
using StaticArrays
allocate_SA() = @SVector [rand(); rand()] # a tuple of two floats, everything is known at compile time
@btime allocate_SA() 

# # In-place vs out-of-place
# It is common that you need to store the results of matrix operations in a new array. Creating the new destination array will obviously allocate, if you need to this operation just once, an out-of-place kernel will do just fine
function outofplace(A, B)
    C = similar(A)
    for i in axes(A, 1), j in axes(A, 2)
        C[i, j] = B[i, j] * C[i, j]
    end
    return C
end
@btime outofplace($A, $B)

# however, it is frequent you need to run the kernel several times, in which case you want to avoid allocating the destination array every time. In this case, you can use an in-place kernel, by pre-allocating the destinating array and just mutating it:
function inplace!(C, A, B)
    for i in axes(A, 1), j in axes(A, 2)
        C[i, j] = B[i, j] * C[i, j]
    end
    return nothing
end
@btime inplace!($C, $A, $B)
# note that in the latter case we do no return anything, as Julia passes arguments by reference to the functions.
# Also note the `!` at the end for the in-place function, this is a convention in Julia to denote that the function mutates its arguments (where the mutating arguments are the first ones).

# # Array-like programming
# # # Broadcasting
# As in MATLAB, Julia allows to perform element-wise operations on arrays, this is called broadcasting. A dot before the target function indicates broadcasting
broadcast1(A, B, C) = A .+ B .+ C
@btime broadcast1($A, $B, $C)

# alternative you can use the macro `@.` to remove dot redundancy and apply broadcasting to all the operations
broadcast2(A, B, C) = @. A + B + C
@btime broadcast2($A, $B, $C)

# See that we are still allocating an output array. We can also do in-place operations with broadcasting by putting a dot before the equal symbol
function broadcasting3!(C, A, B)
    C .= A .+ B
    return nothing
end
@btime broadcasting3!($C, $A, $B);

# # # Array slicing
# We can use MATLAB syntax to slice our arrays
Aslice = A[:, 1];
# However, this is creating a new array out of the slice of A (=allocating). If we want to avoid this, we can use the `@view` macro
@btime @. $C[:, 1] = $A[:, 1] + $B[:, 1] 
# But we can avoid allocations using the `@views` macro
@btime @views @. $C[:, 1] = $A[:, 1] + $B[:, 1] 
# Tip: loops are *fast*, so just loop. Looping often yields faster code, as you can do 
# more optimizations (e.g. loop fusion, caching, loop unrolling, SIMD, etc.), and more readible code
