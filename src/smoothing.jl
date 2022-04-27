"""
    norm_gauss_window(bin_length, std)

Gaussian window with mass normalized to 1
"""
function norm_gauss_window(bin_length, std)
    n = Int(round(5 * std / bin_length))
    win = gaussian(n, std / bin_length / n)
    return win ./ sum(win)
end

function norm_gauss_window(bin_length; hw=DEFAULT_HW)
    return norm_gauss_window(bin_length, hw_to_std(hw))
end


"""
    hw_to_std(hw)

Convert half-width to standard deviation for a Gaussian window.
"""
function hw_to_std(hw)
    return hw / (2 * sqrt(2 * log(2)))
end


"""
    smooth_spikes(neuron_spikes, win)
    smooth_spikes(pop_spikes, win)
    smooth_spikes(neuron_spikes, bin_size, hw)
    smooth_spikes(pop_spikes, bin_size, hw)

Smooth spikes of a single neuron with the given smoothing window win.
"""
function smooth_spikes(neuron_spikes::AbstractVector, win::AbstractVector)
    hw = floor(length(win) / 2) |> Int
    return conv(neuron_spikes, win)[hw+1:end-hw]
end

function smooth_spikes(neuron_spikes::AbstractVector, bin_size, hw=DEFAULT_HW)
    win = norm_gauss_window(bin_size; hw=hw)
    return smooth_spikes(neuron_spikes, win)
end

function smooth_spikes(pop_spikes::AbstractMatrix, win::AbstractVector)
    hw = floor(length(win) / 2) |> Int
    return conv(pop_spikes, win)[hw+1:end-hw, :]
end

function smooth_spikes(pop_spikes::AbstractMatrix, bin_size, hw=DEFAULT_HW)
    win = norm_gauss_window(bin_size; hw=hw)
    return smooth_spikes(pop_spikes, win)
end


"""
    smooth_signals(df, sig::T, win::AbstractVector) where T <: Union{String, Symbol}

    smooth_signals(df, signals, win::AbstractVector)
    smooth_signals(df, signals, hw::Number=DEFAULT_HW)
"""
function smooth_signals(df, sig::T, win::AbstractVector) where T <: Union{String, Symbol}
    outdf = deepcopy(df)

    outdf[!, sig] = [smooth_spikes(arr, win) for arr in outdf[!, sig]]

    return outdf
end

function smooth_signals(df, signals, win::AbstractVector)
    outdf = deepcopy(df)

    for sig in signals
        outdf[!, sig] = [smooth_spikes(arr, win) for arr in outdf[!, sig]]
    end

    return outdf
end

function smooth_signals(df, signals, hw::Number=DEFAULT_HW)
    bin_size = df.bin_size[1]
    win = norm_gauss_window(bin_size; hw=hw)

    return smooth_signals(df, signals, win)
end


"""
    moving_average(vs, n)

Calculate a moving average of vector vs with a window of n elements
"""
function moving_average(vs::AbstractVector, n)
    return [mean(@view vs[i:(i+n-1)]) for i in 1:(length(vs)-(n-1))]
end

function moving_average(sig::AbstractMatrix, n; dims=1)
    return mapslices(v -> moving_average(v, n), sig; dims = dims)
end
