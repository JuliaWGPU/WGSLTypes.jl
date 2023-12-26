
using WGSLTypes

export @code_wgsl

function evalUserField(expr)
	if typeof(expr) == Expr
		if @capture(expr, Array{T_})
			if typeof(T) == Symbol
				return Array{nameof(eval(T))}
			end
		elseif @capture(expr, Array{T_, N_})
			# TODO same as above
			return Array{nameof(eval(T)), eval(N)}
		else
			return wgslType(expr)
		end
	end
end

macro user(expr)
	return evalUserField(expr)
end


# TODO this function takes block of fields too
# Another function that makes a sequence of field 
# statements is needed.
function evalStructField(fieldDict, field)
	if @capture(field, if cond_ ifblock__ end)
		if eval(cond) == true
			for iffield in ifblock
				evalStructField(fieldDict, iffield)
			end
		end
	elseif @capture(field, if cond_ ifblock__ else elseBlock__ end)
		if eval(cond) == true
			for iffield in ifblock
				evalStructField(fieldDict, iffield)
			end
		else
			for elsefield in elseBlock
				evalStructField(fieldDict, elsefield)
			end
		end
	elseif @capture(field, name_::dtype_)
		return push!(fieldDict, name=>eval(dtype))
	elseif @capture(field, @builtin btype_ name_::dtype_)
		return push!(fieldDict, name=>eval(:(@builtin $btype $dtype)))
	elseif @capture(field, @location btype_ name_::dtype_)
		return push!(fieldDict, name=>eval(:(@location $btype $dtype)))
	elseif @capture(field, quote stmnts__ end)
		for stmnt in stmnts
			evalStructField(fieldDict, stmnt)
		end
	else
		@error "Unknown struct field! $field"
	end
end

function wgslStruct(expr)
	expr = MacroTools.striplines(expr)
	expr = MacroTools.flatten(expr)
	@capture(expr, struct T_ fields__ end) || error("verify struct format of $T with fields $fields")
	fieldDict = OrderedDict{Symbol, DataType}()
	for field in fields
		evalfield = evalStructField(fieldDict, field)
	end
	makePaddedStruct(T, :UserStruct, fieldDict)
	makePaddedWGSLStruct(T, fieldDict)
end

# TODO rename simple asssignment and bring back original assignment if needed
function wgslAssignment(expr)
	io = IOBuffer()
	@capture(expr, a_ = b_) || error("Expecting simple assignment a = b")
	write(io, "$(wgslType(a)) = $(wgslType(b));\n")
	seek(io, 0)
	stmnt = read(io, String)
	close(io)
	return stmnt
end

# function wgslDecisionBlock(io, stmnts; indent=true, indentLevel=0)
# 	for stmnt in stmnts
# 		if indent==true
# 			indentLevel += 1
# 			write(io, " "^(4*indentLevel))
# 		end
# 		wgslFunctionStatement(io, stmnt)
# 	end
# end
function wgslFunctionStatement(io, stmnt; indent=true, indentLevel=0)
	if indent==true
		write(io, " "^(4*indentLevel))
	end
	if @capture(stmnt, @var t__)
		write(io, wgslVariable(stmnt))
	elseif @capture(stmnt, a_ = b_)
		write(io, wgslAssignment(stmnt))
	elseif @capture(stmnt, @let t_ | @let t__)
		stmnt.args[1] = Symbol("@letvar") # replace let with letvar
		write(io, wgslLet(stmnt))
	elseif @capture(stmnt, return t_)
		write(io, "return $(wgslType(t));\n")
	elseif @capture(stmnt, if cond_ ifblock__ end)
		if cond == true
			wgslFunctionStatements(io, ifblock;indent=true, indentLevel=indentLevel)
		end
	elseif @capture(stmnt, @escif if cond_ blocks__ end)
		write(io, " "^(4*(indentLevel-1))*"if $cond {\n")
		wgslFunctionStatements(io, blocks; indent=false, indentLevel=indentLevel)
		write(io, " "^(4*(indentLevel))*"}\n")
	elseif @capture(stmnt, if cond_ ifBlock__ else elseBlock__ end)
		if eval(cond) == true
			wgslFunctionStatements(io, ifBlock; indent=true, indentLevel=indentLevel)
		else
			wgslFunctionStatements(io, elseBlock; indent=true, indentLevel=indentLevel)
		end
	else
		@error "Failed to capture statment : $stmnt !!"
	end
end

function wgslFunctionStatements(io, stmnts; indent=true, indentLevel=0)
	for stmnt in stmnts
		if indent==true
			write(io, " "^(4*indentLevel))
		end
		wgslFunctionStatement(io, stmnt; indent=true, indentLevel=indentLevel+1)
	end
end

