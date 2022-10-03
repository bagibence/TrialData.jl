# this has to be done this way instead of @sk_import because otherwise it throws a segfault
# https://github.com/JuliaPy/PyCall.jl/blob/master/README.md#using-pycall-from-julia-modules
# https://github.com/cstjean/ScikitLearn.jl/issues/50
const model_selection = PyNULL()
const sk_metrics = PyNULL()
const default_scorer = PyNULL()
const sk_decomp = PyNULL()

function __init__()
    copy!(model_selection, pyimport("sklearn.model_selection"))
    copy!(sk_metrics, pyimport("sklearn.metrics"))
    copy!(default_scorer, sk_metrics.make_scorer(sk_metrics.r2_score, multioutput = "variance_weighted"))
    copy!(sk_decomp, pyimport("sklearn.decomposition"))
end



