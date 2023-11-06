# # Outline 
# 1. Writing Julia code: type system and multiple-dispatch
# 2. Why is my code so slow?
#      1. Type stabilities
#      2. Heap vs Stack
#      3. Arrays and tuples
# 3. Metaprogramming (i.e. code gen): macros and generated functions
# 4. Boosting performance

# # Writing Julia code
# Julia selling point in a nutshell is 
# > **easy** high-level language with the performance of a low-level language
#
# or
# > reads like Python runs like C
#
# ... but is that so?

n = 256
A, B, C = rand(n,n), rand(n,n), rand(n,n)
f(A, B, C) = sum(A[2:end-1, 2:end-1] .* B[2:end-1, 2:end-1] .+ C[2:end-1, 2:end-1]);

# which reads as MATLAB. Let's benchmark it

using BenchmarkTools
@btime f($A, $B, $C);

# not very impressive. Let's try to make it faster in a Julia way with a one-liner

f1(A, B, C) = sum(A[i, j] * B[i, j] + C[i, j] for i in 2:size(A,1)-1, j in 2:size(A,2)-1)
@btime f1($A, $B, $C);

# not bad, we cut off 50% of the time. Unlike Python and MATLAB, loops in Julia are **fast** (and lead to more readible code), 
# so we can further speed up things if we are willing to type a bit more
function f2(A, B, C) 
    v = 0.0
    nx, ny = size(A)
    for j in 2:ny-1, i in 2:nx-1
        v += A[i, j] * B[i, j] + C[i, j]
    end
    return v
end
@btime f2($A, $B, $C);

# that's already a x2.5 speedup. If we are willing to accept some black magic
# we can use `LoopVectorization.jl` to effortlessly vectorize the loop
using LoopVectorization
function f3(A, B, C) 
    v = 0.0
    nx, ny = size(A)
    @turbo for j in 2:ny-1, i in 2:nx-1
        v += A[i, j] * B[i, j] + C[i, j]
    end
    return v
end
@btime f3($A, $B, $C);

# for a nice x6 speedup.