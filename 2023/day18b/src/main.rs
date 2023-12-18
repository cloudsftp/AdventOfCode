#![feature(test)]

extern crate test;

use std::{fs::File, i32, i64, io::Read, usize};

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

fn run(content: &str) -> i64 {
    let instructions = parse(content);

    let mut corners = vec![(0, 0)];
    calculate_corners(&mut corners, &instructions);

    let mut a: i64 = 0;

    for i in 0..corners.len() {
        let j = (i + 1) % corners.len();
        a += corners[i].0 * corners[j].1;
        a -= corners[i].1 * corners[j].0;
    }

    (a + instructions.into_iter().map(|i| i.length).sum::<i64>()) / 2 + 1
}

fn calculate_corners(corners: &mut Vec<(i64, i64)>, instructions: &[Instruction]) {
    if instructions.is_empty() {
        return;
    }

    let (mut x, mut y) = corners.last().unwrap();
    let instruction = instructions.first().unwrap();
    match instruction.direction {
        Direction::Right => x += instruction.length,
        Direction::Down => y += instruction.length,
        Direction::Left => x -= instruction.length,
        Direction::Up => y -= instruction.length,
    }
    corners.push((x, y));

    calculate_corners(corners, &instructions[1..])
}

#[derive(Debug)]
struct Instruction {
    direction: Direction,
    length: i64,
}

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
enum Direction {
    Right,
    Down,
    Left,
    Up,
}

// Parsing

fn parse(content: &str) -> Vec<Instruction> {
    content.lines().map(Instruction::from).collect()
}

impl From<&str> for Instruction {
    fn from(line: &str) -> Self {
        let part = line.split_ascii_whitespace().nth(2).unwrap();

        let direction = match &part[7..8] {
            "3" => Direction::Up,
            "0" => Direction::Right,
            "1" => Direction::Down,
            "2" => Direction::Left,
            _ => unreachable!(),
        };

        let length = i64::from_str_radix(&part[2..7], 16).unwrap();

        Self { direction, length }
    }
}

// testing
#[cfg(test)]
mod tests {
    use std::i64;

    use ::test::Bencher;

    use super::*;

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 952408144115 as i64)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 250022188522074)
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
