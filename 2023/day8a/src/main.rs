#![feature(test)]

extern crate test;

use std::{collections::HashMap, fs::File, io::Read, str::FromStr};

use anyhow::{anyhow, Error};
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

fn run(content: &str) -> u64 {
    let (instructions, edges) = parse(content);

    let mut count = 0;
    let mut curr_node = String::from("AAA");
    let end_node = String::from("ZZZ");
    while curr_node != end_node {
        let edges = edges
            .get(&curr_node)
            .expect("curr_node should always exist in the mapping");

        curr_node = match instructions[count % instructions.len()] {
            Instruction::Left => edges.left.clone(),
            Instruction::Right => edges.right.clone(),
        };

        count += 1;
    }

    count as u64
}

fn parse(content: &str) -> (Vec<Instruction>, HashMap<String, Edges>) {
    let mut lines = content.lines();

    let instruction_line = lines.next().expect("input has at least one line");
    let instructions = instruction_line.chars().map(Instruction::from).collect();

    lines.next();

    let edges = lines
        .map(|l| {
            let mut parts = l.split(" = ");

            let start_part = parts.next().expect("should have two parts").to_string();
            let edges = parts
                .next()
                .expect("should have two parts")
                .parse()
                .expect("edges should be parsable");

            (start_part, edges)
        })
        .collect();

    (instructions, edges)
}

#[derive(Debug)]
enum Instruction {
    Left,
    Right,
}

impl From<char> for Instruction {
    fn from(value: char) -> Self {
        match value {
            'L' => Instruction::Left,
            'R' => Instruction::Right,
            _ => panic!("Unknown instruction: '{}'", value),
        }
    }
}

#[derive(Debug)]
struct Edges {
    left: String,
    right: String,
}

impl FromStr for Edges {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Edges {
            left: s[1..4].to_string(),
            right: s[6..9].to_string(),
        })
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
        assert_eq!(result, 6)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 18727)
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
