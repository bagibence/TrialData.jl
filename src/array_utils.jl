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
