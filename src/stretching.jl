using Interpolations: LinearInterpolation


"""
    stretch(arr::AbstractVector, old_anchors, new_anchors)

Stretch time series by aligning `.old_anchors`. to `new_anchors`. 
"""
function stretch(arr::AbstractVector, old_anchors, new_anchors)
    time = new_anchors[1]:new_anchors[end]
    tt = 1:length(arr)

    stretched = Vector{Float64}(undef, length(time))

    for k in 1:length(new_anchors)-1
        indtofill = new_anchors[k] .<= time .< new_anchors[k+1]

        compress_factor = (old_anchors[k+1] - old_anchors[k]) / (new_anchors[k+1] - new_anchors[k])

        timeint = old_anchors[k] .+ compress_factor .* (time[indtofill] .- new_anchors[k])

        interp = LinearInterpolation(tt, arr)

        stretched[indtofill] = [interp(t) for t in timeint]
    end
    
    return stretched
end


"""
    stretch(arr::AbstractMatrix, old_anchors, new_anchors)

Stretch multiple time series by aligning `.old_anchors`. to `new_anchors`. 
The stretch is applied to each column of the matrix.
"""
function stretch(arr::AbstractMatrix, old_anchors, new_anchors)
    stretched = Matrix{Float64}(undef, length(new_anchors[1]:new_anchors[end]), size(arr, 2))
    
    for j in 1:size(arr, 2)
        stretched[:, j] = stretch(arr[:, j], old_anchors, new_anchors)
    end
    
    return stretched
    
    # alternative one-liner
    #return hcat([stretch(v, get_time_points(trial), new_anchors) for v in eachcol(arr)]...)
end
