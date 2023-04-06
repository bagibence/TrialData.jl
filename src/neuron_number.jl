"""
$(SIGNATURES)

Sample `n_neurons` neurons from `signal` and write it to `out_signal` in `df`.
"""
function subsample_neurons!(df::AbstractDataFrame, signal::T, n_neurons::Int, out_signal::T) where T <: Union{String, Symbol}
    sampled_ind = rand(1:signal_dimensionality(df, signal), n_neurons)

    @transform!(df, out_signal = {signal}[:, sampled_ind]);

    return df
end

function subsample_neurons!(df::AbstractDataFrame, signal::T, n_neurons::Int) where T <: Union{String, Symbol}
    return subsample_neurons!(df, signal, n_neurons, signal)
end

"""
$(SIGNATURES)

Sample `n_neurons` neurons from `signal` and write into `out_signal`, operating on a copy of `df`.
"""
function subsample_neurons(df::AbstractDataFrame, signal::T, n_neurons::Int, out_signal::T) where T <: Union{String, Symbol}
    copy_df = deepcopy(df)
    return subsample_neurons!(copy_df, signal, n_neurons, out_signal)
end

function subsample_neurons(df::AbstractDataFrame, signal::T, n_neurons::Int) where T <: Union{String, Symbol}
    return subsample_neurons(df, signal, n_neurons, signal)
end

"""
$(SIGNATURES)

Match the number of neurons across signals.
"""
function match_number_of_neurons!(df, max_n_neurons::Int, signals = (:PMd_spikes, :M1_spikes))
    n_to_sample = min((signal_dimensionality(df, signal) for signal in signals)..., max_n_neurons)

    for signal in signals
        subsample_neurons!(df, signal, n_to_sample)
    end

    return df
end

"""
$(SIGNATURES)

Match the number of neurons across `signals` and return a copy of `df`.
"""
function match_number_of_neurons(df, max_n_neurons::Int, signals = (:PMd_spikes, :M1_spikes))
    copy_df = deepcopy(df)
    return match_number_of_neurons!(copy_df, max_n_neurons, signals)
end
