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

using DimensionalData: DimArray
using NamedDims: NamedDimsArray
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
    get_sig_at_time,
    group_by,
    expand_in_time,
    keep_common_trials,
    sample,
    balance_conditions,
    get_idx_fields,

    #select_trials,
    rename_fields,
    subtract_cross_condition_mean,
    trial_average,
    lendiff,

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
    get_trial_lengths,

    get_average_firing_rates,
    remove_low_firing_neurons,
    add_firing_rates,
    match_firing_rate_distributions!,

    add_norm!,
    add_norm,
    add_gradient,
    time_average,
    signal_dimensionality,
    signal_at_t,
    mean_signal_in_interval,

    nanmin,
    nanmax,
    nanmean,
    nanmedian,

    dim_reduce,

    match_histograms,
    digitize,
    histedges_equal_num,

    subsample_neurons!,
    subsample_neurons,
    match_number_of_neurons!,
    match_number_of_neurons,

    twonn_dimension,
    participation_ratio,

    get_movement_onset,
    get_movement_peak,
    add_movement_onset,

    get_classif_cv_scores_through_time,
    get_regr_cv_scores_through_time,
    get_predictive_axis_through_time,
    cross_val_score, KFold, StratifiedKFold,
    make_scorer, r2_score, accuracy_score, default_scorer,

    stretch,
    get_ordered_median_time_points,
    stretch_signal!,

    split,
    cummean,

    plot,

    combine_dataframes

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
include("neuron_number.jl")
include("dimensionality.jl")
include("movement_onset.jl")
include("decoding.jl")
include("stretching.jl")
include("array_utils.jl")
include("plotting.jl")
include("dataframe_transformations.jl")

end # module
