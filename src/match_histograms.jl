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


function match_histograms(df::AbstractDataFrame, grouping_field, matching_field, n_bins)
    groups = groupby(df, grouping_field)
    sampled_indices, bins = match_histograms((subdf[!, matching_field] for subdf in groups),
                                             n_bins)
    return [subdf[si, :] for (subdf, si) in zip(groups, sampled_indices)], bins
end

function digitize(arr, bins)
    return searchsortedlast.(Ref(bins), arr)
end


using Interpolations: LinearInterpolation
# from https://stackoverflow.com/questions/39418380/histogram-with-equal-number-of-points-in-each-bin
function histedges_equal_num(x, nbin)
    npt = length(x)
    interp = LinearInterpolation(0:npt-1, sort(x))

    return [interp(xi) for xi in range(0, npt-1, length = nbin+1)]
end

