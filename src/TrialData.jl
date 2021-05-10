module TrialData

using Statistics
using DataFrames
using DataFramesMeta

using HDF5: h5open
using MAT: matopen

using PyCall: pyimport
pd = pyimport("pandas");

using DSP: gaussian, conv

using LinearAlgebra: norm

export
    mat2df,
    hdf2df,
    to_pandas,
    to_int,
    clean_idx_fields,

    norm_gauss_window,
    smooth_spikes,
    smooth_signals!,
    
    concat_trials,
    get_sig_by_trial,
    merge_signals,
    merge_fields,
    get_sig,

    select_trials,
    @select_trials,
    rename_fields,
    subtract_cross_condition_mean,
    trial_average,

    center,
    z_score,
    center_normalize,
    zero_normalize,
    soft_normalize,
    sqrt_transform,

    time_varying_fields,
    restrict_to_interval,

    get_average_firing_rates,
    remove_low_firing_neurons,

    add_norm!,
    add_norm,

    nanmin,
    nanmax,
    nanmean,
    nanmedian


include("constants.jl")
include("io.jl")
include("smoothing.jl")
include("querying.jl")
include("data_transformations.jl")
include("time.jl")
include("firing_rates.jl")
include("signals.jl")
include("nanfunctions.jl")

end # module
