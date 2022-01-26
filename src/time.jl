interval_around_index(idx, before, after) = idx-before:idx+after

intervals_around_indices(indices, before, after) = [interval_around_index(idx, before, after) for idx in indices]

interval_around_point(trial, point_name, before, after) = interval_around_index(trial[point_name], before, after)

intervals_around_points(trial, point_name, before, after) = intervals_around_indices(trial[point_name], before, after)


function _ref_time_field(trial_or_df)
    return first([col for col in names(trial_or_df) if endswith(col, "spikes") || endswith(col, "rates")])
end

function get_trial_length(trial_or_df)
    return get_trial_length(trial_or_df, _ref_time_field(trial_or_df))
end

function get_trial_length(trial::DataFrameRow, ref_field)
    return size(trial[ref_field], 1)
end

function get_trial_length(df::AbstractDataFrame, ref_field)
    trial_lengths = [get_trial_length(trial, ref_field) for trial in eachrow(df)]
    
    @assert length(unique(trial_lengths)) == 1
    
    return trial_lengths[1]
end

function time_varying_fields(trial::DataFrameRow, ref_field)
    T = get_trial_length(trial, ref_field)

    time_fields = []
    for col in names(trial)
        try
            if get_trial_length(trial, col) == T
                push!(time_fields, col)
            end
        catch
        end
    end

    return time_fields
end

function time_varying_fields(df, ref_field)
    time_fields = time_varying_fields(first(df))

    for trial in eachrow(df)
        ref_T = get_trial_length(trial, ref_field)
        for col in time_fields
            @assert get_trial_length(trial, col) == ref_T
        end
    end
    
    return time_fields
end


function time_varying_fields(df)
    ref_field = _ref_time_field(df)

    return time_varying_fields(df, ref_field)
end



function _interval_in_trial(trial, interval, ref_field)
    T = get_trial_length(trial, ref_field)
    
    return !(interval.start < 1 || interval.stop > T)
end

function _interval_in_trial(trial, epoch_fun::Function, ref_field)
    interval = try
        epoch_fun(trial)
    catch err
        # this is thrown if the index we're trying to use is missing
        if isa(err, InexactError)
            # in that case the interval is not in the trial
            return false
        # if something else happened, we don't want to just silently continue
        else
            rethrow()
        end
    end

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

# I don't know how much sense this makes
function restrict_to_interval(trial::DataFrameRow, epoch, ref_field)
    return first(restrict_to_interval(DataFrame(trial), epoch, ref_field))
end

function _validate_time_point(tp::Integer, T)
    if ismissing(tp) | (tp < 1) | (tp > T)
        return missing
    else
        return tp
    end
end

function _validate_time_point(time_points::AbstractArray, T)
    return [_validate_time_point(tp, T) for tp in time_points]
end


function restrict_to_interval(df, epoch, ref_field)
    out_df = deepcopy(df)
    out_df = filter(trial -> _interval_in_trial(trial, epoch, ref_field), out_df)

    dropped_ids = Int.(setdiff(df.trial_id, out_df.trial_id))
    if !isempty(dropped_ids)
        @warn "Dropped the trials with the following IDs: $(dropped_ids)"
    end

    for col in time_varying_fields(out_df, ref_field)
        out_df[!, col] = restrict_to_epoch(out_df, col, epoch)
    end

    idx_fields = [col for col in names(out_df) if startswith(col, "idx")]

    # convert every index column to allow inserting a missing value
    allowmissing!(out_df)

    for trial in eachrow(out_df)
        t0 = _epoch_start(trial, epoch) - 1
        T = get_trial_length(trial, ref_field)

        for col in idx_fields
            if typeof(trial[col]) <: Vector
                trial[col] .-= t0
            else
                trial[col] -= t0
            end

            trial[col] = _validate_time_point(trial[col], T)
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
