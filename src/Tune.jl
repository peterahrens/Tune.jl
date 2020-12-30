module Tune

using Memoize
using CpuId
using UUIDs
using DiskBackedDicts

export @memoize
export @Vault
export getarch

@memoize function getarch()
    return uuid5(UUID("2b1b8f36-4a44-11eb-04f1-23588d707498"), string(cpuinfo()))
end

struct NoEmptyMemoizeDict{K, V, T<:AbstractDict{K, V}} <: AbstractDict{K, V}
    parent::T
end

for f in [:getindex, :keys, :values, :length, :get, :iterate, :delete!, :setindex!, :get!, :empty!]
    @eval function Base.$f(d::NoEmptyMemoizeDict, args...)
        $f(d.parent, args...)
    end
end

function Base.get(f::Base.Callable, d::NoEmptyMemoizeDict, key)
    return get(f, d.parent, key)
end

function Base.get!(f::Base.Callable, d::NoEmptyMemoizeDict, key)
    return get!(f, d.parent, key)
end

function Base.empty!(d::NoEmptyMemoizeDict)
    return nothing
end

function sudo_empty!(d::NoEmptyMemoizeDict)
    return empty!(d.parent)
end

macro Vault()
    fname = joinpath(@__DIR__, "../data", string(uuid5(UUID("81d1007a-4ac8-11eb-0dd6-151dbad3f71a"), string(__source__.file, "_", __source__.line)), "_vault.jld2"))
    return :(()->NoEmptyMemoizeDict(DiskBackedDict($fname)))
end

end