# Tune.jl

This started out as an exploration of autotuning utilities in Julia, and culminated in the following list of useful packages, which together provide the necessary functionality:

- [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
- [CpuId.jl](https://github.com/m-j-w/CpuId.jl)
- [DiskCaches.jl](https://github.com/peterahrens/DiskCaches.jl.git)
- [Hwloc.jl](https://github.com/JuliaParallel/Hwloc.jl.git)
- [MemoizedMethods.jl](https://github.com/peterahrens/MemoizedMethods.jl.git)
- [Scratch.jl](https://github.com/JuliaPackaging/Scratch.jl.git)
- [SHA.jl](https://github.com/JuliaLang/julia/tree/master/stdlib/SHA)

In the following example, all of these packages combine to fit a linear cost model to a register-blocked sparse matrix (taken from [SparseMatrixVBCs.jl](https://github.com/peterahrens/SparseMatrixVBCs.jl)):

```julia
@memoize arch_id() = (sha2_256(string(cpuinfo()))...,)

@memoize DiskCache(@get_scratch!("1DVBC_timings")) function model_SparseMatrix1DVBC_time_params(W, Tv, Ti, arch=arch_id())
    @info "calculating $(SparseMatrix1DVBC{W, Tv, Ti}) cost model..."
    @assert arch == arch_id()

    ms = [2^i for i = 0:8]
    mem_max = fld(first(filter(t->t.type_==:L1Cache, collect(Hwloc.topology_load()))).attr.size, 2) #Half the L1 cache size.
    T = Float64[]
    ds = Vector{Float64}[]
    C = Float64[]
    for w in 1:W
        ts = Float64[]
        c = 0
        for m in ms
            L = fld(mem_max, 3 * sizeof(Ti) + m * (sizeof(Tv) * w + sizeof(Ti))) 
            if L >= 1
                n = w * L
                A = sparse(ones(Tv, m, n))
                B = SparseMatrix1DVBC{W}(A, pack_stripe(A, EquiChunker(w)))
                x = ones(m)
                y = ones(n)
                d_α_col = zeros(W)
                d_α_col[w] = L
                d_β_col = zeros(W)
                d_β_col[w] = L * m
                d = [d_α_col; d_β_col]
                mul!(y, B', x)
                t = (@belapsed mul!($y, $B', $x) evals=1_000)
                push!(ds, d)
                push!(T, t)
                @info "w: $w m: $m n: $n L: $L t: $t"
                c += 1
            end
        end
        append!(C, [1/c for _ = 1:c])
    end
    D = reduce(hcat, ds)
    println(size(D))
    P = (Diagonal(sqrt.(C)) * D') \ (Diagonal(sqrt.(C)) * T)
    α_col = (P[1:W]...,)
    β_col = (P[W + 1:end]...,)
    @info "α_col: $α_col"
    @info "β_col: $β_col"
    @info "done!"
    return (α_col, β_col)
end
```
