using WGSLTypes
using WGSLTypes: wgslStruct
using MacroTools
using MacroTools: striplines, @capture, flatten


e = quote
    struct T
        scale::Float32
        offset::SVector{3, Float32}
        projection::SMatrix{4, 4, Float32, 16}
    end
end

expr = e |> striplines |> flatten

wgslStruct(expr)

WGSLTypes.T |> fieldnames


e = quote
        struct GSplatIn
            pos::Vec3{Float32}
            scale::Vec3{Float32}
            opacity::Float32
            quaternions::Vec4{Float32}
            sh::Vec3{Float32}
        end
    end

        
expr = e |> striplines |> flatten

wgslStruct(expr)

WGSLTypes.GSplatIn |> fieldnames
                                                                            
