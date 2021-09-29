function select_trials(df, query::Function)
    return filter(query, df)
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
    out_df = deepcopy(df)

    out_df[!, out_fieldname] = [hcat(trial[signals]...) for trial in eachrow(df)]

    return out_df
end

merge_fields = merge_signals


function get_sig(df, signals...)
    return hcat([concat_trials(df, sig) for sig in signals]...)
end


function stack_trials(df, field)
    return hcat(df[:, field]...)'
end


function stack_time_average(df, field)
    return vcat([mean(arr, dims=1) for arr in df[:, field]]...)
end
