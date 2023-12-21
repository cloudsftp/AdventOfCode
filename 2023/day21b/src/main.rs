use std::{
    collections::{HashMap, HashSet},
    fs::File,
    i32,
    io::Read,
    usize,
};

use clap::Parser;
use iter_tools::Itertools;
use strum::{EnumIter, IntoEnumIterator};

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
    let (layout, start) = parse(content);

    let height = layout.len();
    let width = layout[0].len();

    let mut cache = HashMap::new();
    let mut fields = HashMap::from([((0, 0), Vec::from([(start)]))]);

    for _ in 0..steps {
        let mut new_fields = HashMap::new();
        let mut emmissions = HashMap::new();

        for (position, field) in fields {
            let (field, emmission) = step(&mut cache, field, &layout, height, width);
            new_fields.insert(position, field);
            emmissions.insert(position, emmission);
        }

        apply_emmissions(&mut new_fields, emmissions, height, width);

        fields = new_fields;
    }

    fields.into_iter().map(|(_, field)| field.len()).sum()
}

fn step(
    cache: &mut Cache,
    field: FieldState,
    layout: &Field,
    height: usize,
    width: usize,
) -> (FieldState, FieldEmissions) {
    let entry = cache.get(&field);
    match entry {
        Some(result) => {
            print!(".");
            result.clone()
        }
        None => {
            let result = step_no_cache(&field, layout, height, width);
            cache.insert(field, result.clone());
            result
        }
    }
}

fn step_no_cache(
    field: &FieldState,
    layout: &Field,
    height: usize,
    width: usize,
) -> (FieldState, FieldEmissions) {
    let positions: HashSet<Position> = field
        .into_iter()
        .map(|position| Direction::iter().map(move |direction| direction.apply(*position)))
        .flatten()
        .filter(|(x, y)| {
            *y < 0
                || *y >= height as i32
                || *x < 0
                || *x >= width as i32
                || layout[*y as usize][*x as usize] != Tile::Stone
        })
        .collect();

    let mut emissions: FieldEmissions = Direction::iter()
        .map(|_| HashSet::new())
        .collect_vec()
        .try_into()
        .unwrap();

    let field = positions
        .into_iter()
        .filter_map(|(x, y)| {
            if y < 0 {
                emissions[Direction::Up as usize].insert(x);
                None
            } else if y >= height as i32 {
                emissions[Direction::Down as usize].insert(x);
                None
            } else if x < 0 {
                emissions[Direction::Left as usize].insert(y);
                None
            } else if x >= width as i32 {
                emissions[Direction::Right as usize].insert(y);
                None
            } else {
                Some((x, y))
            }
        })
        .sorted()
        .collect();

    (field, emissions)
}

fn apply_emmissions(
    fields: &mut Fields,
    emmissions: HashMap<Position, FieldEmissions>,
    height: usize,
    width: usize,
) {
    for (position, emmissions) in emmissions {
        for direction in Direction::iter() {
            let positions = emmissions[direction as usize]
                .iter()
                .map(|c| match direction {
                    Direction::Up => (*c, height as i32 - 1),
                    Direction::Right => (0, *c),
                    Direction::Down => (*c, 0),
                    Direction::Left => (width as i32 - 1, *c),
                });

            fields
                .entry(direction.apply(position))
                .and_modify(|field| {
                    for position in positions.clone() {
                        if !field.contains(&position) {
                            field.push(position);
                        }
                    }
                    field.sort();
                })
                .or_insert_with(|| positions.sorted().collect_vec());
        }
    }
}

type Cache = HashMap<FieldState, (FieldState, FieldEmissions)>;
type Fields = HashMap<Position, FieldState>;

type FieldState = Vec<Position>;
type FieldEmissions = [HashSet<i32>; 4];

type Field = Vec<Vec<Tile>>;
#[derive(Debug, Clone, Copy, PartialEq)]
enum Tile {
    Empty,
    Stone,
}

type Position = (i32, i32);

#[derive(Debug, EnumIter, Clone, Copy)]
enum Direction {
    Up,
    Right,
    Down,
    Left,
}

impl Direction {
    fn apply(self, (x, y): Position) -> Position {
        match self {
            Direction::Up => (x, y - 1),
            Direction::Right => (x + 1, y),
            Direction::Down => (x, y + 1),
            Direction::Left => (x - 1, y),
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
                .map(move |(x, _)| (x as i32, y as i32))
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

    use super::*;

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content, 6);
        assert_eq!(result, 16);

        let result = run(&content, 10);
        assert_eq!(result, 50);

        let result = run(&content, 50);
        assert_eq!(result, 1594);

        let result = run(&content, 5000);
        assert_eq!(result, 16733044);
    }

    /*
    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content, 64);
        assert_eq!(result, 807069600)
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        b.iter(|| run(&content, 64));

    }
    */
}
