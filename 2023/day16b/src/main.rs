#![feature(test)]

extern crate test;

use std::{fs::File, i64, io::Read, usize};

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

fn run(content: &str) -> usize {
    let field = parse(content);

    (0..field.height)
        .map(|y| ((0, y), Direction::Right))
        .chain((0..field.height).map(|y| ((field.width - 1, y), Direction::Left)))
        .chain((0..field.width).map(|x| ((x, 0), Direction::Down)))
        .chain((0..field.width).map(|x| ((x, field.height - 1), Direction::Left)))
        .map(|((x, y), direction)| {
            let mut light: State = (0..field.height)
                .map(|_| (0..field.width).map(|_| [false; 4]).collect())
                .collect();

            walk(&field, &mut light, (x as i64, y as i64), direction);

            score(&light)
        })
        .max()
        .unwrap()
}

type State = Vec<Vec<[bool; 4]>>;

fn score(light: &State) -> usize {
    light
        .into_iter()
        .map(|row| {
            row.into_iter()
                .map(|l| l.into_iter().any(|w| *w))
                .filter(|row| *row)
                .count()
        })
        .sum()
}

fn walk(field: &Field, state: &mut State, (x, y): (i64, i64), direction: Direction) {
    if x < 0 || x > field.width as i64 - 1 || y < 0 || y > field.height as i64 - 1 {
        return;
    }

    let xi = x as usize;
    let yi = y as usize;

    if state[yi][xi][direction as usize] {
        return;
    }

    state[yi][xi][direction as usize] = true;

    let mut recurse = |direction| {
        let (x, y) = match direction {
            Direction::Right => (x + 1, y),
            Direction::Down => (x, y + 1),
            Direction::Left => (x - 1, y),
            Direction::Up => (x, y - 1),
        };

        walk(field, state, (x, y), direction)
    };

    match field.tiles[yi][xi] {
        Tile::Empty => recurse(direction),
        Tile::MirrorUp => recurse(match direction {
            Direction::Right => Direction::Up,
            Direction::Up => Direction::Right,
            Direction::Down => Direction::Left,
            Direction::Left => Direction::Down,
        }),
        Tile::MirrorDown => recurse(match direction {
            Direction::Right => Direction::Down,
            Direction::Up => Direction::Left,
            Direction::Down => Direction::Right,
            Direction::Left => Direction::Up,
        }),
        Tile::SplitVertical => match direction {
            Direction::Down | Direction::Up => recurse(direction),
            Direction::Right | Direction::Left => {
                recurse(Direction::Up);
                recurse(Direction::Down);
            }
        },
        Tile::SplitHorizontal => match direction {
            Direction::Right | Direction::Left => recurse(direction),
            Direction::Down | Direction::Up => {
                recurse(Direction::Left);
                recurse(Direction::Right)
            }
        },
    };
}

#[derive(Debug)]
struct Field {
    tiles: Vec<Vec<Tile>>,
    height: usize,
    width: usize,
}

#[derive(Debug)]
enum Tile {
    Empty,
    MirrorUp,
    MirrorDown,
    SplitHorizontal,
    SplitVertical,
}

#[derive(Debug, Clone, Copy)]
enum Direction {
    Right,
    Down,
    Left,
    Up,
}

// Parsing

fn parse(content: &str) -> Field {
    let tiles = content
        .lines()
        .map(|line| {
            line.chars()
                .map(|c| match c {
                    '.' => Tile::Empty,
                    '/' => Tile::MirrorUp,
                    '\\' => Tile::MirrorDown,
                    '-' => Tile::SplitHorizontal,
                    '|' => Tile::SplitVertical,
                    _ => unreachable!(),
                })
                .collect()
        })
        .collect();

    let height = content.lines().count();
    let width = content.lines().next().unwrap().len();

    Field {
        tiles,
        height,
        width,
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

        let result = run(&content);
        assert_eq!(result, 51)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 8185)
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        b.iter(|| run(&content));
    }
}
