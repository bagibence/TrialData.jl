module TrialData

using Statistics
using DataFrames
using DataFramesMeta

using HDF5: h5open
using MAT: matopen

using PyCall: pyimport
pd = pyimport("pandas");

using DSP: gaussian, conv

using LinearAlgebra: norm


end # module
