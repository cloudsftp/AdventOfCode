#![feature(test)]

extern crate test;

use std::{collections::HashMap, fs::File, io::Read, str::FromStr};

use anyhow::{anyhow, Error};
use clap::{Parser, ValueEnum};

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
    let mut curr_node = 0;
    while curr_node != edges.len() - 1 {
        let edges = edges
            .get(curr_node)
            .expect("curr_node should always exist in the mapping");

        curr_node = match instructions[count % instructions.len()] {
            Instruction::Left => edges.left,
            Instruction::Right => edges.right,
        };

        count += 1;
    }

    count as u64
}

fn parse(content: &str) -> (Vec<Instruction>, Vec<Edges>) {
    let mut lines = content.lines();

    let instruction_line = lines.next().expect("input has at least one line");
    let instructions = instruction_line.chars().map(Instruction::from).collect();

    lines.next();

    let mut edges: Vec<(&str, &str)> = lines
        .map(|l| {
            let mut parts = l.split(" = ");

            let start_part = parts.next().expect("should have two parts");
            let edges = parts.next().expect("should have two parts");

            (start_part, edges)
        })
        .collect();
    edges.sort_by_key(|t| t.0);

    let index_of_node: HashMap<&str, usize> = edges
        .iter()
        .enumerate()
        .map(|(i, (node, _))| (*node, i))
        .collect();

    let edges = edges
        .into_iter()
        .map(|(_, edge_part)| Edges::parse_from_str(edge_part, &index_of_node))
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
    left: usize,
    right: usize,
}

impl Edges {
    fn parse_from_str(s: &str, index_of_node: &HashMap<&str, usize>) -> Self {
        let left = *index_of_node.get(&s[1..4]).expect("node should exist");
        let right = *index_of_node.get(&s[6..9]).expect("node should exist");

        Edges { left, right }
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
