
export BuiltinValue, getEnumBuiltinValue, BuiltIn, @builtin, BuiltInDataType

@enum BuiltinValue begin
	vertex_index
	instance_index
	position
	front_facing
	frag_depth
	local_invocation_id
	local_invocation_index
	global_invocation_id
	workgroup_id
	num_workgroups
	sample_index
	sample_mask
end

function getEnumBuiltinValue(s::Symbol)
	ins = instances(BuiltinValue)
	for i in ins
		if string(s) == string(i)
			return i
		end
	end
	@error "$s is not in builtin types"
end

struct BuiltIn{B, S, D} end

function BuiltIn(btype::Symbol, pair::Pair{Symbol, DataType})
	bVal = getEnumBuiltinValue(btype) |> Val
	sVal = pair.first
	dVal = pair.second |> Val
	return BuiltIn{bVal, sVal, dVal}
end

struct BuiltInDataType{B, D} end

function BuiltInDataType(btype::Symbol, dType::DataType)
	bVal = getEnumBuiltinValue(btype) |> Val
	dVal = dType |> Val
	return BuiltInDataType{bVal, dVal}
end

macro builtin(btype, dtype::DataType)
	@assert typeof(btype) == Symbol """\n
		Expecting expression, found typeof(exp) instead
			builtin can be defined as
			@builtin builtinValue DataType
		"""
	@assert btype in Symbol.(instances(BuiltinValue)) "$(btype) is not in BuiltinValue Enum"
	@assert typeof(eval(dtype)) == DataType "Expecting Valid Data Type"
	return BuiltInDataType(btype, eval(dtype))
end

macro builtin(sym::Symbol, expr::Expr)
	@capture(expr, a_::b_) && return BuiltIn(sym, a=>eval(b))
	@capture(expr, a_) && return BuiltInDataType(sym, eval(a))
	error("BuiltIn didn't follow expected format!!!")
end

function BuiltIn(sVal::Symbol, ::Type{BuiltInDataType{B, D}}) where {B, D}
	return BuiltIn{B, sVal, D}
end


