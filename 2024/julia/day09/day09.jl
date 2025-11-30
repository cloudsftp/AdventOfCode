function solve(filename)
    spec = open(filename) do file
        lines = readlines(file)
        @assert length(lines) == 1

        collect(lines[1]) |> characters ->
            map(character -> parse(UInt64, character), characters)
    end

    blocks = Tuple{UInt64,UInt64}[]
    spaces = UInt64[]

    i = 1
    while i <= length(spec)
        push!(blocks, (i ÷ 2, spec[i]))

        if i + 1 <= length(spec)
            push!(spaces, spec[i+1])
        end

        i += 2
    end

    i = length(blocks)
    while i > 0 #length(blocks) - 3
        #@show blocks

        try
            moving_block = blocks[i]
            target = find_space(spaces, moving_block, i) # throws if there is no such space

            # build new blocks
            left = blocks[1:target]
            push!(left, moving_block)

            middle = blocks[target+1:i-1]
            right = blocks[i+1:length(blocks)]

            blocks = []
            append!(blocks, left)
            append!(blocks, middle)
            append!(blocks, right)

            # build new spaces
            (_, block_size) = moving_block
            left = spaces[1:target-1]
            push!(left, 0)
            push!(left, spaces[target] - block_size)

            middle = spaces[target+1:i - 2]
            push!(middle, spaces[i-1] + block_size + get(spaces, i, 0))

            right = spaces[i+1:length(spaces)]

            spaces = []
            append!(spaces, left)
            append!(spaces, middle)
            append!(spaces, right)

        catch e
            if e isa ErrorException
                println("Did not find a target for block " * string(blocks[i]))
                i -= 1
            else
                rethrow(e)
            end
        end

    end

    i = 0
    sum = 0
    for ((id, size), space) in zip(blocks, spaces)
        for _ in 1:size
            sum += id * i
            i += 1
        end

        i += space
    end

    println("result: " * string(sum))
end

function find_space(spaces, (_, size), max)
    for (i, space) in enumerate(spaces)
        if i >= max + 1
            break
        end

        if size <= space
            return i
        end
    end

    throw(ErrorException("no space found"))
end

function pretty(blocks, spaces)
    display = ""
    for ((id, size), space) in zip(blocks, spaces)
        for _ in 1:size
            display *= string(id)
        end

        for _ in 1:space
            display *= "."
        end
    end

    println(display)
end

solve("input.big")
