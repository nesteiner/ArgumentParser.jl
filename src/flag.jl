struct Flag
    name::String
    defaultValue::Bool
    short::Union{Nothing, String}
    long::Union{Nothing, String}
end

function Flag(; name::String, defaultValue::Bool, short::Union{Nothing, String} = nothing, long::Union{Nothing, String} = nothing)
    if isnothing(short) && isnothing(long)
        throw(DefinitionException("short and long cannot both be nothing"))
    end

    Flag(name, defaultValue, short, long)
end