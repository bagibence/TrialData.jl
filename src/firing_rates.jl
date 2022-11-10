"""
    _divide_by_bin_size(signal)

Infer if we have to divide by the bin size or not.
For spikes we have to divide by the bin size, but for firing rates that is usually already done.
"""
function _divide_by_bin_size(signal)
    if endswith(String(signal), "spikes")
        @warn "Assuming spikes are actually spikes and dividing by bin size."
        return true
    elseif endswith(String(signal), "rates")
        @warn "Assuming rates are already in Hz and don't have to divide by bin size."
        return false
    else
        throw(ArgumentError("Please specify divide_by_bin_size. Could not determine it automatically."))
    end
end

"""
    get_average_firing_rates(df, signal[, divide_by_bin_size])

Get a vector of average firing rates per neuron in the `signal` field of `df`.

`divide_by_bin_size` is ideally inferred from the name of the signal.
For spikes we have to divide by the bin size, but for firing rates that is usually already done.
The value of the bin size is read from the `bin_size` field of `df`.
See also [`_divide_by_bin_size`](@ref)
"""
function get_average_firing_rates(df, signal)
    divide_by_bin_size = _divide_by_bin_size(signal)

    return get_average_firing_rates(df, signal, divide_by_bin_size)
end

function get_average_firing_rates(df, signal, divide_by_bin_size)
    @assert length(unique(df.bin_size)) == 1

    if divide_by_bin_size
        return vec(mean(concat_trials(df, signal), dims=1) / df.bin_size[1])
    else
        return vec(mean(concat_trials(df, signal), dims=1))
    end
end



"""
    _spikes_and_rates_fields(df, signal)

Find the "spikes" / "rates" counterpart of `signal` in `df`.

# Examples
`_spikes_and_rates_fields(df, :PMd_spikes)`

gives

`[:PMd_spikes, :PMd_rates]` if `:PMd_rates` is in `df`
`[:PMd_spikes]` and a warning otherwise
"""
function _spikes_and_rates_fields(df, signal)
    ssignal = String(signal)
    if endswith(ssignal, "spikes")
        sother = replace(ssignal, "spikes" => "rates")
    elseif endswith(ssignal, "rates")
        sother = replace(ssignal, "rates" => "spikes")
    else
        @warn "Could not find spikes/rates counterpart of $(ssignal)"
        return [ssignal]
    end

    if sother in names(df)
        return [ssignal, sother]
    else
        return [ssignal]
    end
end


"""
    remove_low_firing_neurons(df, signal, threshold[, divide_by_bin_size])

Remove neurons from `signal` whose average firing rate is below `threshold`.
"""
function remove_low_firing_neurons(df, signal, threshold, divide_by_bin_size)
    out_df = deepcopy(df)

    av_rates = get_average_firing_rates(df, signal, divide_by_bin_size)
    mask = av_rates .> threshold

    for sig in _spikes_and_rates_fields(out_df, signal)
        out_df[!, sig] = [arr[:, mask] for arr in df[!, sig]]
    end

    return out_df
 end

 function remove_low_firing_neurons(df, signal, threshold)
    divide_by_bin_size = _divide_by_bin_size(signal)

    return remove_low_firing_neurons(df, signal, threshold, divide_by_bin_size)
end


"""
    _add_rates!(df, spike_fields, rate_fields, f)

Apply `f` to every element in `spike_fields` and save it in `rate_fields`.
"""
function _add_rates!(df, spike_fields, rate_fields, f)
    for (spike_col, rate_col) in zip(spike_fields, rate_fields)
        df[!, rate_col] = [f(arr) for arr in df[!, spike_col]]
    end

    return df
end

"""
    add_firing_rates(df, method; win=nothing, hw=nothing, std=nothing)

Add firing rates calculated from spikes using the chosen method to the dataframe.

# Arguments
#
- `df::DataFrame`: dataframe in TrialData format
- `method::Symbol`: `:bin` or `:smooth`. If smooth and none of win, hw, and std are given,
a Gaussian kernel with the default smoothing half-width defined in `globals.DEFAULT_HW` is used.
- `win::Vector`: smoothing window to use.
- `hw::Integer`: half-width of the Gaussian smoothing kernel in ms.
- `std::Integer`: standard deviation of the Gaussian smoothing kernel.
"""
function add_firing_rates(df, method; win=nothing, hw=nothing, std=nothing)
    out_df = deepcopy(df)

    spike_fields = [col for col in names(out_df) if endswith(col, "spikes")]
    rate_fields = [replace(col, "spikes" => "rates") for col in spike_fields]

    bin_size = out_df.bin_size[1]

    if method == :bin
        out_df = _add_rates!(out_df, spike_fields, rate_fields,
                             arr -> (arr ./ bin_size))
    elseif method == :smooth
        if win !== nothing
            @assert (hw === nothing) && (std === nothing)
        elseif std !== nothing
            @assert hw === nothing
            win = norm_gauss_window(bin_size, std)
        elseif hw !== nothing
            win = norm_gauss_window(bin_size; hw=hw)
        else
            win = norm_gauss_window(bin_size)
        end

        out_df = _add_rates!(out_df, spike_fields, rate_fields,
                             arr -> smooth_spikes(arr, win) ./ bin_size)

    else
        throw(ArgumentError("method has to be :bin or :smooth"))
    end

    return out_df
end


"""
$(SIGNATURES)

Match firing rate distributions between two signals and save
the subsampled populations in `out_signals`.
"""
function match_firing_rate_distributions!(df, signals, out_signals = signals)
    @assert length(signals) == 2
    @assert length(out_signals) == 2
    signal_a, signal_b = signals
    out_signal_a, out_signal_b = out_signals

    area_a_av_rates = get_average_firing_rates(df, signal_a);
    area_b_av_rates = get_average_firing_rates(df, signal_b);

    area_b_upper_bound = percentile(area_b_av_rates, 95)
    area_a_upper_bound = percentile(area_a_av_rates, 95)

    upper_bound = ceil(max(area_b_upper_bound, area_a_upper_bound))

    fr_bins = 0:1:upper_bound;

    sampled_area_a_indices = []
    sampled_area_b_indices = []
    for (start, stop) in zip(fr_bins[1:end-1], fr_bins[2:end])
        area_a_indices = findall(start .< area_a_av_rates .< stop)
        area_b_indices = findall(start .< area_b_av_rates .< stop)
        
        n_to_sample = min(length(area_a_indices), length(area_b_indices))
        
        if n_to_sample > 0
            push!(sampled_area_a_indices, sample(area_a_indices, n_to_sample, replace = false))
            push!(sampled_area_b_indices, sample(area_b_indices, n_to_sample, replace = false))
        end
    end

    sampled_area_a_indices = sort(reduce(vcat, sampled_area_a_indices));
    sampled_area_b_indices = sort(reduce(vcat, sampled_area_b_indices));

    @transform!(df, {out_signal_a} = {signal_a}[:, sampled_area_a_indices]);
    @transform!(df, {out_signal_b} = {signal_b}[:, sampled_area_b_indices]);

    return df
end
