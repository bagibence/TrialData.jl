module TrialData

using DocStringExtensions

import StatsBase.sample
using StatsBase: percentile, countmap
using Statistics: mean, median, var, std
using DataFrames
using DataFrameMacros

using HDF5: h5open
using MAT: matopen

using PyCall: pyimport, PyObject, PyNULL

using DSP: gaussian, conv

using LinearAlgebra: norm

using DimensionalData
using NamedDims
using AxisKeys

using NearestNeighbors
using Distances: pairwise, Euclidean, CosineDist

include("scikit_imports.jl")

export
    mat2df,
    hdf2df,
    to_pandas,
    to_xarray,
    to_int,
    clean_idx_fields,

    norm_gauss_window,
    smooth_spikes,
    smooth_signals,
    moving_average,
    
    concat_trials,
    get_sig_by_trial,
    merge_signals,
    merge_fields,
    get_sig,
    stack_trials,
    stack_time_average,
    group_by,
    expand_in_time,
    keep_common_trials,
    sample,
    balance_conditions,

    #select_trials,
    rename_fields,
    subtract_cross_condition_mean,
    trial_average,

    transform_signal,
    center,
    z_score,
    center_normalize,
    zero_normalize,
    soft_normalize,
    sqrt_transform,

    time_varying_fields,
    restrict_to_interval,
    get_trial_length,

    get_average_firing_rates,
    remove_low_firing_neurons,
    add_firing_rates,

    add_norm!,
    add_norm,
    add_gradient,
    time_average,
    signal_dimensionality,
    signal_at_t,

    nanmin,
    nanmax,
    nanmean,
    nanmedian,

    dim_reduce,

    match_histograms,
    digitize,
    histedges_equal_num,

    twonn_dimension,

    get_movement_onset,
    get_movement_peak,
    add_movement_onset,

    get_classif_cv_scores_through_time,
    get_regr_cv_scores_through_time,
    get_predictive_axis_through_time,
    cross_val_score, KFold, StratifiedKFold,
    make_scorer, r2_score, accuracy_score, default_scorer,

    stretch,

    split

include("constants.jl")
include("io.jl")
include("smoothing.jl")
include("querying.jl")
include("data_transformations.jl")
include("time.jl")
include("firing_rates.jl")
include("signals.jl")
include("nanfunctions.jl")
include("dim_reduction.jl")
include("match_histograms.jl")
include("dimensionality.jl")
include("movement_onset.jl")
include("decoding.jl")
include("stretching.jl")
include("array_utils.jl")

end # module
