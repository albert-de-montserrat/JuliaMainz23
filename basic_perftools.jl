# # Tools to asses the performance of our functions
# Main tools I use every day:
# * [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) to benchmark the speed and memory allocations of our kernels
# * Profilers to find bottlenecks (e.g. [ProfileCanvas.jl](https://github.com/pfitzseb/ProfileCanvas.jl))
# * `@code_warntype` to check if our code is type stable
# * [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl)
# * Others: [JET.jl](https://github.com/aviatesk/JET.jl), [Aqua.jl](https://github.com/JuliaTesting/Aqua.jl)

# # BenchmarkTools.jl
using BenchmarkTools
f(x, n) = x^n
@btime f(1.2, 3.2)

# Be aware if you want to benchmark functions with non-literal arguments, you 
# need to use the dollar symbol:

x, n = 1.2, 3.2
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
