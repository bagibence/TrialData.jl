function get_mu_knn(X)
    kdtree = KDTree(X')

    function _get_mu(kdtree, point)
        _, dists = knn(kdtree, point, 3, true)
        return dists[3] / dists[2]
    end

    return [_get_mu(kdtree, point) for point in eachrow(X)]
end

function get_mu_from_precomputed(D)
    function _get_mu(col)
        r1, r2 = sort(col)[[2, 3]]
        return r2 / r1
    end
    
    return [_get_mu(col) for col in eachcol(D)]
end

function _dim_from_mus(mus, discard_fraction)
    N = length(mus)
    
    num_mus_to_keep = Int(N * (1 - discard_fraction))
    indices_to_keep = sortperm(mus)[1:num_mus_to_keep]
    kept_mus = mus[indices_to_keep]
    
    Femp = range(0, num_mus_to_keep-1, step=1) ./ N

    #slope = coef(lm(reshape(log.(kept_mus), :, 1), -log.(1 .- Femp)))[1]
    slope = log.(kept_mus) \ (-log.(1 .- Femp))
    return slope
end


function _twonn_dimension(X, discard_fraction=0.1)
    if size(X, 2) > 25
        D = pairwise(Euclidean(), X')
        return _dim_from_mus(get_mu_from_precomputed(D), discard_fraction)
    else
        return _dim_from_mus(get_mu_knn(X), discard_fraction)
    end
end


"""
    twonn_dimension(X, discard_fraction=0.1; precomputed=false)

Calculate nonlinear dimensionality of `X` using two-NN.

# Extra arguments

- `discard_fraction::Float=0.1`: fraction of distance ratios to discard
- `precomputed::Bool=false`: if true, treat X as a distance matrix instead data samples
"""
function twonn_dimension(X, discard_fraction=0.1; precomputed=false)
    if precomputed
        return _dim_from_mus(get_mu_from_precomputed(X), discard_fraction)
    else
        return _twonn_dimension(X, discard_fraction)
    end
end
