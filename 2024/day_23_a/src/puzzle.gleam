import gleam/dict
import gleam/io
import gleam/list
import gleam/option
import gleam/set
import gleam/string
import simplifile

type Connection {
  Edge(src: String, tgt: String)
}

pub fn main() {
  let assert Ok(content) = simplifile.read("input")
  let edges = parse(content)

  let incidences = collect_incidences(edges)
  let nodes = incidences |> dict.keys()
  let cliques3 = find_cliques3(nodes, incidences)

  cliques3
  |> set.each(fn(clique) {
    let assert [a, b, c] =
      clique
      |> set.to_list

    io.println(a <> " - " <> b <> " - " <> c)
  })

  let result =
    cliques3
    |> set.to_list
    |> list.count(fn(clique) {
      let assert [a, b, c] =
        clique
        |> set.to_list

      a |> string.starts_with("t")
      || b |> string.starts_with("t")
      || c |> string.starts_with("t")
    })

  io.debug(result)
}

fn find_cliques3(
  nodes: List(String),
  incidences: dict.Dict(String, set.Set(String)),
) -> set.Set(set.Set(String)) {
  nodes
  |> list.fold(set.new(), fn(cliques, node) {
    node
    |> solo_find_cliques3(incidences, cliques)
  })
}

fn solo_find_cliques3(
  node: String,
  incidences: dict.Dict(String, set.Set(String)),
  cliques: set.Set(set.Set(String)),
) -> set.Set(set.Set(String)) {
  let assert Ok(connected) =
    incidences
    |> dict.get(node)

  connected
  |> set.fold(cliques, fn(cliques, second) {
    let assert Ok(connected2) =
      incidences
      |> dict.get(second)

    connected
    |> set.intersection(connected2)
    |> set.fold(cliques, fn(cliques, third) {
      cliques
      |> set.insert(
        set.new()
        |> set.insert(node)
        |> set.insert(second)
        |> set.insert(third),
      )
    })
  })
}

fn collect_incidences(
  edges: List(Connection),
) -> dict.Dict(String, set.Set(String)) {
  edges
  |> list.fold(dict.new(), fn(incidences, edge) {
    incidences
    |> add_incidence(edge.src, edge.tgt)
    |> add_incidence(edge.tgt, edge.src)
  })
}

fn add_incidence(
  incidences: dict.Dict(String, set.Set(String)),
  src: String,
  tgt: String,
) -> dict.Dict(String, set.Set(String)) {
  incidences
  |> dict.upsert(src, fn(targets) {
    case targets {
      option.None -> set.new()
      option.Some(targets) -> targets
    }
    |> set.insert(tgt)
  })
}

fn parse(content: String) -> List(Connection) {
  content
  |> string.split(on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
  |> list.map(fn(line) {
    let assert Ok(#(src, tgt)) = string.split_once(line, on: "-")
    Edge(src, tgt)
  })
}
