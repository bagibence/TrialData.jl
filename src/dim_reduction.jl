"""
    dim_reduce(df::AbstractDataFrame, model::PyObject, signal, outsignal)

Fit `model` to `signal` in `df` and store the projections in the `outsignal` field in `df`.
"""
function dim_reduce(df::AbstractDataFrame, model::PyObject, signal, outsignal)
    outdf = deepcopy(df)

    model = model.fit(concat_trials(outdf, signal))
    outdf[!, outsignal] = [model.transform(arr) for arr in outdf[:, signal]]

    return outdf
end


