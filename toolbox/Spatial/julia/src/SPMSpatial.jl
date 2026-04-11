module SPMSpatial

using ROMEO

"""
    romeo_unwrap_3d(phase::Array{Float32,3}, mag::Array{Float32,3})

Unwrap a single 3D phase volume using ROMEO.
Returns the unwrapped phase as a Float32 array.
Note: Data is promoted to Float64 internally for numerical stability
in ROMEO's unwrapping algorithm, then converted back to Float32.
"""
function romeo_unwrap_3d(phase::Array{Float32,3}, mag::Array{Float32,3})
    return Float32.(ROMEO.unwrap(Float64.(phase); mag=Float64.(mag), correctglobal=true))
end

"""
    romeo_unwrap_3d(phase::Array{Float64,3}, mag::Array{Float64,3})

Unwrap a single 3D phase volume using ROMEO (Float64 version).
Returns the unwrapped phase as a Float64 array.
"""
function romeo_unwrap_3d(phase::Array{Float64,3}, mag::Array{Float64,3})
    return ROMEO.unwrap(phase; mag=mag, correctglobal=true)
end

"""
    romeo_unwrap_4d(phase::Array{Float32,4}, mag::Array{Float32,4})

Unwrap 4D phase data using ROMEO. Each 3D volume is unwrapped individually
with global offset correction. Returns the unwrapped phase as a Float32 array.
"""
function romeo_unwrap_4d(phase::Array{Float32,4}, mag::Array{Float32,4})
    result = similar(phase)
    for i in axes(phase, 4)
        result[:,:,:,i] = Float32.(ROMEO.unwrap(Float64.(phase[:,:,:,i]);
                                                mag=Float64.(mag[:,:,:,i]),
                                                correctglobal=true))
    end
    return result
end

"""
    romeo_unwrap_4d(phase::Array{Float64,4}, mag::Array{Float64,4})

Unwrap 4D phase data using ROMEO (Float64 version). Each 3D volume is
unwrapped individually with global offset correction.
"""
function romeo_unwrap_4d(phase::Array{Float64,4}, mag::Array{Float64,4})
    result = similar(phase)
    for i in axes(phase, 4)
        result[:,:,:,i] = ROMEO.unwrap(phase[:,:,:,i];
                                       mag=mag[:,:,:,i],
                                       correctglobal=true)
    end
    return result
end

end # module SPMSpatial
