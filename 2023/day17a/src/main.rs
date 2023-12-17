#![feature(test)]

extern crate test;

use std::{collections::BinaryHeap, fs::File, io::Read, usize};

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

    let mut min_cost: Vec<usize> = (0..field.height)
        .map(|_| {
            (0..field.width)
                .map(|_| (0..4).map(|_| usize::max_value()))
                .flatten()
        })
        .flatten()
        .collect();

    for direction in [
        Direction::Right,
        Direction::Down,
        Direction::Left,
        Direction::Up,
    ] {
        min_cost[direction as usize] = 0;
    }

    let mut frontier: BinaryHeap<ActionItem> = BinaryHeap::new();

    frontier.push(ActionItem {
        cost: 0,
        position: (0, 0),
        direction: Direction::Right,
    });
    frontier.push(ActionItem {
        cost: 0,
        position: (0, 0),
        direction: Direction::Down,
    });

    'outer: while let Some(ActionItem {
        mut cost,
        position: (mut x, mut y),
        direction,
    }) = frontier.pop()
    {
        //dbg!(cost, x, y, direction);

        if x == field.width - 1 && y == field.height - 1 {
            return cost;
        }

        for _ in 0..3 {
            let mut step = |direction: Direction| {
                let Some((x, y)) = direction.apply((x, y)) else {
                    return;
                };
                if x >= field.width || y >= field.height {
                    return;
                }

                let cost = cost + field.tiles[y * field.width + x];

                let min_cost_index = (y * field.width + x) * 4 + direction as usize;
                if min_cost[min_cost_index] <= cost {
                    return;
                }

                min_cost[min_cost_index] = cost;
                frontier.push(ActionItem {
                    cost,
                    position: (x, y),
                    direction,
                })
            };

            step(direction.turn_left());
            step(direction.turn_right());

            let Some(next) = direction.apply((x, y)) else {
                continue 'outer;
            };
            (x, y) = next;
            if x >= field.width || y >= field.height {
                continue 'outer;
            }

            cost += field.tiles[y * field.width + x];
        }
    }

    usize::max_value()
}

#[derive(Debug, Eq)]
struct ActionItem {
    cost: usize,
    position: (usize, usize),
    direction: Direction,
}

impl PartialEq for ActionItem {
    fn eq(&self, other: &Self) -> bool {
        self.cost.eq(&other.cost)
    }
}

impl PartialOrd for ActionItem {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        other.cost.partial_cmp(&self.cost)
    }
}

impl Ord for ActionItem {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        other.cost.cmp(&self.cost)
    }
}

#[derive(Debug)]
struct Field {
    tiles: Vec<usize>,
    height: usize,
    width: usize,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
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

    fn apply(self, (x, y): (usize, usize)) -> Option<(usize, usize)> {
        match self {
            Direction::Right => Some((x + 1, y)),
            Direction::Down => Some((x, y + 1)),
            Direction::Left => x.checked_sub(1).and_then(|x| Some((x, y))),
            Direction::Up => y.checked_sub(1).and_then(|y| Some((x, y))),
        }
    }
}

// Parsing

fn parse(content: &str) -> Field {
    let tiles = content
        .lines()
        .map(|line| line.chars().map(|c| c.to_digit(10).unwrap() as usize))
        .flatten()
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
        assert_eq!(result, 102)
    }

    /*
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
    */
}
