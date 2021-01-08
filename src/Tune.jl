module Tune

using Memoize
using CpuId
using UUIDs
using Scratch
using Serialization

export @memoize
export @Vault
export Vault
export arch_id

vault_name = "" 

function __init__()
    global vault_name = get_scratch!(@__MODULE__, "vault")
end

@memoize function arch_id()
    return uuid5(UUID("2b1b8f36-4a44-11eb-04f1-23588d707498"), string(cpuinfo()))
end

struct Vault{K,V} <: AbstractDict{K,V}
    path::String
    data::Dict{K, V}
    function Vault{K,V}(path::AbstractString) where {K,V}
        if !(ispath(path))
            dir = splitdir(path)[1]
            mkpath(dir)
            data = Dict{K,V}()
            open(path, "w") do io
                serialize(io, data)
            end
        end
        open(path, "r") do io
            data = deserialize(io)
        end
        return new{K,V}(String(path), data)
    end
end

Vault(path) = Vault{Any, Any}(path)

function _vault_save(v::Vault{K, V}) where {K, V}
    open(v.path, "w") do io
        serialize(io, v.data)
    end
end

function Base.get!(v::Vault{K, V}, key, default) where {K, V}
    if haskey(v.data, key)
        return v.data[key]
    else
        v.data[key] = default
        _vault_save(v)
        return v.data[key]
    end
end

function Base.get!(f::Union{Function, Type}, v::Vault{K, V}, key) where {K, V}
    if haskey(v.data, key)
        return v.data[key]
    else
        v.data[key] = f()
        _vault_save(v)
        return v.data[key]
    end
end

function Base.empty!(v::Vault{K, V}) where {K, V}
    return nothing
end

Base.iterate(v::Vault) = iterate(v.data)
Base.iterate(v::Vault, state) = iterate(v.data, state)

function sudo_empty!(v::Vault{K, V}) where {K, V}
    empty!(v.data)
    _vault_save(v)
end

macro Vault(args...)
    if length(args) == 0
        tag = uuid5(UUID("81d1007a-4ac8-11eb-0dd6-151dbad3f71a"), string(__source__.file, "_", __source__.line))
    elseif length(args) == 1
        tag = args[1]
    else
        error("too many arguments for macro @Vault")
    end

    tag_name = string(tag, ".vault")
    return :(()->Vault(joinpath($(Tune).vault_name, $(tag_name))))
end

end
