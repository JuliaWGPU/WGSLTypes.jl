
abstract type UserStruct end

wgslType(::Type{T})  where T<:UserStruct = nameof(T)
