#function select_trials(df, query::Function)
#    return filter(query, df)
#end


#function select_trials(df, indices::AbstractVector)
#    return df[indices, :]
#end


"""
    concat_trials(df, fieldname)

Concatenate the given field of every trial from the dataframe
(Assumes that time is the first axis.)
"""
function concat_trials(df, fieldname)#::Array{Float64, 2}
    return vcat(df[:, fieldname]...)
end


function get_sig_by_trial(df, signal)
    return cat(df[:, signal]..., dims=3)
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


"""
    expand_in_time(df, field)

"Expand in time" and concatenate a scalar way in a way that the resulting array has the same
number of time points as if we concatenated a time-varying signal from the same trials.
Useful for regressing onto a scalar field at every timepoint.
"""
function expand_in_time(df, field)
    subarrays = []
    
    for trial in eachrow(df)
        T = get_trial_length(trial)

        if isa(trial[field], Vector)
            push!(subarrays, repeat(transpose(trial[field]), T))
        else
            push!(subarrays, fill(trial[field], T))
        end
    end

    return vcat(subarrays...)
end


"""
    group_by(df, field)

Pandas-style groupby

**Example**:
```julia
for (ck, ckdf) in group_by(df, :cue_kappa)
    println(ck)
    # operate on ckdf which is type DataFrame
end
```
"""
function group_by(df, field)
    groups = groupby(df, field)
    key_tuples = values.(keys(groups))
    return zip([length(k) == 1 ? k[1] : k for k in values.(keys(groups))], [DataFrame(g) for g in groups])
end


"""
    get_idx_fields(df)

Get dataframe fields that start with "idx" as symbols
"""
function get_idx_fields(df)
    return [Symbol(col) for col in names(df) if startswith(string(col), "idx")]
end;
