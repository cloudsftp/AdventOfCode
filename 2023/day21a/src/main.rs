#![feature(test)]

extern crate test;

use std::{collections::HashSet, fs::File, io::Read, usize};

use clap::Parser;
use iter_tools::Itertools;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    #[arg(short, long)]
    file: String,
    #[arg(short, long)]
    steps: usize,
}

fn main() {
    let args = Args::parse();
    let file = args.file;

    let mut file = File::open(file).unwrap();
    let mut content = String::new();
    file.read_to_string(&mut content).unwrap();

    let result = run(&content, args.steps);

    println!("{}", result)
}

fn run(content: &str, steps: usize) -> usize {
    let (field, start) = parse(content);

    let mut end = HashSet::new();
    let mut seen = (0..=steps).map(|_| HashSet::new()).collect_vec();
    walk(&field, &mut end, &mut seen, start, steps);
    end.len()
}

fn walk(
    field: &Field,
    end: &mut HashSet<Position>,
    seen: &mut Vec<HashSet<Position>>,
    (x, y): Position,
    steps: usize,
) {
    if y >= field.len()
        || x >= field[0].len()
        || field[y][x] == Tile::Stone
        || seen[steps].contains(&(x, y))
    {
        return;
    }

    if steps == 0 {
        end.insert((x, y));
        return;
    }

    seen[steps].insert((x, y));
    let steps = steps - 1;

    [
        Directions::Up,
        Directions::Right,
        Directions::Down,
        Directions::Left,
    ]
    .into_iter()
    .for_each(|direction| {
        direction
            .apply((x, y))
            .map(|position| walk(field, end, seen, position, steps));
    })
}

type Field = Vec<Vec<Tile>>;
#[derive(Debug, PartialEq)]
enum Tile {
    Empty,
    Stone,
}

type Position = (usize, usize);

#[derive(Debug)]
enum Directions {
    Up,
    Right,
    Down,
    Left,
}

impl Directions {
    fn apply(self, (x, y): Position) -> Option<Position> {
        match self {
            Directions::Up => y.checked_sub(1).map(|y| (x, y)),
            Directions::Right => Some((x + 1, y)),
            Directions::Down => Some((x, y + 1)),
            Directions::Left => x.checked_sub(1).map(|x| (x, y)),
        }
    }
}

// Parsing

fn parse(content: &str) -> (Field, Position) {
    let field = content
        .lines()
        .map(|line| line.chars().map(Tile::from).collect_vec())
        .collect_vec();

    let start = content
        .lines()
        .enumerate()
        .map(|(y, line)| {
            line.chars()
                .enumerate()
                .filter(|(_, c)| *c == 'S')
                .map(move |(x, _)| (x, y))
        })
        .flatten()
        .next()
        .unwrap();

    (field, start)
}

impl From<char> for Tile {
    fn from(value: char) -> Self {
        match value {
            '#' => Tile::Stone,
            '.' | 'S' => Tile::Empty,
            _ => unreachable!(),
        }
    }
}

// testing
#[cfg(test)]
mod tests {
    use ::test::Bencher;

    use super::*;

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content, 6);
        assert_eq!(result, 16)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content, 64);
        assert_eq!(result, 3594)
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        b.iter(|| run(&content, 64));
    }
}
