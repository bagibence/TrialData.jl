"""
$(SIGNATURES)

Get the cross-validation scores through time, trying to classify `out_field` from `input_field` using `classifier`.

# Extra arguments
- `cv::Integer=10`: number of cross-validation folds
- `n_jobs::Integer=1`: number of CPU cores to use
- `cum_av::Bool=false`: use cumulative average of the signal
"""
function get_classif_cv_scores_through_time(df, classifier, input_field, out_field, cv = 10; n_jobs = 1, cum_av = false)
    X_per_trial = permutedims(get_sig_by_trial(df, input_field), (3, 2, 1))
    y = df[!, out_field]
    
    T = size(X_per_trial, 3);
    
    cv_scores = []
    for t in 1:T
        if cum_av
          x = dropdims(mean(X_per_trial[:, :, 1:t],
                            dims = 3),
                       dims = 3)
        else
          x = X_per_trial[:, :, t]
        end
        push!(cv_scores, model_selection.cross_val_score(classifier, x, y, cv = model_selection.StratifiedKFold(cv, shuffle=true), n_jobs = n_jobs))
    end
    
    return hcat(cv_scores...)
end


"""
$(SIGNATURES)

Get the cross-validation scores through time, trying to regress onto `out_field` from `input_field` using `regressor`.
Returns a `cv x T` array.

# Extra arguments
- `cv::Integer=10`: number of cross-validation folds
- `n_jobs::Integer=1`: number of CPU cores to use
- `scoring`: sklearn scorer to use. Defaults to variance weighted R2
- `cum_av::Bool=false`: use cumulative average of the signal
"""
function get_regr_cv_scores_through_time(df, regressor, input_field, out_field, cv = 10; n_jobs=1, scoring=sk_metrics.make_scorer(sk_metrics.r2_score, multioutput = "variance_weighted"), cum_av = false)
    X_per_trial = permutedims(get_sig_by_trial(df, input_field), (3, 2, 1))
    y = df[!, out_field]
    
    T = size(X_per_trial, 3);
    
    cv_scores = []
    for t in 1:T
        if cum_av
          x = dropdims(mean(X_per_trial[:, :, 1:t],
                            dims = 3),
                       dims = 3)
        else
          x = X_per_trial[:, :, t]
        end
        push!(cv_scores, model_selection.cross_val_score(regressor, x, y, cv = model_selection.KFold(cv, shuffle=true), scoring = scoring, n_jobs = n_jobs))
    end

    
    return hcat(cv_scores...)
end


"""
$(SIGNATURES)

Fit `predictor` at every time point, predicting `out_field` from `input_field` and record the axes used for prediction.
`predictor` has to have a `.coef_` field.
If `cum_av` is true, use a cumulative average of the signal.

Returns an array of coefficients (which are arrays themselves).
"""
function get_predictive_axis_through_time(df, predictor, input_field, out_field; cum_av = false)
    X_per_trial = permutedims(get_sig_by_trial(df, input_field), (3, 2, 1))
    y = df[!, out_field]
    
    T = size(X_per_trial, 3);
    
    coefficients = []
    for t in 1:T
        if cum_av
          x = dropdims(mean(X_per_trial[:, :, 1:t],
                            dims = 3),
                       dims = 3)
        else
          x = X_per_trial[:, :, t]
        end
        push!(coefficients, predictor.fit(X_per_trial[:, :, t], y).coef_)
    end

    return coefficients
end
