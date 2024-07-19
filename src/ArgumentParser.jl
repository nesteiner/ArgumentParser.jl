module ArgumentParser

import Base: eltype

export parseArguments, Argument, Positioned, SubCommand, Flag, 
    hasargument, hasflag, haspositioned, hassubcommand

include("argument.jl")
include("flag.jl")
include("positioned.jl")
include("subcommand.jl")
include("exception.jl")
#=
for case 1
=#
function parseArguments(; 
    target::Vector{String}, 
    subcommand::Union{Nothing, SubCommand} = nothing,
    positions::Vector{<:Positioned} = Positioned{String}[],
    arguments::Vector{<:Argument} = Argument{String}[],
    flags::Vector{Flag} = Flag[])::Dict{String, Any}

    #= validdate positions
    验证固定位置参数是否合法，
    如果positioned.require为true并且参数数组在positioned.index上的值是Flag或者Argument的时，
    抛出ParseException异常

    to validate if the `Positoned` arguments are valid
    and if `positoned.require` is true and the target[postioned.index] is a flag or argument,
    throw a `ParseException`
    
    =#
    for positioned in positions
        if positioned.require && isargument(target[positioned.index])
            throw(ParseException("expect postioned but found argument"))
        end
    end

    #= validate arguments
    Flag类型我们没有定义 require 字段，他代表的值是Bool类型，我们不需要对其进行验证。
    最后是Argument类型的验证，由于Argument在后面一定要携带一个或多个值，
    所以主要验证在require字段为true的情况下，
    在参数数组中查找是否有这个Argument，并查看Argument后面的值是否合法

    for `Flag` has no `require` field, and its value is `Bool`, we don't need to validate it
    for `Argument` type, it has one or many value, 
    so we need to validate it : when its `require` is true, find out if there is such `Argument` in the target,
    and check out if the value after `Argument` is valid
    =#
    for argument in arguments
        if argument.require
            index = findfirst(x -> matchShort(x, argument.short) || matchLong(x, argument.long) || matchName(x, argument.name), target)
            if isnothing(index)
                throw(ParseException("no argument value provide which name is $(argument.name)"))
            end

            if isargument(target[index + 1])
                throw(ParseException("invalid argument value provide which name is $(argument.name)"))
            end

            # TODO validate number, string and vector
        end
    end

    #=
    验证完毕后，定义一个 Dict{String, Any} 来存储结果，
    再用 strings 来将参数数组 copy 一下，因为接下来我们要操作参数数组

    after validation, we define a `Dict{String, Any}` to store the result,
    and then we copy the `target` array to `strings`, for we need to operate the `target` vector without modifying it
    =#
    result = Dict{String, Any}()

    strings::Vector{String} = copy(target)
    
    if !isnothing(subcommand) && subcommand.require
        index = findfirst(isequal(subcommand.name), target)
        if index != 1
            throw(ParseException("subcommand must be the first"))
        end
        
        result[subcommand.name] = popat!(target, index)
    end
    
    for positioned in positions
        if positioned.require
            index = positioned.index
            type = eltype(positioned)
        
            result[positioned.name] = if type == String
                strings[index]
            else
                parse(type, strings[index])
            end
        end
    end

    #=
    解析这两种参数类型完毕后，我们操作参数数组，将其删除掉与 SubCommand 和 Positioned 匹配的值

    after parsing `SubCommand` and `Positioned`, let operate the `strings` to delete the match value
    =#
    splice!(strings, map(x -> x.index, positions))

    if !isnothing(subcommand) && subcommand.require
        popfirst!(strings)
    end


    #= fetch flags
    需要将Flag数组解析，如果在参数数组中找不到匹配的Flag，那么在结果中设置值为Flag的 defaultValue

    then we need to parse the `flags`, if there is no matched `Flag` in the `target`, then we set the `result[flag.name]` to its default value
    =#
    for flag in flags
        index = findfirst(x -> matchShort(x, flag.short) || matchLong(x, flag.long), strings)
        if isnothing(index)
            result[flag.name] = flag.defaultValue
        else
            result[flag.name] = true
            popat!(strings, index)
        end
    end

    
    # now parse arguments
    while true
        if isempty(strings)
            break
        end
        
        s = popfirst!(strings)

        index = findfirst(x -> matchShort(s, x.short) || matchLong(s, x.long) || matchName(s, x.name), arguments)
        argument::Argument = arguments[index]

        # there is no need to consider require of arugment, for I have validated it
        type = eltype(argument)
        if type <: Vector
            values::Vector{String} = collect(Iterators.takewhile(!isargument, strings))
            splice!(strings, 1:length(values))
            elementtype::DataType = eltype(type)
            result[argument.name] = if elementtype == String
                values
            else
                map(x -> parse(elementtype, x), values)
            end
        else
            value = popfirst!(strings)
            result[argument.name] = if type == String
                value
            else
                parse(type, value)
            end
        end

    end

    return result
end

isargument(s::String) = startswith(s, "-") || startswith(s, "--")
matchShort(left::String, right::Union{Nothing, String}) = if isnothing(right)
    false
else
    left == right
end

matchLong(left::String, right::Union{Nothing, String}) = if isnothing(right)
    false
else
    left == right
end

matchName(left::String, right::String) = left == right

hasargument(target::Vector{String}, argument::Argument{T}) where T <: ArgumentType = any(x -> matchShort(x, argument.short) || matchLong(x, argument.long) || matchName(x, argument.name), target)
hasflag(target::Vector{String}, flag::Flag) = any(x -> matchShort(x, flag.short) || matchShort(x, flag.long), target)
haspositioned(target::Vector{String}, positioned::Positioned{T}) where T <: PositionedType = length(target) >= positioned.index
hassubcommand(target::Vector{String}, subcommand::SubCommand) = first(target) == subcommand.name

@static if false
    include("../examples/examples.jl")
end

end # module ArgumentParser
