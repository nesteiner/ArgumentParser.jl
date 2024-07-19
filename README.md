# ArgumentParser.jl

## Introduction

eh, this is a project-based-learning project, for building a simple command line argument parser.
I don't know why there is not a lot of tutorial about how to build a library in of command line argument parser, so I create one with my own understanding.
this project is very simple, but I need issue and feedback to improve it, can you help me out ?

## Usage

there are 4 arguments:

```julia
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
```

```julia
@kwdef struct Flag
    name::String
    defaultValue::Bool
    short::Union{Nothing, String} = nothing
    long::Union{Nothing, String} = nothing
end

function Flag(; name::String, defaultValue::Bool, short::Union{Nothing, String} = nothing, long::Union{Nothing, String} = nothing) 
    if isnothing(short) && isnothing(long)
        throw(DefinitionException("short and long cannot both be null"))
    end

    Flag(name, defaultValue, short, long)
end
```

```julia
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
```

```julia
@kwdef struct SubCommand
    name::String
    require::Bool = true
end
```

and there are some predicate function

```julia
hasargument(target::Vector{String}, argument::Argument{T}) where T <: ArgumentType = any(x -> matchShort(x, argument.short) || matchLong(x, argument.long) || matchName(x, argument.name), target)
```

```julia
hasflag(target::Vector{String}, flag::Flag) = any(x -> matchShort(x, flag.short) || matchShort(x, flag.long), target)
```

```julia
haspositioned(target::Vector{String}, positioned::Positioned{T}) where T <: PositionedType = target[positioned.index] == position.name
```

```julia
hassubcommand(target::Vector{String}, subcommand::SubCommand) = first(target) == subcommand.name
```

the main idea for parsing the arguments is

1. split the argv into `Vector{String}`
2. use 4 types of arguments to construct parsing rules
3. get result from `parseArguments`


### simple usage

1. `myapp -v`
2. `myapp --version`

```julia
let args = ["-v"]
    flag = Flag(name = "verbose", short = "-v", long = "--verbose", defaultValue = false)
    parseArguments(target = args, flags = [flag])
end
```

### calculate 

1. `calculate 5 + 3`, expect ouput 8, **but I cannot describe it now**
2. `calculate`, expect error

### use argument

1. `config-editor --set username admin --set password scretpassword`
2. `config-editor --get username`, expect output `admin`
3. `config-editor --set`, expect error for lack of pair of `--set`

```julia
# 1. "config-editor --set username admin"
# 2. "config-editor --set password password"
let args1 = ["--set", "username", "admin"]
    subcommand = SubCommand(name = "--set")
    result = nothing
    if hassubcommand(args1, subcommand)
        argument = Argument(String, name = "username")
        result = parseArguments(target = args1, subcommand = subcommand, arguments = [argument])
    end

    args2 = ["--set", "password", "password"]
    if hassubcommand(args2, subcommand)
        argument = Argument(String, name = "password")
        merge!(result, parseArguments(target = args2, subcommand = subcommand, arguments = [argument]))
    end
end

let args = ["--set"]
    subcommand = SubCommand(name = "--set")
    argument = Argument(String, name = "username")
    parseArguments(target = args, subcommand = subcommand, arguments = [argument])
end
```

### operation on file

1. `file-analyzer --file example.txt --count-lines`
2. `file-analyzer --file non_existent_file.txt` expect error for file not exist

```julia
# 1. "file-analyzer --file existfile.txt --count-lines"
# 2. "file-analyzer --file non_existent_file.txt"
let args1 = ["--file", "/home/steiner/workspace/julia-scratch/ArgumentParser.jl/examples/examples.jl", "--count-lines"]
    argument = Argument(String, name = "file", long = "--file")
    flag = Flag(name = "count-lines", long = "--count-lines", defaultValue = false)
    parseArguments(target = args1, arguments = [argument], flags = [flag]) |> println

    args2 = ["--file", "hello-world", "--count-lines"]
    result = parseArguments(target = args2, arguments = [argument], flags = [flag])

    filepath = get(result, argument.name, nothing)
    if !isnothing(filepath)
        if !isfile(filepath)
            throw("this file $filepath does not exist")
        end
    end
end
```


### complex arguments

`search-tool -r /path/to/search -e ".txt,.docx" -n "keyword"`

```julia
let args = ["-r", "examples.jl", "-e", ".txt,docx", "-n", "keyword"]
    arguments = [
        Argument(String, name = "resource", short = "-r"),
        Argument(String, name = "export", short = "-e"),
        Argument(String, name = "n", short = "-n")
    ]

    parseArguments(target = args, arguments = arguments)
end
```

### for redirecting standard input / standard output

1. `cat input.txt | text-filter --uppercase`
2. `echo "hello world" | text-filter --reverse`

### subcommand

1. `git commit -m "initial commit"`
2. `git branch new-feature`
3. `git invalid-command`

```julia
let args = ["commit", "-m", "\"inital commit\""]
    subcommand = SubCommand(name = "commit")
    argument = Argument(String, name = "message", short = "-m")

    parseArguments(target = args, subcommand = subcommand, arguments = [argument])
end

let args = ["branch", "new-feature"]
    subcommand = SubCommand(name = "branch")
    positioned = Positioned(String, name = "branch-name", index = 2)
    parseArguments(target = args, subcommand = subcommand, positions = [positioned])
end
```

## Feature

- [ ] multiple flags, for example `-abc`
- [ ] handle `program 1 2 3 4`
- [ ] handle `program 1 + 2`
