function fit(df::AbstractDataFrame, model::PyObject, signal)
    return model.fit(concat_trials(df, signal))
end


function dim_reduce(df::AbstractDataFrame, model::PyObject, signal, outsignal)
    outdf = copy(df)

    model = fit(outdf, model, signal)
    outdf[!, outsignal] = [model.transform(arr) for arr in outdf[!, signal]]

    return outdf
end


