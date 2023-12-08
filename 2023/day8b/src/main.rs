#![feature(test)]

extern crate test;

use std::{collections::HashMap, fs::File, io::Read, str::FromStr, u32, u64, usize};

use anyhow::{anyhow, Error};
use clap::Parser;
use num::{integer::lcm, Integer};

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
    let (instructions, edges) = parse(content);

    println!("{}", instructions.len());

    edges
        .iter()
        .map(|(node, _)| node)
        .filter(|node| node.ends_with('A'))
        .map(|node| num_of_iterations(node, &instructions, &edges))
        .reduce(|a, b| a.lcm(&b))
        .expect("")
        * instructions.len()
}

fn num_of_iterations(
    node: &String,
    instructions: &Vec<Instruction>,
    edges: &HashMap<String, Edges>,
) -> usize {
    let mut count = 0;
    let mut node = node;

    while !node.ends_with('Z') {
        node = instructions.iter().fold(node, |node, i| {
            let edge = edges.get(node).expect("node should exist");

            match i {
                Instruction::Left => &edge.left,
                Instruction::Right => &edge.right,
            }
        });

        count += 1;
    }

    count
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
    use test::Bencher;

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
