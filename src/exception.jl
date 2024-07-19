struct ParseException <: Exception
    message::String
end

struct DefinitionException <: Exception
    message::String
end