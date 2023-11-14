using BenchmarkTools

# # Working with Arrays
# Imagine that for some obscure reason we want to do a reduction
# of ~ saxpy BLAS kernel ($A_{ij} * B_{ij} + C_{ij}$) on the interior of a 2D array (i.e. excluding the boundaries).

n = 256
A, B, C = rand(n,n), rand(n,n), rand(n,n)
f(A, B, C) = sum(A[2:end-1, 2:end-1] .* B[2:end-1, 2:end-1] .+ C[2:end-1, 2:end-1]);

# which is as ugly as MATLAB. Let's benchmark it
@btime f($A, $B, $C);

# not very impressive. Let's try to make it faster in a Julia way with a one-liner

f1(A, B, C) = sum(A[i, j] * B[i, j] + C[i, j] for i in axes(A,1)[2:end-1], j in axes(A,2)[2:end-1])
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

# that's already a x2.5 speedup. Beyond this point, the optimizations are less language-based and more algorithm-based.
# For example, we could improve the spatial locality of the function by introducing loop unrolling to a given depth (which has to be known at compile time)

function f4(A, B, C, ::Val{N}) where N
    v = 0.0
    nx, ny = size(A)
    blocks = div(nx, N)
    stride = N
    for j in 2:ny-1
        for i in 2:stride:((blocks-1)*stride)-1
            A0 = ntuple(Val(N)) do ix
                Base.@_inline_meta
                @inbounds A[ix+i-1, j]
            end
            B0 = ntuple(Val(N)) do ix
                Base.@_inline_meta
                @inbounds B[ix+i-1, j]
            end
            C0 = ntuple(Val(N)) do ix
                Base.@_inline_meta
                @inbounds C[ix+i-1, j]
            end
            @inbounds v += sum(muladd(A0[k], B0[k], C0[k]) for k in 1:N)
        end
        @inbounds v += sum(muladd(A[i, j], B[i, j], C[i, j]) for i in (((blocks-1)*stride)-1 + stride):nx-1)
    end

    return v
end

@btime f4($A, $B, $C, Val(2)); # 27.554
@btime f4($A, $B, $C, Val(4)); # 17.458

# for a x5-8 speed up. Or if we are willing to accept some black magic
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

# for a nice simpler x6 speedup.  