"""
    $(SIGNATURES)

Concatenate a collection of dataframes only keeping common columns.
If `verbose` is set, print which columns were removed from the individual dataframes.
"""
function combine_dataframes(dataframes; verbose = false)
    common_fields = intersect(names.(dataframes)...)
    if verbose
        for (i, dfi) in enumerate(dataframes)
            removed_fields = setdiff(names(dfi), common_fields)
            if length(removed_fields) > 0
                println("Removing the following columns from dataframe #$(i): $(removed_fields)")
            end
        end
    end

    return vcat([dfi[:, common_fields] for dfi in dataframes]...);
end
