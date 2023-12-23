use std::{collections::binary_heap::Iter, fs::File, i32, io::Read, iter, str::FromStr, usize};

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
    walk(&field, &mut seen, field.start, Direction::Down, 0)
}

fn walk(
    field: &Field,
    seen: &mut Vec<Position>,
    (x, y): Position,
    direction: Direction,
    mut length: usize,
) -> usize {
    if x < 0 || x >= field.width || y < 0 || y >= field.height || seen.contains(&(x, y)) {
        return 0;
    }

    let tile = &field.tiles[y as usize][x as usize];
    match tile {
        Tile::Forest => return 0,
        _ => (),
    }

    if (x, y) == field.end {
        return length;
    }

    length += 1;
    seen.push((x, y));

    let next_directions = match tile {
        Tile::Slope(slope) => iter::once(*slope).collect_vec(),
        _ => Direction::iter().collect_vec(),
    };
    let res = next_directions
        .into_iter()
        .map(|direction| {
            let position = direction.apply((x, y));
            walk(field, seen, position, direction, length)
        })
        .max()
        .unwrap();

    seen.pop();
    res
}

impl Direction {
    fn apply(&self, (x, y): Position) -> Position {
        match self {
            Direction::Up => (x, y - 1),
            Direction::Right => (x + 1, y),
            Direction::Down => (x, y + 1),
            Direction::Left => (x - 1, y),
        }
    }
}

type Position = (i32, i32);

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
    height: i32,
    width: i32,
    start: (i32, i32),
    end: (i32, i32),
}

// Parsing

impl FromStr for Field {
    type Err = Error;

    fn from_str(content: &str) -> Result<Self, Self::Err> {
        let tiles = content
            .lines()
            .map(|line| line.chars().map(Tile::from).collect_vec())
            .collect_vec();

        let height = tiles.len() as i32;
        let width = tiles[0].len() as i32;

        let index_of_only_path = |index: i32| {
            (
                tiles[index as usize]
                    .iter()
                    .enumerate()
                    .find_map(|(i, t)| {
                        if *t == Tile::Path {
                            Some(i as i32)
                        } else {
                            None
                        }
                    })
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
        assert_eq!(result, 94);
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
