using WGSLTypes

T = Float32

tsize = (10, 10)

shaderSrc = quote

	struct Data
		data::Vec2{Float32}
	end
	
	struct ArrayVector
		data::Array{Data, 1}
	end

	@var StorageReadWrite 0 0 input0::ArrayVector
	@var StorageReadWrite 0 1 output0::ArrayVector

	@compute @workgroupSize($(tsize)) function main(@builtin(global_invocation_id, global_id::Vec3{UInt32}),@builtin(local_invocation_id, local_id::Vec3{UInt32})
	)::Vec3{Float32}
		@let gidx = global_id.x

		@escif if gidx > 0
				@let tidx = 0
				@let sidx = 4
			end
		
		output0.data[g_idx] = max(input0.data[g_idx], $(zero(eltype(T))))
	end
end

@info wgslCode(shaderSrc)

