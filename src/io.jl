"""
    to_int(idx::Number)
    to_int(indices)

Turn a number or a collection to integers.
"""
to_int(idx::Number) = isnan(idx) ? missing : Int(round(idx))
to_int(indices) = vec(to_int.(indices))


"""
    clean_idx_fields!(df)

Turn fields of the the dataframe that start with "idx" to integers.
"""
function clean_idx_fields!(df)
    idx_fieldnames = get_idx_fields(df)

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
    outdf = deepcopy(df)
    return clean_idx_fields!(outdf)
end

"""
    clean_types!(df)

`clean_types(df)` in-place.
See [`clean_types`](@ref).
"""
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

"""
    clean_types(df)

Clean the data types of `df`.
If all values in a column have the same type, cast all of them into that type.
"""
function clean_types(df)
    outdf = deepcopy(df)
    return clean_types!(outdf)
end

"""
    replace_nans!(df)

Replace `NaN` values with `missing`.
"""
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
    mat2df(filename, fieldname)

Read a data set saved in a .MAT file's fieldname variable and turn fields starting with "idx" to integers.
If fieldname is not given, it is assumed that only one variable is saved in the .MAT file.
"""
function mat2df(filename)
    data = matopen(filename)
    fieldnames = names(data)
    @assert length(fieldnames) == 1
    return mat2df(filename, first(fieldnames))
end

function mat2df(filename, fieldname)
    trial_data = read(matopen(filename), fieldname)

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
    df = sort(df, :trial_id)
    
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

Convert a DataFrame or DimArray to a pd.DataFrame because seaborn can only handle pandas DataFrames.
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
$(SIGNATURES)

Convert a DimensionalData.DimArray, NamedDims.NamedDimsArray, or AxisKeys.KeyedArray
to an xr.DataArray (mostly for plotting).
"""
function to_xarray(K::DimArray)
    xr = pyimport("xarray");

    return xr.DataArray(parent(K),
                        dims = name.(K.dims),
                        coords = _build_coords_dict(K.dims))
end

function to_xarray(K::NamedDimsArray)
    xr = pyimport("xarray")

    return xr.DataArray(parent(K),
                        dims = dimnames(K))
end

function to_xarray(K::KeyedArray)
    xr = pyimport("xarray")

    return xr.DataArray(parent(K),
                        dims = dimnames(K),
                        coords = Dict(zip(dimnames(K), axiskeys(K))))
end

"""
    _build_coords_dict(dims)

Helper for to_xarray
"""
function _build_coords_dict(dims)
    d = Dict()
    for dim in dims
        try
            d[name(dim)] = val(dim)
        catch
        end
    end
end
