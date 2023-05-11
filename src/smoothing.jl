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

Smooth spikes of a single neuron or a population of neurons with the given smoothing window `.win`.
The output is the same length as the input, similarly to numpy's mode='same' setting.
"""
function smooth_spikes(neuron_spikes::AbstractVector, win::AbstractVector)
    # copied from https://github.com/JuliaDSP/DSP.jl/pull/403/files/0584fbde6ec0e9a87601a27bc67e5cd454432411#diff-5abb42008ccc969a9672dee0fc50fc9a3ad75f93d843e83a1535993107d6e387R765
    su = length(neuron_spikes)
    sv = length(win)
    start_ind = Int(floor(sv/2 + 1))
    last_ind = Int(floor(sv/2) + su)

    return conv(neuron_spikes, win)[start_ind:last_ind]
end

function smooth_spikes(neuron_spikes::AbstractVector, bin_size, hw=DEFAULT_HW)
    win = norm_gauss_window(bin_size; hw=hw)
    return smooth_spikes(neuron_spikes, win)
end

function smooth_spikes(pop_spikes::AbstractMatrix, win::AbstractVector)
    # copied from https://github.com/JuliaDSP/DSP.jl/pull/403/files/0584fbde6ec0e9a87601a27bc67e5cd454432411#diff-5abb42008ccc969a9672dee0fc50fc9a3ad75f93d843e83a1535993107d6e387R765
    su = size(pop_spikes, 1)
    sv = length(win)
    start_ind = Int(floor(sv/2 + 1))
    last_ind = Int(floor(sv/2) + su)

    return conv(pop_spikes, win)[start_ind:last_ind, :]
end

function smooth_spikes(pop_spikes::AbstractMatrix, bin_size, hw=DEFAULT_HW)
    win = norm_gauss_window(bin_size; hw=hw)
    return smooth_spikes(pop_spikes, win)
end


"""
    smooth_signals(df, signals, win::AbstractVector)

Smooth the values of `signals` in `df` with the smoothing window `win`.
"""
function smooth_signals(df, signals, win::AbstractVector)
    outdf = deepcopy(df)

    for sig in signals
        outdf[!, sig] = [smooth_spikes(arr, win) for arr in outdf[!, sig]]
    end

    return outdf
end

function smooth_signals(df, sig::T, win::AbstractVector) where T <: Union{String, Symbol}
    return smooth_signals(df, [sig], win)
end

"""
    smooth_signals(df, signals, hw::Number=DEFAULT_HW)

Smooth the values of `signals` in `df` with a Gaussian window with a half-width of `hw`.
"""
function smooth_signals(df, signals, hw::Number=DEFAULT_HW)
    bin_size = df.bin_size[1]
    win = norm_gauss_window(bin_size; hw=hw)

    return smooth_signals(df, signals, win)
end



"""
    moving_average(vs, n)

Calculate a moving average of vector `vs` with a window of `n` elements
"""
function moving_average(vs::AbstractVector, n)
    return [mean(@view vs[i:(i+n-1)]) for i in 1:(length(vs)-(n-1))]
end

"""
    moving_average(sig::AbstractMatrix, n; dims=1)

Calculate a moving average of the vectors in the matrix `sig` with a window of `n` elements,
along the dimension given by `dims`.
"""
function moving_average(sig::AbstractMatrix, n; dims=1)
    return mapslices(v -> moving_average(v, n), sig; dims = dims)
end
