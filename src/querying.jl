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


"""
    get_sig_by_trial(df, signal)

Get a 3D tensor containing `signal`'s values on each trial.
The result is of shape `time x signal_dimensionality x n_trials`.
"""
function get_sig_by_trial(df, signal)
    return cat(df[:, signal]..., dims=3)
end

"""
    merge_signals(df, signals, out_fieldname)

Merge multiple signals into one by stacking them horizontally and store it in `out_fieldname`.
"""
function merge_signals(df, signals, out_fieldname)
    out_df = deepcopy(df)

    out_df[!, out_fieldname] = [hcat(trial[signals]...) for trial in eachrow(df)]

    return out_df
end

merge_fields = merge_signals


"""
    get_sig(df, signals...)

Same as [`concat_trials`](@ref) but accepts multiple signal names,
and stacks them horizontally.
"""
function get_sig(df, signals...)
    return hcat([concat_trials(df, sig) for sig in signals]...)
end


function stack_trials(df, field)
    return hcat(df[:, field]...)'
end


"""
    stack_time_average(df, field)

Average field in time on each trial, then stack trials under each other,
giving an `n_trials x signal_dimensionality` matrix.
"""
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


"""
    keep_common_trials(df_a, df_b, join_field=:trial_id)

Keep only trials with ID that are found in both data sets

Parameters
----------
df_a : pd.DataFrame
    first data set in trial_data format
df_b : pd.DataFrame
    second data set in trial_data format
join_field : str, optional, default trial_id
    field based on which trials are matched to each other

Returns
-------
(subset_a, subset_b) : tuple of dataframes
"""
function keep_common_trials(df_a, df_b, join_field=:trial_id)
    common_ids = Set(intersect(df_a[:, join_field], df_b[:, join_field]))
    
    subset_a = @subset(df_a, {join_field} in common_ids);
    subset_b = @subset(df_b, {join_field} in common_ids);
    
    return subset_a, subset_b
end


"""
    sample(df::AbstractDataFrame, n; replace=false)

Sample `n` rows of a DataFrame
"""
function sample(df::AbstractDataFrame, n; replace=false)
    return df[sample(axes(df, 1), n; replace = replace, ordered = true), :]
end
