module WGSLTypes

using Infiltrator
using MacroTools
using StaticArrays
using DataStructures

const Vec2{T} = SVector{2, T}
const Vec3{T} = SVector{3, T}
const Vec4{T} = SVector{4, T}
const Mat2{T} = SMatrix{2, 2, T, 4}
const Mat3{T} = SMatrix{3, 3, T, 9}
const Mat4{T} = SMatrix{4, 4, T, 16}
const Vec{N, T} = SVector{N, T}

include("functions.jl")
include("builtins.jl")
include("locations.jl")
include("userstructs.jl")
include("macros.jl")
include("typeutils.jl")
include("variableDecls.jl")
include("structUtils.jl")

export @builtin, @location, wgslCode, wglsType, @var, @letvar, makePaddedWGSLStruct, makePaddedStruct,
	makeStruct, StorageVar, UniformVar, PrivateVar, BuiltIn, BuiltInDataType, BuiltinValue,
	Location, LocationDataType

end
