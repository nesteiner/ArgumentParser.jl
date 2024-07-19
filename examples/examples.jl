using ArgumentParser

let args = ["-v"]
    flag = Flag(name = "verbose", short = "-v", long = "--verbose", defaultValue = false)
    parseArguments(target = args, flags = [flag])
end

let args = ["-S", "package"]
    subcommand = SubCommand(name = "-S")
    package = Positioned(String, name = "package-name", index = 2)
    result = parseArguments(target = args, subcommand = subcommand, positions = [package])
    println(result)
end

let args = ["-S", "-s", "foo", "-i", "bar"]
    subcommand = SubCommand(name = "-S")
    arguments = [
        Argument(String, name = "search", short = "-s"),
        Argument(String, name = "info", short = "-i")
    ]

    parseArguments(target = args, subcommand = subcommand, arguments = arguments)
end

# 使用选项和值
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

# throw an error
# "config-editor --set"
let args = ["--set"]
    subcommand = SubCommand(name = "--set")
    argument = Argument(String, name = "username")
    parseArguments(target = args, subcommand = subcommand, arguments = [argument])
end

# operation on file
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

# complex arguments
let args = ["-r", "examples.jl", "-e", ".txt,docx", "-n", "keyword"]
    arguments = [
        Argument(String, name = "resource", short = "-r"),
        Argument(String, name = "export", short = "-e"),
        Argument(String, name = "n", short = "-n")
    ]

    parseArguments(target = args, arguments = arguments)
end

# subcommand
# 1. "git commmit -m "initail commit"
# 2. "git branch new-feature"
# 3. "git invalid-commmand"

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