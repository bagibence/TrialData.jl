nanmean(x) = mean(filter(!isnan, x));
nanmean(x, dims) = mapslices(nanmean, x, dims=dims);

nanmedian(x) = median(filter(!isnan, x));
nanmedian(x, dims) = mapslices(nanmedian, x, dims=dims);

nanmax(x) = maximum(filter(!isnan, x));
nanmax(x, dims) = mapslices(nanmax, x, dims=dims);

nanmin(x) = minimum(filter(!isnan, x))
nanmin(x, dims) = mapslices(nanmin, x, dims=dims);

