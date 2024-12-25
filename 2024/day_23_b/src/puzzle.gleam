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

  let nodes =
    edges
    |> list.fold(set.new(), fn(nodes, edge) {
      nodes
      |> set.insert(edge.src)
      |> set.insert(edge.tgt)
    })
    |> set.to_list

  io.debug(1)
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
