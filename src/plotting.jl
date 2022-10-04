# plot nameddimsarray and keyedarray objects
import Plots.plot
function plot(arr::T; kwargs...) where T <: Union{NamedDimsArray, KeyedArray}
    to_xarray(arr).plot(; kwargs...)
end
