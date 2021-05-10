"""
    norm_gauss_window(bin_length, std)

Gaussian window with mass normalized to 1
"""
function norm_gauss_window(bin_length, std)
    n = Int(round(5 * std / bin_length))
    win = gaussian(n, std / bin_length / n)
    return win ./ sum(win)
end
norm_gauss_window(bin_length; std) = norm_gauss_window(bin_length, std)

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

Smooth spikes of a single neuron with the given smoothing window win.
"""
function smooth_spikes(neuron_spikes::AbstractVector, win::AbstractVector)
    hw = floor(length(win) / 2) |> Int
    return conv(neuron_spikes, win)[hw+1:end-hw]
end

"""
    smooth_spikes(neuron_spikes, bin_size; hw)

Smooth spikes of a single neuron with a Gaussian window of a given half-width.
"""
function smooth_spikes(neuron_spikes::AbstractVector, bin_size; hw=DEFAULT_HW)
    win = norm_gauss_window(bin_size; hw=hw)
    return smooth_spikes(neuron_spikes, win)
end

"""
    smooth_spikes(pop_spikes, win)

Smooth spikes of a population (time x neuron) with the given smoothing window win.
"""
function smooth_spikes(pop_spikes::AbstractMatrix, win::AbstractVector)
    return hcat((smooth_spikes(neuron_spikes, win) for neuron_spikes in eachcol(pop_spikes))...)
end

"""
    smooth_spikes(pop_spikes, bin_size; hw)

Smooth spikes of a population (time x neuron) with a Gaussian window of a given half-width.
"""
function smooth_spikes(pop_spikes::AbstractMatrix, bin_size; hw=DEFAULT_HW)
    win = norm_gauss_window(bin_size; hw=hw)
    return smooth_spikes(pop_spikes, win)
end


function smooth_signals!(df, sig::T, win::AbstractVector) where T <: Union{String, Symbol}
    outdf = copy(df)

    outdf[!, sig] = [smooth_spikes(arr, win) for arr in outdf[!, sig]]

    return outdf
end

function smooth_signals!(df, signals, win::AbstractVector)
    outdf = copy(df)

    for sig in signals
        outdf[!, sig] = [smooth_spikes(arr, win) for arr in outdf[!, sig]]
    end

    return outdf
end

function smooth_signals!(df, signals; hw::Number=DEFAULT_HW)
    bin_size = df.bin_size[1]
    win = norm_gauss_window(bin_size; hw=hw)

    return smooth_signals(df, signals, win)
end