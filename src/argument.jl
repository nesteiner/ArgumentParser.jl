ArgumentType = Union{String, <:Number, Vector{String}, Vector{<:Number}}

@kwdef struct Argument{T <: ArgumentType}
    name::String
    require::Bool = true
    short::Union{Nothing, String} = nothing
    long::Union{Nothing, String} = nothing
end

Argument(
    T::Type{<:ArgumentType};
    name::String,
    require::Bool = true,
    short::Union{Nothing, String} = nothing,
    long::Union{Nothing, String} = nothing) = Argument{T}(name = name, require = require, short = short, long = long)


eltype(::Argument{T}) where T = T