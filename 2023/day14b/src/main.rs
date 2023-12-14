#![feature(test)]

extern crate test;

use std::{
    collections::HashSet,
    fmt::{Display, Write},
    fs::File,
    i64,
    io::Read,
};

use clap::Parser;

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

fn run(content: &str) -> i64 {
    let field = parse(content);

    process(field)
}

fn process(field: Field) -> i64 {
    let mut field = field;

    for i in 0..1_000_000_000 {
        println!("{}", field);

        let new_field = spin_cycle(&field);
        if field == new_field {
            field = new_field;
            break;
        }

        field = new_field;
        if i > 100 {
            panic!()
        }

        if i % 1_000 == 0 {
            println!("---- {}", i)
        }
    }

    field.score()
}

impl Field {
    fn score(self) -> i64 {
        self.rolling
            .iter()
            .map(|(_, y)| self.height as i64 - y)
            .sum()
    }
}

fn spin_cycle(field: &Field) -> Field {
    let field = roll_field(field, Direction::North);
    let field = roll_field(&field, Direction::West);
    let field = roll_field(&field, Direction::South);
    let field = roll_field(&field, Direction::East);
    field
}

fn roll_field(field: &Field, dir: Direction) -> Field {
    let slices = match dir {
        Direction::North => get_cols(field, |y| y),
        Direction::South => get_cols(field, |y| field.height as i64 - y - 1),
        Direction::West => get_rows(field, |x| x),
        Direction::East => get_rows(field, |x| field.width as i64 - x - 1),
    };

    let chunks = slices.into_iter().map(get_rolling_chunks).collect();

    match dir {
        Direction::North => reconstruct_field_from_cols(chunks, |y| y, field),
        Direction::South => {
            reconstruct_field_from_cols(chunks, |y| field.height as i64 - y - 1, field)
        }
        Direction::West => reconstruct_field_from_rows(chunks, |x| x, field),
        Direction::East => {
            reconstruct_field_from_rows(chunks, |x| field.width as i64 - x - 1, field)
        }
    }
}

fn filter_relevant(
    coordinates: &HashSet<(i64, i64)>,
    i: i64,
    filter_proj: fn((i64, i64)) -> i64,
    map_proj: impl Fn((i64, i64)) -> i64,
) -> Vec<i64> {
    coordinates
        .iter()
        .filter_map(|coord| (i == filter_proj(*coord)).then_some(map_proj(*coord)))
        .collect()
}

fn get_cols(field: &Field, proj: impl Fn(i64) -> i64) -> Vec<Slice> {
    (0..field.width as i64)
        .map(|i| {
            let filter_proj = |(x, _)| x;
            let map_proj = |(_, y)| proj(y);
            let steady = filter_relevant(&field.steady, i, filter_proj, map_proj);
            let rolling = filter_relevant(&field.rolling, i, filter_proj, map_proj);
            let len = field.height;

            Slice {
                steady,
                rolling,
                len,
            }
        })
        .collect()
}

fn get_rows(field: &Field, proj: impl Fn(i64) -> i64) -> Vec<Slice> {
    (0..field.width as i64)
        .map(|i| {
            let filter_proj = |(_, y)| y;
            let map_proj = |(x, _)| proj(x);
            let steady = filter_relevant(&field.steady, i, filter_proj, map_proj);
            let rolling = filter_relevant(&field.rolling, i, filter_proj, map_proj);
            let len = field.width;

            Slice {
                steady,
                rolling,
                len,
            }
        })
        .collect()
}

fn get_rolling_chunks(mut slice: Slice) -> Vec<(i64, i64)> {
    slice.steady.sort();

    let mut acc = vec![];
    let mut rolling: HashSet<i64> = slice.rolling.iter().cloned().collect();

    for s in slice.steady.iter().cloned().rev() {
        let relevant: HashSet<i64> = rolling.iter().filter(|r| **r > s).cloned().collect();
        rolling = rolling.difference(&relevant).cloned().collect();

        acc.push((s, relevant.len() as i64))
    }

    if rolling.len() > 0 {
        acc.push((-1, rolling.len() as i64))
    }

    acc
}

fn reconstruct_field_from_cols(
    cols: Vec<Vec<(i64, i64)>>,
    proj: impl Fn(i64) -> i64,
    field: &Field,
) -> Field {
    let steady = field.steady.clone();
    let rolling = cols
        .iter()
        .enumerate()
        .map(|(x, chunks)| {
            chunks
                .iter()
                .map(|(s, n)| (1..=*n).map(|i| (x as i64, proj(s.clone() + i))))
                .flatten()
                .collect::<Vec<_>>()
        })
        .flatten()
        .collect();

    Field {
        steady,
        rolling,
        height: field.height,
        width: field.width,
    }
}

fn reconstruct_field_from_rows(
    cols: Vec<Vec<(i64, i64)>>,
    proj: impl Fn(i64) -> i64,
    field: &Field,
) -> Field {
    let steady = field.steady.clone();
    let rolling = cols
        .iter()
        .enumerate()
        .map(|(y, chunks)| {
            chunks
                .iter()
                .map(|(s, n)| (1..=*n).map(|i| (proj(s.clone() + i), y as i64)))
                .flatten()
                .collect::<Vec<_>>()
        })
        .flatten()
        .collect();

    Field {
        steady,
        rolling,
        height: field.height,
        width: field.width,
    }
}

#[derive(Debug, PartialEq, Eq)]
struct Field {
    steady: HashSet<(i64, i64)>,
    rolling: HashSet<(i64, i64)>,
    height: usize,
    width: usize,
}

#[derive(Debug, PartialEq, Eq)]
struct Slice {
    steady: Vec<i64>,
    rolling: Vec<i64>,
    len: usize,
}

#[derive(Debug)]
enum Direction {
    North,
    West,
    South,
    East,
}

// Parsing

fn parse(content: &str) -> Field {
    let stones = content
        .lines()
        .enumerate()
        .map(|(y, line)| {
            line.chars().enumerate().filter_map(move |(x, c)| match c {
                '#' => Some((false, (x, y))),
                'O' => Some((true, (x, y))),
                '.' => None,
                _ => unreachable!("should not find this character in the input"),
            })
        })
        .flatten()
        .map(|(i, (x, y))| (i, (x as i64, y as i64)));

    let steady = stones
        .clone()
        .filter_map(|(rolling, coordinates)| (!rolling).then_some(coordinates))
        .collect();

    let rolling = stones
        .filter_map(|(rolling, coordinates)| rolling.then_some(coordinates))
        .collect();

    let height = content.lines().count();
    let width = content.lines().next().expect("at least one line").len();

    Field {
        steady,
        rolling,
        height,
        width,
    }
}

// Printing

impl Display for Field {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        for y in 0..self.height as i64 {
            for x in 0..self.width as i64 {
                let steady = self.steady.contains(&(x, y));
                let rolling = self.rolling.contains(&(x, y));

                let c = match (steady, rolling) {
                    (true, false) => '#',
                    (false, true) => 'O',
                    (false, false) => '.',
                    _ => unreachable!("should never happen"),
                };

                f.write_char(c)?
            }
            f.write_char('\n')?
        }

        Ok(())
    }
}

// testing
#[cfg(test)]
mod tests {
    use core::panic;

    use ::test::Bencher;

    use super::*;

    /*
    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 64)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 113486)
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        b.iter(|| run(&content));
    }
    */

    #[test]
    fn test_south() {
        let field = parse(".\nO\n.\nO\n#");
        let field = roll_field(&field, Direction::South);
        assert_eq!(field, parse(".\n.\n.\nO\n#"));
    }
}
