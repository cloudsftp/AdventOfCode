lista = Int64[]
listb = Int64[]

open("input.big") do file
    for line in readlines(file)
        parts =
            split(line, " ") |>
            parts -> filter(part -> !isempty(part), parts)

        @assert length(parts) == 2

        push!(lista, parse(Int, parts[1]))
        push!(listb, parse(Int, parts[2]))
    end
end

result = map(value -> value * count(other -> value == other, listb), lista) |> sum

println(result)
