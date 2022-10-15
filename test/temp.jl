using WGSLTypes

T = Float32

tsize = (10, 10)

shaderSrc = quote
	struct ArrayVector
		data::Vec4{Float32}
	end

	@var Storage 0 0 input0::ArrayVector
	@var Storage 0 1 output0::ArrayVector

	@compute @workgroupSize($(tsize)) function main(@builtin global_invocation_id global_id::Vec3{UInt32})
		@let gidx = global_id.x
		output0.data[g_idx] = max(input0.data[g_idx], $(zero(eltype(T))))
	end
end

@info wgslCode(shaderSrc)

