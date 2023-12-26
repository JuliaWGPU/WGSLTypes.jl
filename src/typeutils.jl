using StaticArrays
using Infiltrator

varyingTypes = [
	"f32", "vec2<f32>", "vec3<f32>", "vec4<f32>",
	"i32", "vec2<i32>", "vec3<i32>", "vec4<i32>",
	"u32", "vec2<u32>", "vec3<u32>", "vec4<u32>"
]

juliaToWGSLTypes = Dict(
	Bool => "bool",
	Int32 => "i32",
	UInt32 => "u32",
	Float16 => "f16",
	Float32 => "f32",
)

wgslType(a::Bool) = a;
wgslType(a::Int32) = "$(a)i";
wgslType(a::UInt32) = "$(a)u";
wgslType(a::Float16) = a;
wgslType(a::Float32) = a;
wgslType(a::Int) = a;
wgslType(a::Number) = a;

function wgslType(::Type{Vec2{T}}) where {T}
	return "vec2<$(wgslType(T))>"
end

function wgslType(::Type{Vec3{T}}) where {T}
	return "vec3<$(wgslType(T))>"
end

function wgslType(::Type{Vec4{T}}) where {T}
	return "vec4<$(wgslType(T))>"
end

# wgslType(::Type{T}) where T<:UserStruct = begin
# 	string(T) |> (x) -> split(x, ".") |> last
# end

function wgslType(t::Type{T}) where T
	if T <: UserStruct
		return string(T)
	end
	wgsltype = get(juliaToWGSLTypes, T, nothing)
	if wgsltype === nothing
		@error "Invalid Julia type $T with value $t or missing wgsl type"
	end
	return wgsltype
end

function wgslType(::Type{Mat4{T}}) where T
 	return "mat4x4<$(wgslType(T))>"
end

function wgslType(::Type{Mat3{T}}) where T
 	return "mat3x3<$(wgslType(T))>"
end

function wgslType(::Type{Mat2{T}}) where T
 	return "mat2x2<$(wgslType(T))>"
end

function wgslType(::Type{Array{T, N}}) where {T, N}
	return "array<$(wgslType(T)), $N>"
end

function wgslType(::Type{Array{T}}) where T
	return "array<$(wgslType(T))>"
end

function wgslType(a::Function) 
	return nameof(a)
end

function wgslType(::Type{SMatrix{N, M, T, L}}) where {N, M, T, L}
	return "mat$(N)x$(M)<$(wgslType(T))>"
end

function wgslType(::Type{SVector{N, T}}) where {N, T}
	return "vec$(N)<$(wgslType(T))>"
end

wgslType(b::BuiltinValue) = string(b)

function wgslType(a::Pair{Symbol, DataType})
	return "$(a.first):$(wgslType(a.second))"
end

function wgslType(a::Pair{Symbol, Any})
	if a.second == :Any
		return "$(a.first)"
	else
		return "$(a.first):$(wgslType(a.second))"
	end
end

wgslType(val::Val{T}) where T = wgslType(T)

function wgslType(a::Symbol)
	if !isdefined(@__MODULE__, a)
		return string(a)
	elseif typeof(eval(a)) <: UserStruct
		return string(a)
	else
		return wgslType(eval(a))
	end
end

function wgslType(::Type{BuiltIn{B, S, D}}) where {B, S, D}
	return "@builtin($(wgslType(B) |> string)) $(S):$(wgslType(D))"
end

function wgslType(::Type{BuiltInDataType{B, D}}) where {B, D}
	return "@builtin($(wgslType(B) |> string)) $(wgslType(D))"
end

function wgslType(::Type{Location{B, S, D}}) where {B, S, D}
	return "@location($(wgslType(B))) $S:$(wgslType(D))"
end

function wgslType(::Type{LocationDataType{B, D}}) where {B, D}
	return "@location($(wgslType(B))) $(wgslType(D))"
end

wgslType(::typeof(*)) = "*"
wgslType(::typeof(+)) = "+"
wgslType(::typeof(/)) = "/"
wgslType(::typeof(-)) = "-"


# TODO nested operations with operator precedence
# For now add brackets manually
function wgslOperation(op, x, y)
	if typeof(x) <: Number && typeof(y) <: Number
		return "$(wgslType(x)) $op $(wgslType(y))"
	else
		return "$x $op $y"
	end
end

wgslType(s::String) = s

function wgslType(expr::Union{Expr, Type{Expr}})
	if @capture(expr, a_ = b_)
		return "$(wgslType(a)) = $(wgslType(b))"
	elseif expr.head == :call
		@capture(expr, f_(x_)) && return "$(wgslType(eval(f)))($x)"
		@capture(expr, f_(x_, y_)) && f in (:*, :-, :+, :/) && return wgslOperation(f, x, y)
		# @capture(expr, f_(x_, y_)) && !(f in (:*, :-, :+, :/)) && return "$(eval(f))($(x), $(y))"
		@capture(expr, f_(x__)) && begin
			xargs = join(wgslType.(x), ", ")
			return "$(wgslType(eval(f)))($(xargs))"
		end
	elseif @capture(expr, a_::b_)
		return "$a::$(wgslType(eval(b)))"
	elseif @capture(expr, a_::b_ = c_)
		return "$a::$(wgslType(eval(b))) = $c"
	elseif @capture(expr, a_.b_)
		return "$a.$b"
	elseif @capture(expr, ref_[b_])
		return "$ref[$b]"
	else
		@error "Could not capture $expr !!!"
	end
end

