using Interpolations: LinearInterpolation


"""
    match_histograms(array_list, n_bins)

Subsample the elements of the arrays in `array_list` such that the histograms
of the values in the subsampled arrays is matched across arrays.
`n_bins` sets how many bins the resulting histogram has.

Return a list of indices that can be used to select the sampled elements, and the
generated bins of the matched histogram.
"""
function match_histograms(array_list, n_bins)
    n_arrays = length(array_list)

    mini = minimum(minimum.(array_list))
    maxi = maximum(maximum.(array_list))
    bins = range(mini, maxi, length = n_bins)

    which_bin_per_array = [searchsortedlast.(Ref(bins), arr) for arr in array_list];
    linear_indices_per_array = [1:length(bin_ind_i) for bin_ind_i in which_bin_per_array]

    sampled_bin_indices = [Int64[] for i in 1:n_arrays]

    for i in 1:n_bins
        n_sample = minimum(count.(==(i), which_bin_per_array))
        indices_in_current_bin_per_array = [lin_ind[bin_ind .== i]
                                            for (lin_ind, bin_ind)
                                            in zip(linear_indices_per_array, which_bin_per_array)]

        for j in 1:n_arrays
            push!(sampled_bin_indices[j],
                  sample(indices_in_current_bin_per_array[j], n_sample, replace=false)...)
        end
    end

    return sampled_bin_indices, bins
end


"""
    match_histograms(df::AbstractDataFrame, grouping_field, matching_field, n_bins)

Group `df` based on `grouping_field`, then subsample the rows of each group such that
the histograms of the values in `matching_field` is matched across groups, using `n_bins` bins.

Return a list of subdataframes and the bin edges used.
"""
function match_histograms(df::AbstractDataFrame, grouping_field, matching_field, n_bins)
    groups = groupby(df, grouping_field)
    sampled_indices, bins = match_histograms((subdf[!, matching_field] for subdf in groups),
                                             n_bins)
    return [subdf[si, :] for (subdf, si) in zip(groups, sampled_indices)], bins
end


"""
    digitize(arr, bins)

For each element in `arr`, tell which bin of `bins` it falls into.
Reproduces the functionality of numpy.digitize.
"""
function digitize(arr, bins)
    return searchsortedlast.(Ref(bins), arr)
end


"""
    histedges_equal_num(x, nbin)

Create histogram bin edges so that when binning `x`, the same number of values fall in all bins.

From https://stackoverflow.com/questions/39418380/histogram-with-equal-number-of-points-in-each-bin
"""
function histedges_equal_num(x, nbin)
    npt = length(x)
    interp = LinearInterpolation(0:npt-1, sort(x))

    return [interp(xi) for xi in range(0, npt-1, length = nbin+1)]
end