function wgslFunctionBody(fnbody, io, endstring)
	if @capture(fnbody[1], fnname_(fnargs__)::fnout_)
		if !(fnname in wgslfunctions)
			quote	
				function $fnname() end
				wgslType(::typeof(eval($fnname))) = string($fnname)
			end |> eval
		end
		write(io, "fn $fnname(")
		len = length(fnargs)
		endstring = len > 0 ? "}\n" : ""
		for (idx, arg) in enumerate(fnargs)
			if @capture(arg, aarg_::aatype_)
				intype = wgslType(eval(aatype))
				write(io, "$aarg:$(intype)"*(len==idx ? "" : ", "))
			elseif @capture(arg, @builtin e_ id_::typ_)
				intype = wgslType(eval(typ))
				write(io, "@builtin($e) $id:$(intype)")
			elseif @capture(arg, @location e_ id_::typ_)
				intype = wgslType(eval(typ))
				write(io, "@location($e) $id:$(intype)")
			end
			write(io, idx == length(fnargs) ? "" : ", ")
			# TODO what is this check ... not clear
			@capture(fnargs, aarg_) || error("Expecting type for function argument in WGSL!")
		end
		outtype = wgslType(eval(fnout))
		write(io, ") -> $outtype { \n")
		@capture(fnbody[2], stmnts__) || error("Expecting quote statements")
		wgslFunctionStatements(io, stmnts)
	elseif @capture(fnbody[1], fnname_(fnargs__))
		write(io, "fn $fnname(")
		len = length(fnargs)
		endstring = len > 0 ? "}\n" : ""
		for (idx, arg) in enumerate(fnargs)
			if @capture(arg, aarg_::aatype_)
				intype = wgslType(eval(aatype))
				write(io, "$aarg:$(intype)"*(len==idx ? "" : ", "))
			elseif @capture(arg, @builtin e_ id_::typ_)
				intype = wgslType(eval(typ))
				write(io, "@builtin($e) $id:$(intype)")
			elseif @capture(arg, @location e_ id_::typ_)
				intype = wgslType(eval(typ))
				write(io, "@location($e) $id:$(intype)")
			end
			write(io, idx == length(fnargs) ? "" : ", ")
			# TODO what is this check ... not clear
			@capture(fnargs, aarg_) || error("Expecting type for function argument in WGSL!")
		end
		write(io, ") { \n")
		@capture(fnbody[2], stmnts__) || error("Expecting quote statements")
		wgslFunctionStatements(io, stmnts)
	end
	write(io, endstring)
end



function wgslVertex(expr)
	io = IOBuffer()
	endstring = ""
	@capture(expr, @vertex function fnbody__ end) || error("Expecting regular function!")
	write(io, "@vertex ") # TODO should depend on version
	wgslFunctionBody(fnbody, io, endstring)
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

function wgslFragment(expr)
	io = IOBuffer()
	endstring = ""
	@capture(expr, @fragment function fnbody__ end) || error("Expecting regular function!")
	write(io, "@fragment ") # TODO should depend on version
	wgslFunctionBody(fnbody, io, endstring)
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

function wgslCompute(expr)
	io = IOBuffer()
	endstring = ""
	if @capture(expr, @compute @workgroupSize(x_) function fnbody__ end)
		write(io, "@compute @workgroup_size($x) \n")
	elseif	@capture(expr, @compute @workgroupSize(x_,) function fnbody__ end)
		write(io, "@compute @workgroup_size($x) \n")
	elseif @capture(expr, @compute @workgroupSize(x_, y_) function fnbody__ end)
		write(io, "@compute @workgroup_size($x, $y) \n")
	elseif @capture(expr, @compute @workgroupSize(x_, y_, z_) function fnbody__ end)
		write(io, "@compute @workgroup_size($x, $y, $z) \n")
	else
		error("Did not match the compute declaration function!")
	end
	wgslFunctionBody(fnbody, io, endstring)
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

function wgslFunction(expr)
	io = IOBuffer()
	endstring = ""
	@capture(expr, function fnbody__ end) || error("Expecting regular function!")
	wgslFunctionBody(fnbody, io, endstring)
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

function wgslVariable(expr)
	io = IOBuffer()
	write(io, wgslType(eval(expr)))
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

# TODO for now both wgslVariable and wgslLet are same
function wgslLet(expr)
	io = IOBuffer()
	write(io, wgslType(eval(expr)))
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end


function wgslConstVariable(block)
	@capture(block, @const constExpr_)
	return "const $(wgslType(constExpr));\n"
end


# IOContext TODO
function wgslCode(expr)
	io = IOBuffer()
	expr = MacroTools.striplines(expr)
	expr = MacroTools.flatten(expr)
	@capture(expr, blocks__) || error("Current expression is not a quote or block")
	for block in blocks
		if @capture(block, struct T_ fields__ end)
			write(io, wgslStruct(block))
		elseif @capture(block, a_ = b_)
			write(io, wgslAssignment(block))
		elseif @capture(block, @var t__)
			write(io, wgslVariable(block))
		elseif @capture(block, @const ct__)
			write(io, wgslConstVariable(block))
		elseif @capture(block, @vertex function a__ end)
			write(io, wgslVertex(block))
			write(io, "\n")
		elseif @capture(block, @compute @workgroupSize(x__) function a__ end)
			write(io, wgslCompute(block))
			write(io, "\n")
		elseif @capture(block, @fragment function a__ end)
			write(io, wgslFragment(block))
			write(io, "\n")
		elseif @capture(block, function a__ end)
			write(io, wgslFunction(block))
			write(io, "\n")
		elseif @capture(block, if cond_ ifblock_ end)
			if eval(cond) == true
				write(io, wgslCode(ifblock))
				write(io, "\n")
			end
		elseif @capture(block, if cond_ ifBlock_ else elseBlock_ end)
			if eval(cond) == true
				write(io, wgslCode(ifBlock))
				write(io, "\n")
			else
				write(io, wgslCode(elseBlock))
				write(io, "\n")
			end
		end
	end
	seek(io, 0)
	code = read(io, String)
	close(io)
	return code
end

macro code_wgsl(expr)
	a = wgslCode(eval(expr)) |> println
	return a
end

