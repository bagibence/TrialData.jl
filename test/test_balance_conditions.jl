using DataFrames
using StatsBase: countmap

function _test_balance_conditions(group_lengths, max_samples, desired_length)
    # generate a dataframe with the given number of trials and a random field
    function _build_df(group_lengths)
        row_tups = []
        for (group_val, n_trials) in group_lengths
            for i in 1:n_trials
                push!(row_tups, (group_val = group_val, random_field = randn()))
            end
        end

        return DataFrame(row_tups)
      end

    if isnothing(max_samples)
        @test all(values(countmap(balance_conditions(_build_df(group_lengths), :group_val).group_val)) .== desired_length)
        #@test @pipe group_lengths |> _build_df(_) |> balance_conditions(_, :group_val) |> _.group_val |> countmap |> values |> (_ .== 10) |> all
    else
        @test all(values(countmap(balance_conditions(_build_df(group_lengths), :group_val, max_samples).group_val)) .== desired_length)
    end
end


@testset "balance_conditions" begin
    # input is the following
    # ck => # trials, max_n_trials, desired output
    _test_balance_conditions(Dict(5 => 10, 50 => 20), nothing, 10)
    _test_balance_conditions(Dict(5 => 10, 50 => 20, 1 => 30), nothing, 10)
    _test_balance_conditions(Dict(5 => 10, 50 => 20), 15, 10)
    _test_balance_conditions(Dict(5 => 10, 50 => 20), 5, 5)
    _test_balance_conditions(Dict(5 => 10, 50 => 20), 30, 10)
end
