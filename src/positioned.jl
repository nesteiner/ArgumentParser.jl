PositionedType = Union{String, <:Number}

struct Positioned{T <: PositionedType}
    name::String
    index::Int
    require::Bool
end

Positioned(
    T::Type{<:PositionedType};
    name::String,
    index::Int,
    require::Bool = true) = Positioned{T}(name, index, require)


eltype(::Positioned{T}) where T = T