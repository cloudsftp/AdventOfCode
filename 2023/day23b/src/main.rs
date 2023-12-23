use core::panic;
use std::{collections::HashMap, fs::File, io::Read, str::FromStr, usize};

use anyhow::Error;
use clap::Parser;
use iter_tools::Itertools;
use strum::{EnumIter, IntoEnumIterator};

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    file: String,
}

fn main() {
    let args = Args::parse();
    let file = args.file;

    let mut file = File::open(file).unwrap();
    let mut content = String::new();
    file.read_to_string(&mut content).unwrap();

    let result = run(&content);

    println!("{}", result)
}

fn run(content: &str) -> usize {
    let field = Field::from_str(content).unwrap();

    let mut seen = vec![];
    let mut graph = HashMap::new();
    walk_field(
        &field,
        &mut seen,
        &mut graph,
        field.start,
        (field.start.0, field.start.1 + 1),
        Direction::Down,
        0,
    );

    let mut seen = vec![];
    walk_graph(&graph, &field, &mut seen, field.start, 0)
}

fn walk_graph(
    graph: &HashMap<Position, Vec<(Position, usize)>>,
    field: &Field,
    seen: &mut Vec<Position>,
    current: Position,
    length: usize,
) -> usize {
    if current == field.end {
        return length;
    }

    if seen.contains(&current) {
        return 0;
    }

    seen.push(current);

    let res = graph
        .get(&current)
        .unwrap()
        .iter()
        .map(|(position, distance)| {
            let length = length + distance;
            walk_graph(graph, field, seen, *position, length)
        })
        .max()
        .unwrap();

    seen.pop();
    res
}

fn walk_field(
    field: &Field,
    seen: &mut Vec<Position>,
    graph: &mut HashMap<Position, Vec<(Position, usize)>>,
    last_fork: Position,
    current: Position,
    direction: Direction,
    mut length: usize,
) {
    length += 1;

    let mut register = || {
        let edge = (current, length);
        graph
            .entry(last_fork.clone())
            .and_modify(|edges| {
                if !edges.contains(&edge) {
                    edges.push(edge);
                }
            })
            .or_insert_with(|| vec![edge]);

        let edge = (last_fork, length);
        graph
            .entry(current)
            .and_modify(|edges| {
                if !edges.contains(&edge) {
                    edges.push(edge);
                }
            })
            .or_insert_with(|| vec![edge]);
    };

    if current == field.end {
        register();
        return;
    }

    let next_tiles = Direction::iter()
        .filter(|next_dir| !direction.is_opposite(next_dir))
        .filter_map(|direction| {
            direction.apply(current).and_then(|(x, y)| {
                if x >= field.width || y >= field.height || field.tiles[y][x] == Tile::Forest {
                    None
                } else {
                    Some(((x, y), direction))
                }
            })
        })
        .collect_vec();

    assert_ne!(next_tiles.len(), 0, "dead end encountered: {:?}", current);

    if next_tiles.len() == 1 {
        let (position, direction) = *next_tiles.first().unwrap();
        walk_field(field, seen, graph, last_fork, position, direction, length)
    } else {
        register();

        if !seen.contains(&current) {
            seen.push(current.clone());

            for (position, direction) in next_tiles {
                walk_field(field, seen, graph, current.clone(), position, direction, 0)
            }
        }
    }
}

impl Direction {
    fn apply(&self, (x, y): Position) -> Option<Position> {
        match self {
            Direction::Up => y.checked_sub(1).map(|y| (x, y)),
            Direction::Right => Some((x + 1, y)),
            Direction::Down => Some((x, y + 1)),
            Direction::Left => x.checked_sub(1).map(|x| (x, y)),
        }
    }

    fn is_opposite(&self, other: &Self) -> bool {
        *other
            == match self {
                Direction::Up => Direction::Down,
                Direction::Right => Direction::Left,
                Direction::Down => Direction::Up,
                Direction::Left => Direction::Right,
            }
    }
}

type Position = (usize, usize);

#[derive(Debug, Clone, Copy, PartialEq, EnumIter)]
enum Direction {
    Up,
    Right,
    Down,
    Left,
}

#[derive(Debug, PartialEq)]
enum Tile {
    Path,
    Forest,
    Slope(Direction),
}

#[derive(Debug)]
struct Field {
    tiles: Vec<Vec<Tile>>,
    height: usize,
    width: usize,
    start: (usize, usize),
    end: (usize, usize),
}

// Parsing

impl FromStr for Field {
    type Err = Error;

    fn from_str(content: &str) -> Result<Self, Self::Err> {
        let tiles = content
            .lines()
            .map(|line| line.chars().map(Tile::from).collect_vec())
            .collect_vec();

        let height = tiles.len();
        let width = tiles[0].len();

        let index_of_only_path = |index: usize| {
            (
                tiles[index as usize]
                    .iter()
                    .enumerate()
                    .find_map(|(i, t)| if *t == Tile::Path { Some(i) } else { None })
                    .expect("expected row to have at least one path tile"),
                index,
            )
        };

        let start = index_of_only_path(0);
        let end = index_of_only_path(height - 1);

        Ok(Field {
            tiles,
            height,
            width,
            start,
            end,
        })
    }
}

impl From<char> for Tile {
    fn from(value: char) -> Self {
        match value {
            '.' => Tile::Path,
            '#' => Tile::Forest,
            '>' => Tile::Slope(Direction::Right),
            'v' => Tile::Slope(Direction::Down),
            _ => unreachable!("unexpected character in input: {}", value),
        }
    }
}

// testing
#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 154);
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 405)
    }
}
