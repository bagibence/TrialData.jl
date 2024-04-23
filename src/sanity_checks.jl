"""
$(SIGNATURES)

Check that all trials are the same length. 
"""
function all_trials_are_the_same_length(df)
    return length(unique(get_trial_length.(eachrow(df)))) == 1
end
