module Tune

using CpuId
using Hwloc
using BenchmarkTools
using MemoizedMethods
using DiskCaches
using Scratch
using SHA

@memoize arch_id() = (sha2_256(string(cpuinfo()))...,)

export @memoize DiskCache @get_scratch! arch_id


end
