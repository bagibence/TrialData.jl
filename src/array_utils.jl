import Base.split

"""
    split(x, n)

Split a long array (`x`) into subarrays of given lengths (`n`).
If `x` is a matrix, split along the first dimension.
"""
function Base.split(x::AbstractVector, n)
    result = Vector{Vector{eltype(x)}}()
    #start = firstindex(x)
    start = 1
    for len in n
        push!(result, x[start:(start + len - 1)])
        start += len
    end
    return result
end

function Base.split(x::AbstractMatrix, n)
    result = Vector{Matrix{eltype(x)}}()
    #start = firstindex(x)
    start = 1
    for len in n
        push!(result, x[start:(start + len - 1), :])
        start += len
    end
    return result
end


"""
$(SIGNATURES)

Cumulative average of array along given dimension.
"""
cummean(a::AbstractVector) = cumsum(a) ./ (1:length(a))
cummean(A::AbstractArray; dims) = cumsum(A; dims = dims) ./ (1:size(A, dims))
