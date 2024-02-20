export Location, @location, LocationDataType

struct Location{B, S, D} end


function Location(btype::Int, pair::Pair{Symbol, DataType})
	bVal = (btype) |> Val
	sVal = pair.first
	dVal = pair.second |> Val
	return Location{bVal, sVal, dVal}
end

struct LocationDataType{B, D} end


function LocationDataType(btype::Int, dType::DataType)
	bVal = (btype) |> Val
	dVal = dType |> Val
	return LocationDataType{bVal, dVal}
end


macro location(btype::Int, dtype::DataType)
	@assert typeof(btype) == Int """\n
	------------------------------------------------
	Expecting expression, found typeof(exp) instead
		location can be defined as
		@location Int DataType
	------------------------------------------------
	"""
	#@assert typeof(eval(dtype)) == DataType "Expecting Valid Data Type : $btype, $dtype"
	return LocationDataType(btype, eval(dtype))
end

macro location(slot::Int, expr::Union{Expr, Symbol})
	@capture(expr, a_::b_) && return Location(slot, a=>eval(b))
	@capture(expr, b_) && return LocationDataType(slot, eval(b))
end


function Location(sVal::Int, ::Type{Location{B, D}}) where {B, D}
	return Location{B, sVal, D}
end


