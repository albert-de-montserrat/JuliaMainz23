```@meta
EditURL = "tiptop.jl"
```

# Outline
1. Writing Julia code: type system and multiple-dispatch
2. Why is my code so slow?
     1. Type stabilities
     2. Heap vs Stack
     3. Arrays and tuples
3. Metaprogramming (i.e. code gen): macros and generated functions
4. Boosting performance

# Writing Julia code
Julia selling point in a nutshell is
> **easy** high-level language with the performance of a low-level language

or
> reads like Python runs like C

... but is that so?

````@example tiptop
using BenchmarkTools
n = 256
A, B, C = rand(n,n), rand(n,n), rand(n,n)
@btime $A[2:end-1] .* $B[2:end-1] .+ $C[2:end-1]
````

julia> @btime $A[2:end-1] .* $B[2:end-1] .+ $C[2:end-1]
  45.792 μs (8 allocations: 2.00 MiB)

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

