function add_norm!(df, signal, out_field)
    df[!, out_field] = [norm.(eachrow(arr)) for arr in df[!, signal]]
end

function add_norm!(df, signal)
    norm_field = Symbol(Symbol(signal), :_norm)
    
    add_norm!(df, signal, norm_field)
end

function add_norm(df, signal, out_field)
    out_df = deepcopy(df)
    add_norm!(out_df, signal, out_field)
    return out_df
end

function add_norm(df, signal)
    norm_field = Symbol(Symbol(signal), :_norm)
    return add_norm(df, signal, norm_field)
end


rename_fields = rename


# if all the elements are the same string, then the _col_mean should be that string
function _col_mean(v::T) where T <: AbstractVector{String}
    if length(unique(v)) == 1
        return v[1]
    else
        return missing
    end
end
# otherwise try taking the mean
_col_mean(v) = mean(v)

function trial_average(df, condition)
    gd = groupby(df, condition)
    
    dd = Dict()
    for col in names(df)
        dd[col] = [_col_mean(subdf[!, col]) for subdf in gd]
    end
    
    return DataFrame(dd)
end

function trial_average(df)
    dd =  Dict(col => [_col_mean(df[!, col])]
               for col in Symbol.(names(df)))

    return DataFrame(dd)
end


function subtract_cross_condition_mean(df, ref_field)
    out_df = deepcopy(df)
    
    for col in time_varying_fields(out_df, ref_field)
        mean_act = mean(out_df[!, col])
        out_df[!, col] = [arr .- mean_act for arr in out_df[!, col]]
    end
    
    return out_df
end

function subtract_cross_condition_mean(df)
    ref_field = _ref_time_field(df)
    return subtract_cross_condition_mean(df, ref_field)
end

lendiff(arr::AbstractVector) = [0; diff(arr)];
lendiff(arr, dims=1) = mapslices(lendiff, arr, dims=dims);

function add_gradient(df, signal, outfield)
    outdf = deepcopy(df)
    outdf[!, outfield] = [lendiff(v) ./ df.bin_size[1] for v in df[!, signal]]

    return outdf
end

function add_gradient(df, signal)
    diff_field = Symbol(:d, Symbol(signal))
    return add_gradient(df, signal, diff_field)
end


"""
    time_average(df, signal)

Return a N_trials x N_features matrix with the given signal averaged through time on each trial, then concatenated
"""
function time_average(df, signal)
    return vcat((mean(arr, dims = 1) for arr in df[:, signal])...)
end;
