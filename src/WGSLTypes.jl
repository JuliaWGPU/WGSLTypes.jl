module WGSLTypes

include("functions.jl")
include("builtins.jl")
include("locations.jl")
include("userstructs.jl")
include("macros.jl")
include("typeutils.jl")
include("variableDecls.jl")
include("structUtils.jl")
include("shaders.jl")

export @builtin, @location, wgslCode, wglsType, @var, @letvar, makePaddedWGSLStruct, makePaddedStruct,
	makeStruct, StorageVar, UniformVar, PrivateVar, BuiltIn, BuiltInDataType, BuiltinValue,
	Location, LocationDataType

end

