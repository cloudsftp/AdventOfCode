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

    let mut min_cost = (0..field.height)
        .map(|_| vec![usize::max_value(); field.width])
        .collect();

    let res = walk(&mut min_cost, 0, (0, 1), Direction::Right, 3, &field).min(walk(
        &mut min_cost,
        0,
        (1, 0),
        Direction::Down,
        3,
        &field,
    ));

    for row in min_cost {
        for c in row {
            print!("{:4}", c)
        }
        println!()
    }

    res
}

type State = Vec<Vec<usize>>;

fn walk(
    min_cost: &mut State,
    mut cost: usize,
    (x, y): (i64, i64),
    direction: Direction,
    straight: usize,
    field: &Field,
) -> usize {
    if x < 0 || x > field.width as i64 - 1 || y < 0 || y > field.height as i64 - 1 {
        return usize::max_value();
    }

    if straight == 0 {
        return usize::max_value();
    }

    let (xi, yi) = (x as usize, y as usize);

    if min_cost[yi][xi] < cost {
        return usize::max_value();
    }

    min_cost[yi][xi] = cost;

    cost += field.tiles[yi][xi];

    if xi == field.width - 1 && yi == field.height - 1 {
        return cost;
    }

    let mut recurse = |direction, straight| {
        let (x, y) = match direction {
            Direction::Right => (x + 1, y),
            Direction::Down => (x, y + 1),
            Direction::Left => (x - 1, y),
            Direction::Up => (x, y - 1),
        };

        walk(min_cost, cost, (x, y), direction, straight, field)
    };

    recurse(direction.turn_left(), 4)
        .min(recurse(direction, straight - 1))
        .min(recurse(direction.turn_right(), 4))
}

#[derive(Debug)]
struct Field {
    tiles: Vec<Vec<usize>>,
    height: usize,
    width: usize,
}

#[derive(Debug, Clone, Copy)]
enum Direction {
    Right,
    Down,
    Left,
    Up,
}

impl Direction {
    fn turn_left(self) -> Self {
        match self {
            Direction::Right => Direction::Up,
            Direction::Down => Direction::Right,
            Direction::Left => Direction::Down,
            Direction::Up => Direction::Left,
        }
    }

    fn turn_right(self) -> Self {
        match self {
            Direction::Right => Direction::Down,
            Direction::Down => Direction::Left,
            Direction::Left => Direction::Up,
            Direction::Up => Direction::Right,
        }
    }
}

// Parsing

fn parse(content: &str) -> Field {
    let tiles = content
        .lines()
        .map(|line| {
            line.chars()
                .map(|c| c.to_digit(10).unwrap() as usize)
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
        assert_eq!(result, 100)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 7884)
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
