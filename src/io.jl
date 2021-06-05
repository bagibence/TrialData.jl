"""
    to_int(idx::Number)
    to_int(indices)

Turn a number or a collection to integers.
"""
to_int(idx::Number) = isnan(idx) ? idx : Int(round(idx))
to_int(indices) = vec(to_int.(indices))


"""
    clean_idx_fields!(df)

Turn fields of the the dataframe that start with "idx" to integers.
"""
function clean_idx_fields!(df)
    idx_fieldnames = [n for n in names(df) if startswith(n, "idx")]

    for trial in eachrow(df)
        for n in idx_fieldnames
            trial[n] = to_int(trial[n])
        end
    end

    return df
end

"""
    clean_idx_fields(df)

Turn fields of the the dataframe that start with "idx" to integers
and return a copy of the dataframe.
"""
function clean_idx_fields(df)
    outdf = copy(df)
    return clean_idx_fields!(outdf)
end

function clean_types!(df)
    for col in names(df)
        dtypes = unique(typeof.(df[!, col]))
        if length(dtypes) == 1
            dtype = dtypes[1]

            if dtype == Missing
                continue
            end
            
            df[!, col] = dtype.(df[!, col])
            #df[!, col] = [convert(Union{Missing, dtype}, el) for el in df[!, col]]
            #df[!, col] = convert(Array{Union{Missing, dtype}}, df[!, col])
        end
    end

    return df
end

function clean_types(df)
    outdf = copy(df)
    return clean_types!(df)
end

function replace_nans!(df)
    for col in names(df)
        try
            replace!(df[!, col], NaN => missing)
        catch
        end
    end

    return df
end


"""
    mat2df(filename)

Read a data set saved in a .MAT file and turn fields starting with "idx" to integers.
"""
function mat2df(filename)
    trial_data = read(matopen(filename), "trial_data")

    cleaned_data = Dict()
    for key in keys(trial_data)
        cleaned_data[key] = vec(trial_data[key])
    end

    return cleaned_data |> DataFrame |> clean_idx_fields! |> replace_nans! |> clean_types!
end


"""
    hdf2df(path)

Read data saved saved in the custom HDF5 format I came up with for Brian's data.
"""
function hdf2df(path)
    h5file = h5open(path, "r")
    
    td = h5file["trial_data"]
    simple_fields = td["simple_fields"]
    array_fields = td["array_fields"]
    
    df = DataFrame(read(simple_fields))
    df = @orderby(df, :trial_id)
    
    for fieldname in keys(array_fields)
        #arrays = [read(array_fields[fieldname][k]) for k in sort(keys(array_fields[fieldname]))];
        arrays = [read(array_fields[fieldname][string(tid)]) for tid in df.trial_id];
        
        if ndims(arrays[1]) == 2
            df[!, fieldname] = [Array(arr') for arr in arrays]
        else
            df[!, fieldname] = arrays
        end
    end
    
    close(h5file)
    
    return df
end


"""
    to_pandas(df)
    to_pandas(arr::DimArray)

Convert a DataFrame or DimArray to a pd.DataFrame because seaborn can only handle pandas DataFrames
"""
function to_pandas(df)
    # this works for now but might want to create a global variable for pd like the docs say
    pd = pyimport("pandas")
    return pd.DataFrame(Matrix(df)).rename(columns = Dict(zip(0:length(names(df))-1,
                                                                 names(df))));
end

function to_pandas(arr::DimArray)
    return to_xarray(arr).to_pandas()
end

"""
    to_xarray(K::DimArray)

Convert a DimensionalData.DimArray to an xr.DataArray (mostly for plotting).
"""
function to_xarray(K::DimArray)
    xr = pyimport("xarray");
    return xr.DataArray(parent(K),
                        dims = name.(K.dims),
                        coords = Dict(name(dim) => val(dim) for dim in K.dims))
end;
