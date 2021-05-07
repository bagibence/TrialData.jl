function get_average_firing_rates(df, signal, divide_by_bin_size)
    @assert length(unique(df.bin_size)) == 1

    if divide_by_bin_size
        return mean(concat_trials(df, signal), dims=1) / df.bin_size[1]
    else
        return mean(concat_trials(df, signal), dims=1)
    end
end


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

function get_average_firing_rates(df, signal)
    divide_by_bin_size = _divide_by_bin_size(signal)

    return get_average_firing_rates(df, signal, divide_by_bin_size)
end


function remove_low_firing_neurons(df, signal, threshold, divide_by_bin_size)
    out_df = copy(df)

    av_rates = get_average_firing_rates(df, signal, divide_by_bin_size)
    mask = vec(av_rates .> threshold)

    out_df[!, signal] = [arr[:, mask] for arr in df[!, signal]]

    return out_df
 end

 function remove_low_firing_neurons(df, signal, threshold)
    divide_by_bin_size = _divide_by_bin_size(signal)

    return remove_low_firing_neurons(df, signal, threshold, divide_by_bin_size)
end


function _add_rates!(df, spike_fields, rate_fields, bin_size, f)
    for (spike_col, rate_col) in zip(spike_fields, rate_fields)
        df[!, rate_col] = [f(arr) for arr in df[!, spike_col]]
    end

    return df
end

function add_firing_rates(df, method; win=nothing, hw=nothing, std=nothing)
    out_df = copy(df)

    spike_fields = [col for col in names(out_df) if endswith(col, "spikes")]
    rate_fields = [replace(col, "spikes" => "rates") for col in spike_fields]

    bin_size = out_df.bin_size[1]

    if method == :bin
        out_df = _add_rates!(out_df, spike_fields, rate_fields, bin_size,
                             arr -> (arr./ bin_size))
    elseif method == :smooth
            win = norm_gaussian_window(bin_size; hw)

        out_df = _add_rates!(out_df, spike_fields, rate_fields, bin_size,
                             arr -> smooth_spikes(arr, win))

    else
        throw(ArgumentError("method has to be :bin or :smooth"))
    end

    return out_df
end
