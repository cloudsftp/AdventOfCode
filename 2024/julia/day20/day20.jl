using DataStructures

function parse_input(filename)
    open(filename) do file
        blocks = Set()
        start = (0, 0)
        endp = (0, 0)

        lines = readlines(file)
        height = length(lines)
        width = length(lines[1])

        for (i, line) in enumerate(lines)
            for (j, character) in enumerate(line)
                if character == '#'
                    push!(blocks, (i, j))
                elseif character == 'S'
                    start = (i, j)
                elseif character == 'E'
                    endp = (i, j)
                end
            end
        end
        (blocks, start, endp, height, width)
    end
end

function solve(filename)
    (blocks, start, endp, height, width) = parse_input(filename)

    walk(blocks, start, endp, height, width)
end

function walk(blocks, start, endp, height, width)
    work = BinaryHeap(Base.By(((_, _, dista), (_, _, distb)) -> dist), [(start, false, 0)])
    visited = Set()
    while position != endp
        (position, cheated, distance) = first(work)

        push!(visited, position)

        one_step = filter(
            next -> !(next in blocks) && !(next in visited),
            step(position, height, width),
        )

        @assert length(one_step) == 1

        push!(work, (first(one_step), cheated, distance + 1))


        if !cheated
            append!(work, map(
                position -> (position, true, distance + 2),
                filter(
                    next -> !(next in blocks) && !(next in visited),
                    map(
                        first_step -> step(first_step, height, width),
                        step(position, height, width),
                    )
                )
            )
            )
        end

    end

    distance
end

function step((i, j), height, width)
    filter(
        position -> begin
            true
            #(i, j) = position
            #1 <= i && i <= height && 1 <= j && j <= width
        end,
        [(i + 1, j), (i, j + 1), (i - 1, j), (i, j - 1)],
    )
end


@show solve("input.small")
