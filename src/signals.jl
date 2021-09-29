function add_norm!(df, signal)
    norm_field = Symbol(Symbol(signal), :_norm)
    
    df[!, norm_field] = [norm.(eachrow(arr)) for arr in df[!, signal]]
end

function add_norm(df, signal)
    out_df = deepcopy(df)
    add_norm!(out_df, signal)
    return out_df
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
