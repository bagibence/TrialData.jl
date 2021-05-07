function select_trials(df, query::Function)
    return filter(query, df)
end

function select_trials(df, query::Expr)
    source, fun = DataFramesMeta.get_source_fun(query)

    eval(:($df[DataFramesMeta.df_to_bool($fun($df[!, $source])), :]))
end

macro select_trials(df, query::Expr)
    source, fun = DataFramesMeta.get_source_fun(query)

    :($df[DataFramesMeta.df_to_bool($fun($df[!, $source])), :])
end

function select_trials(df, indices::AbstractVector)
    return df[indices, :]
end


"""
    concat_trials(df, fieldname)

Concatenate the given field of every trial from the dataframe
(Assumes that time is the first axis.)
"""
function concat_trials(df, fieldname)::Array{Float64, 2}
    return vcat(df[!, fieldname]...)
end


function get_sig_by_trial(df, signal)
    return cat(df[!, signal]..., dims=3)
end

function merge_signals(df, signals, out_fieldname)
    out_df = copy(df)

    out_df[!, out_fieldname] = [hcat(trial[signals]...) for trial in eachrow(df)]

    return out_df
end

merge_fields = merge_signals


function get_sig(df, signals...)
    return hcat([concat_trials(df, sig) for sig in signals]...)
end
