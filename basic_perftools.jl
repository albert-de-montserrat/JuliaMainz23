# # Tools to asses the performance of our functions
# Main tools I use every day
# * [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) to benchmark the speed and memory allocations of our kernels
# * Profilers to find bottlenecks (e.g. [ProfileCanvas.jl](https://github.com/pfitzseb/ProfileCanvas.jl))
# * `@code_warntype` to check if our code is type stable
# * [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl)
#
# Others
# * [JET.jl](https://github.com/aviatesk/JET.jl)
# * [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl)

# # BenchmarkTools.jl
using BenchmarkTools
f(x, n) = x^n
x, n = 1.2, 3.2
@btime f(x, n)

# If the expression you want to benchmark depends on variables in the global scope,
# you should use $ to "interpolate" them into the benchmark expression to avoid the problems of benchmarking with globals.
@btime f($x, $n)

# # Type instabilities
# A type instability when the compiler can't predict (infer) at compile time the types of a variable
function foo(x) 
    v = 0.0 
    for i in eachindex(x) 
        v += x[i] 
    end
    v
end
# If we benchmark the previous function with some funky argument, we will observe a non-expected behaviour
x = (1, 0.5, 34, 213.23f0)
@btime foo($x)

# The best way to detect if and where we have type instabilities is with the `@code_warntype` macro
using InteractiveUtils
@code_warntype foo(x)

# If the argument is a homogeneous data container 
x = (1.0, 0.5, 34.0, 213.23)
@code_warntype foo(x)

# # Profilers
# Profilers can help you find bottlenecks in your code.
f1(x,y,n1,n2,a,b,c) = x^n1 * y^(n2-1) * exp((a + b) / c)
function f1()
    A = zeros(64, 64)
    for i in eachindex(A)
        x, y, n1, n2, a, b, c = rand(7)
        A[i] = f1(x,y,n1,n2,a,b,c)
    end
    return A
end
@btime f1();
# As you can see the performance is not great. Let's see where the bottleneck is with the profiler
using ProfileCanvas
ProfileCanvas.@profview for _ in 1:100 f1() end
#
function f2()
    A = zeros(64, 64)
    for i in eachindex(A)
        x, y, n1, n2, a, b, c = ntuple( _ -> rand(), Val(7))
        A[i] = f1(x, y, n1, n2, a, b, c)
    end
    return A
end
@btime f2();
#
ProfileCanvas.@profview for _ in 1:100 f2() end
