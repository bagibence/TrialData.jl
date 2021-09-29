function get_movement_onset(s::AbstractVector, min_ds=1.9, s_thresh=10, peak_divisor=2)
    # I'm not sure what this is
    abs_acc_thresh = NaN

    # initialize to nan
    on_idx = NaN

    # first and second derivatives of the speed
    ds = [0; diff(s)]
    dds = [0; diff(ds)]
    # peaks of the first are where the second derivative changes sign
    peaks = [(dds[1:end-1] .> 0) .& (dds[2:end] .< 0); false]
    # acceleration has to be over the minimum 
    # and take just the first peak
    mvt_peak = findfirst(peaks .& (ds .> min_ds))

    # if there are peaks
    if !isnothing(mvt_peak)
        if isnan(abs_acc_thresh)
            # Threshold is max of acceleration peak divided by divisor
            thresh = ds[mvt_peak] / peak_divisor
        else
            thresh = abs_acc_thresh
        end
        # initiation is the last time point where ds is below threshold before the peak
        on_idx = findlast((ds .< thresh) .& ((1:length(ds)) .< mvt_peak))
    end

    # if peak finding didn't work, try thresholding
    if isempty(on_idx) || isnan(on_idx)
        on_idx = findfirst((s .> s_thresh))
        if isnothing(on_idx) # usually means it never crosses threshold
            @warn "Could not identify movement onset"
            on_idx = NaN
        end
    end

    return on_idx
end

function get_peak(s)
    peak_idx = argmax(s)
end

function get_movement_onset(trial, exec_idx)
    s = [norm(veli) for veli in eachrow(trial.vel[exec_idx, :])];
    rel_on_idx = get_movement_onset(s)
    
    return exec_idx[1] + rel_on_idx - 1
end

function get_movement_onset(trial; kwargs...)
    return get_movement_onset(trial.vel_norm[trial.idx_go_cue:end]; kwargs...) + trial.idx_go_cue
end

function add_movement_onset(df; kwargs...)
    outdf = deepcopy(df)

    outdf[!, :idx_movement_on] = [get_movement_onset(trial; kwargs...) for trial in eachrow(outdf)]

    return outdf
end


function get_movement_peak(trial, exec_idx)
    s = [norm(veli) for veli in eachrow(trial.vel[exec_idx, :])];
    rel_peak_idx = get_peak(s)
    
    return exec_idx[1] + rel_peak_idx - 1
end


function get_movement_onsets(trial, exec_indices)
    return [get_movement_onset(trial, idx) for idx in exec_indices]
end

function get_movement_peaks(trial, exec_indices)
    return [get_movement_peak(trial, idx) for idx in exec_indices]
end

