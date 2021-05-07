interval_around_index(idx, before, after) = idx-before:idx+after

intervals_around_indices(indices, before, after) = [interval_around_index(idx, before, after) for idx in indices]

interval_around_point(trial, point_name, before, after) = interval_around_index(trial[point_name], before, after)

intervals_around_points(trial, point_name, before, after) = intervals_around_indices(trial[point_name], before, after)


function _ref_time_field(df)
    return [col for col in names(df) if endswith(col, "spikes") | endswith(col, "rates")][1]
end

function trial_length(trial, ref_field)
    return size(trial[ref_field], 1)
end

function trial_length(trial)
    return trial_length(trial, _ref_time_field(trial))
end


function time_varying_fields(df, ref_field)
    first_trial = first(df)
    T = trial_length(first_trial, ref_field)
    
    time_fields = []
    for col in names(first_trial)
        try
            if trial_length(first_trial, col) == T
                push!(time_fields, col)
            end
        catch
        end
    end
    
    for trial in eachrow(df)
        ref_T = trial_length(trial, ref_field)
        for col in time_fields
            @assert trial_length(trial, col) == ref_T
        end
    end
    
    return time_fields
end


function time_varying_fields(df)
    ref_field = _ref_time_field(df)

    return time_varying_fields(df, ref_field)
end



function _interval_in_trial(trial, interval, ref_field)
    T = trial_length(trial, ref_field)
    
    return !(interval.start < 1 || interval.stop > T)
end

function _interval_in_trial(trial, epoch_fun::Function, ref_field)
    interval = epoch_fun(trial)

    return _interval_in_trial(trial, interval, ref_field)
end


function restrict_to_epoch(df, fieldname::T, epoch_fun::Function) where T <: Union{AbstractString, Symbol}
    return [trial[fieldname][epoch_fun(trial), :] for trial in eachrow(df)]
end

function restrict_to_epoch(df, fieldname::T, epoch) where T <: Union{AbstractString, Symbol}
    return [trial[fieldname][epoch, :] for trial in eachrow(df)]
end


_epoch_start(trial, epoch_fun::Function) = epoch_fun(trial).start
_epoch_start(trial, epoch) = epoch.start

function restrict_to_interval(df, epoch, ref_field)
    out_df = select_trials(df, trial -> _interval_in_trial(trial, epoch, ref_field))

    dropped_ids = Int.(setdiff(df.trial_id, out_df.trial_id))
    if !isempty(dropped_ids)
        @warn "Dropped the trials with the following IDs: $(dropped_ids)"
    end

    for col in time_varying_fields(out_df, ref_field)
        out_df[!, col] = restrict_to_epoch(out_df, col, epoch)
    end

    idx_fields = [col for col in names(out_df) if startswith(col, "idx")]

    # convert every index column to allow inserting a missing value
    for col in idx_fields
        dtypes = typeof.(df[!, col])
        dtypes = [t for t in dtypes if t != Missing]
        if length(dtypes) == 1
            df[!, col] = convert(Array{Union{Missing, dtypes[1]}}, df[!, col])
        end
    end

    for trial in eachrow(out_df)
        t0 = _epoch_start(trial, epoch)
        T = trial_length(trial, ref_field)

        for col in idx_fields
            trial[col] -= t0

            if ismissing(trial[col]) | (trial[col] < 1) | (trial[col] > T)
                trial[col] = missing
            end
        end
    end

    # convert columns without missing values back to their true type
    clean_types!(out_df)
    
    return out_df
end


function restrict_to_interval(df, epoch)
    ref_field = _ref_time_field(df)
    return restrict_to_interval(df, epoch, ref_field)
end
