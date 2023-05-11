using Interpolations: LinearInterpolation


"""
    stretch(arr::AbstractVector, old_anchors, new_anchors)

Stretch time series by aligning `old_anchors` to `new_anchors`. 
"""
function stretch(arr::AbstractVector, old_anchors, new_anchors; verbose=false)
    time = new_anchors[1]:new_anchors[end]
    tt = 1:length(arr)

    stretched = Vector{Float64}(undef, length(time))

    for k in 1:length(new_anchors)-1
        indtofill = new_anchors[k] .<= time .<= new_anchors[k+1]

        compress_factor = (old_anchors[k+1] - old_anchors[k]) / (new_anchors[k+1] - new_anchors[k])

        timeint = old_anchors[k] .+ compress_factor .* (time[indtofill] .- new_anchors[k])
        
        # timeint[end] should be equal to old_anchors[k+1]
        # but sometimes it's slightly larger, probably due to floating point errors
        # just set it to the last anchor
        if timeint[end] > old_anchors[k+1]
            timeint[end] = old_anchors[k+1]
        end

        interp = LinearInterpolation(tt, arr)

        stretched[indtofill] = [interp(t) for t in timeint]
    end
    
    return stretched
end


"""
    stretch(arr::AbstractMatrix, old_anchors, new_anchors)

Stretch multiple time series by aligning `old_anchors` to `new_anchors`. 
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


"""
    get_ordered_median_time_points(df::AbstractDataFrame; idx_fields::Vector{Symbol} = TrialData.get_idx_fields(df))

Returns the ordered median time points across trials and the corresponding idx fields, ordered according to the median time points.
"""
function get_ordered_median_time_points(df::AbstractDataFrame; idx_fields::Vector{Symbol} = TrialData.get_idx_fields(df))

    @assert all(all(.!(ismissing.(df[:, idx_field])) .&& isfinite.(df[:, idx_field])) for idx_field in idx_fields) "idx fields must be finite and non-missing"

    median_time_points = [Int(floor(median(df[:, field]))) for field in idx_fields]

    time_point_ordering = sortperm(median_time_points)

    return median_time_points[time_point_ordering], idx_fields[time_point_ordering]
end


"""
    stretch_signal!(df::AbstractDataFrame, signal::Symbol, anchor_names::Vector{Symbol}, new_anchors::Vector{Int})
    stretch_signal!(df::AbstractDataFrame, signal::Symbol, anchor_names::Vector{Symbol})
    stretch_signal!(df::AbstractDataFrame, signal::Symbol)

Stretches the signal in `df` by interpolating between the values of the signal at the time points specified by `anchor_names` to the time points specified by `new_anchors`. The signal is modified in place.
The resulting stretched signal is saved in a new column with the name `Symbol(signal, :_stretched)`.

If `anchor_names` is not specified, all (ordered) index fields are used as anchors.
If `new_anchors` are not specified, the signal is stretched the median of `anchor_names` across trials in the dataframe.
"""
function stretch_signal!(df::AbstractDataFrame, signal::Symbol, anchor_names::Vector{Symbol}, new_anchors::Vector{Int})
    @assert length(anchor_names) == length(new_anchors) "must have same number of anchors and new anchors"

    stretched_name = Symbol(signal, :_stretched)

    df[!, stretched_name] = [stretch(trial[signal], [trial[field] for field in anchor_names], new_anchors) for trial in eachrow(df)]

    return df
end

function stretch_signal!(df::AbstractDataFrame, signal::Symbol, anchor_names::Vector{Symbol})
    median_time_points, ordered_idx_fields = get_ordered_median_time_points(df; idx_fields = anchor_names)

    return stretch_signal!(df, signal, ordered_idx_fields, median_time_points)
end

function stretch_signal!(df::AbstractDataFrame, signal::Symbol)
    median_time_points, ordered_idx_fields = get_ordered_median_time_points(df)

    return stretch_signal!(df, signal, ordered_idx_fields, median_time_points)
end
