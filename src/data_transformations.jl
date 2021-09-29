function center(arr)
    # center each column to zero by removing the mean
    return arr .- mean(arr, dims=1)
end

function center(df, fieldname)
    arr = concat_trials(df, fieldname)
    mean_field = mean(arr, dims=1)

    return [trial[fieldname] .- mean_field for trial in eachrow(df)]
end


col_range(arr) = maximum(arr, dims=1) - minimum(arr, dims=1)
row_range(arr) = maximum(arr, dims=2) - minimum(arr, dims=2)

function center_normalize(arr)
    return (arr .- mean(arr, dims=1)) ./ col_range(arr)
end

function center_normalize(df, fieldname)
    arr = concat_trials(df, fieldname)
    mean_field = mean(arr, dims=1)
    range_field = col_range(arr)

    return [(trial[fieldname] .- mean_field) ./ range_field for trial in eachrow(df)]
end


function zero_normalize(arr)
    return (arr .- minimum(arr, dims=1)) ./ col_range(arr)
end

function zero_normalize(df, fieldname)
    arr = concat_trials(df, fieldname)
    min_field = minimum(arr, dims=1)
    range_field = col_range(arr)

    return [(trial[fieldname] .- min_field) ./ range_field for trial in eachrow(df)]
end


function z_score(vect::AbstractVector)
    return (vect .- mean(vect)) ./ std(vect)
end

function z_score(mat::AbstractMatrix)
    return (mat .- mean(mat, dims=1)) ./ std(mat, dims=1)
end

function z_score(df, fieldname)
    arr = concat_trials(df, fieldname)
    mean_field = mean(arr, dims=1)
    std_field = std(arr, dims=1)

    return [(trial[fieldname] .- mean_field) ./ std_field for trial in eachrow(df)]
end


function soft_normalize(arr; alpha=5)
    norm_factor = col_range(arr) .+ alpha

    return arr ./ norm_factor
end

function soft_normalize(df, fieldname; alpha=5)
    whole_signal = concat_trials(df, fieldname)
    norm_factor = col_range(whole_signal) .+ alpha

    return [trial[fieldname] ./ norm_factor for trial in eachrow(df)]
end


function sqrt_transform(arr)
    return sqrt.(arr)
end

function sqrt_transform(df, fieldname)
    return [sqrt_transform(trial[fieldname]) for trial in eachrow(df)]
end


"""
    transform_signal(df, signal, trafo::Function)
    transform_signal(df, signals, trafo)
    transform_signal(df, signals, trafos)

Apply transformation(s) to signal(s)
"""
function transform_signal(df, signal::T, trafo::Function) where T <: Union{AbstractString, Symbol}
    # TODO handle optional keyword arguments?
    out_df = deepcopy(df)
    out_df[!, signal] = trafo(out_df, signal)
    
    return out_df
end

function transform_signal(df, signals, trafo::Function)
    out_df = deepcopy(df)
    for signal in signals
        out_df[!, signal] = trafo(out_df, signal)
    end
    
    return out_df
end

function transform_signal(df, signals, trafos)
    out_df = deepcopy(df)

    for signal in signals
        for trafo in trafos
            out_df[!, signal] = trafo(out_df, signal)
        end
    end
    
    return out_df
end

