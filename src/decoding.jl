# this has to be done this way instead of @sk_import because otherwise it throws a segfault
# https://github.com/JuliaPy/PyCall.jl/blob/master/README.md#using-pycall-from-julia-modules
# https://github.com/cstjean/ScikitLearn.jl/issues/50
const model_selection = PyNULL()
const sk_metrics = PyNULL()
const default_scorer = PyNULL()

function __init__()
    copy!(model_selection, pyimport("sklearn.model_selection"))
    copy!(sk_metrics, pyimport("sklearn.metrics"))
    copy!(default_scorer, sk_metrics.make_scorer(sk_metrics.r2_score, multioutput = "variance_weighted"))
end



function get_classif_cv_scores_through_time(df, classifier, input_field, out_field, cv = 10; n_jobs = 1)

    X_per_trial = permutedims(get_sig_by_trial(df, input_field), (3, 2, 1))
    y = df[!, out_field]
    
    T = size(X_per_trial, 3);
    
    cv_scores = []
    for t in 1:T
        push!(cv_scores, model_selection.cross_val_score(classifier, X_per_trial[:, :, t], y, cv = model_selection.StratifiedKFold(cv, shuffle=true), n_jobs = n_jobs))
    end
    
    return hcat(cv_scores...)
end


function get_regr_cv_scores_through_time(df, regressor, input_field, out_field, cv = 10; n_jobs=1, scoring=sk_metrics.make_scorer(sk_metrics.r2_score, multioutput = "variance_weighted"))

    X_per_trial = permutedims(get_sig_by_trial(df, input_field), (3, 2, 1))
    y = df[!, out_field]
    
    T = size(X_per_trial, 3);
    
    cv_scores = []
    for t in 1:T
        push!(cv_scores, model_selection.cross_val_score(regressor, X_per_trial[:, :, t], y, cv = model_selection.KFold(cv, shuffle=true), scoring = scoring, n_jobs = n_jobs))
    end

    
    return hcat(cv_scores...)
end


function get_predictive_axis_through_time(df, predictor, input_field, out_field)
    X_per_trial = permutedims(get_sig_by_trial(df, input_field), (3, 2, 1))
    y = df[!, out_field]
    
    T = size(X_per_trial, 3);
    
    coefficients = []
    for t in 1:T
        push!(coefficients, predictor.fit(X_per_trial[:, :, t], y).coef_)
    end

    return coefficients
end
