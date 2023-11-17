function semivariogram(Zs, Δt; lag_ratio=0.5, lag_max=100.0)
    # sanity check for supplied arguments
    if lag_ratio ≤ 0 || 1 < lag_ratio
        throw(DomainError(lag_ratio, "argument ∉ (0,1)"))
    end

    if lag_max ≤ 0
        throw(DomainError(lag_max, "argument must be positive"))
    end


    Nlags = min(round(Int, lag_ratio*length(Zs)*Δt), round(Int, lag_max/Δt))

    Npoints = length(Zs)

    h = Δt:Δt:(Δt * Nlags)
    γ = zeros(Nlags)

    # NOTE: for now, LoopVectorization.jl only supports rectangular loop indices... may be able to achieve additional
    # speedups once triangular looping is in place


    # add a flag to choose whether or not to use multithreading
    Threads.@threads for i ∈ 1:Nlags
        @inbounds for j ∈ (i+1):Npoints
            γ[i] += (Zs[j] - Zs[j-i])^2
        end
        @inbounds γ[i] = γ[i] / (2*(Npoints-i))
    end

    return γ, h
end

