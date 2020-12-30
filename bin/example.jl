using Tune

@memoize @Vault() function hello_world(hyperparameter, arch=getarch())
    @assert arch == getarch()
    println("running")
    return (hyperparameter, arch)
end

function main(args)
    @info "step 1" hello_world(10)
    @info "step 2" hello_world(11)
    @info "step 3" hello_world(10)
end

main(ARGS)