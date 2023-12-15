#![feature(test)]

extern crate test;

use std::{fs::File, io::Read};

use arr_macro::arr;
use clap::Parser;
use regex::Regex;

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
    let instructions = parse(content);

    let mut boxes = arr![Vec::new(); 256];
    instructions.for_each(|instruction| apply_instruction(&mut boxes, instruction));

    score(boxes)
}

fn apply_instruction(boxes: &mut Boxes, instruction: Instruction) {
    let n = hash(instruction.label);

    match instruction.operation {
        Operation::Add(focal_length) => {
            let index = boxes[n].iter().position(
                |Lens {
                     label,
                     focal_length: _,
                 }| label == instruction.label,
            );

            match index {
                None => boxes[n].push(Lens {
                    label: instruction.label.to_string(),
                    focal_length,
                }),
                Some(index) => boxes[n][index].focal_length = focal_length,
            }
        }
        Operation::Remove => {
            boxes[n] = boxes[n]
                .iter()
                .filter(
                    |Lens {
                         label,
                         focal_length: _,
                     }| label.as_str() != instruction.label,
                )
                .cloned()
                .collect()
        }
    }
}

fn hash(part: &str) -> usize {
    part.bytes().fold(0, |acc, c| {
        let mut acc = acc;

        acc += c as usize;
        acc *= 17;
        acc %= 256;

        acc
    })
}

fn score(boxes: Boxes) -> usize {
    boxes
        .iter()
        .enumerate()
        .map(|(box_index, lenses)| {
            lenses
                .iter()
                .enumerate()
                .map(|(lens_index, lens)| (box_index + 1) * (lens_index + 1) * lens.focal_length)
                .sum::<usize>()
        })
        .sum()
}

type Boxes = [Vec<Lens>; 256];

#[derive(Debug, Clone)]
struct Lens {
    label: String,
    focal_length: usize,
}

#[derive(Debug)]
struct Instruction<'a> {
    label: &'a str,
    operation: Operation,
}
#[derive(Debug)]
enum Operation {
    Remove,
    Add(usize),
}

// Parsing

fn parse(content: &str) -> impl Iterator<Item = Instruction> {
    let regex = Regex::new(r#"([a-zA-Z]+)([=-])(\d)?"#).unwrap();
    content.trim().split(",").map(move |step| {
        let step_parts = regex.captures(step).unwrap();

        let label = step_parts.get(1).unwrap().as_str();
        let operation = match step_parts.get(2).unwrap().as_str() {
            "-" => Operation::Remove,
            "=" => {
                let focal_length = step_parts.get(3).unwrap().as_str().parse().unwrap();
                Operation::Add(focal_length)
            }
            _ => unreachable!(),
        };

        Instruction { label, operation }
    })
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
        assert_eq!(result, 145)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 286278)
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
