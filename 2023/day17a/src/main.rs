#![feature(test)]

extern crate test;

use std::{collections::BinaryHeap, fs::File, i64, io::Read, usize};

use clap::Parser;
use iter_tools::Itertools;

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

    let mut min_cost: Vec<Vec<usize>> = (0..field.height)
        .map(|_| vec![usize::max_value(); field.width])
        .collect();

    let mut frontier: BinaryHeap<ActionItem> = BinaryHeap::new();

    frontier.push(ActionItem {
        cost: 0,
        position: (0, 1),
        direction: Direction::Right,
        straight: 3,
    });
    frontier.push(ActionItem {
        cost: 0,
        position: (1, 0),
        direction: Direction::Right,
        straight: 3,
    });

    let res = loop {
        let item = frontier.pop().unwrap();

        // dbg!(&item);

        let (x, y) = item.position;
        if x < 0 || x > field.width as i64 - 1 || y < 0 || y > field.height as i64 - 1 {
            continue;
        }

        if item.straight == 0 {
            continue;
        }

        let (xi, yi) = (x as usize, y as usize);
        let cost = item.cost + field.tiles[yi][xi];

        if min_cost[yi][xi] <= cost {
            continue;
        }
        min_cost[yi][xi] = cost;

        /*
        for row in &min_cost {
            for c in row {
                if c < &usize::max_value() {
                    print!("{:4}", c)
                } else {
                    print!("  --")
                }
            }
            println!()
        }
        */

        if xi == field.width - 1 && yi == field.height - 1 {
            break cost;
        }

        let mut walk = |direction, straight| {
            let (x, y) = match direction {
                Direction::Right => (x + 1, y),
                Direction::Down => (x, y + 1),
                Direction::Left => (x - 1, y),
                Direction::Up => (x, y - 1),
            };

            let item = ActionItem {
                cost,
                direction,
                position: (x, y),
                straight,
            };

            frontier.push(item);
        };

        walk(item.direction, item.straight - 1);
        walk(item.direction.turn_left(), 3);
        walk(item.direction.turn_right(), 3);
    };

    res
}

#[derive(Debug, Eq)]
struct ActionItem {
    cost: usize,
    position: (i64, i64),
    direction: Direction,
    straight: usize,
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
    tiles: Vec<Vec<usize>>,
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
        assert_eq!(result, 102)
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
