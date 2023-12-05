#![feature(test)]

extern crate test;

use std::{fs::File, io::Read, str::SplitAsciiWhitespace, u64};

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
    let (seeds, maps) = parse(content);

    maps.iter()
        .fold(seeds, apply_maps)
        .into_iter()
        .min()
        .expect("resulting vector should have at least one element")
}

fn apply_maps(numbers: Vec<u64>, maps: &Vec<IngredientMap>) -> Vec<u64> {
    numbers
        .into_iter()
        .map(|n| apply_maps_single(n, maps))
        .collect()
}

fn apply_maps_single(number: u64, maps: &Vec<IngredientMap>) -> u64 {
    let map = maps
        .iter()
        .filter(|m| number >= m.src && number < m.src + m.len)
        .next();

    match map {
        None => number,
        Some(m) => m.dest + (number - m.src),
    }
}

// Parsing

fn parse(content: &str) -> (Vec<u64>, Vec<Vec<IngredientMap>>) {
    let mut lines = content.lines();

    let seeds = lines
        .next()
        .expect("input has at least one line")
        .split_ascii_whitespace()
        .skip(1)
        .map(|n| {
            n.parse::<u64>()
                .expect("all parts should consist of digits only")
        })
        .collect();

    lines.next();

    let mut maps = vec![];
    while let Some(_) = lines.next() {
        maps.push(
            (&mut lines)
                .take_while(|l| !l.is_empty())
                .map(|l| l.into())
                .collect(),
        );
    }

    (seeds, maps)
}

#[derive(Debug)]
struct IngredientMap {
    dest: u64,
    src: u64,
    len: u64,
}

impl From<&str> for IngredientMap {
    fn from(value: &str) -> Self {
        let mut parts = value.split_ascii_whitespace();

        IngredientMap {
            dest: parse_part(&mut parts),
            src: parse_part(&mut parts),
            len: parse_part(&mut parts),
        }
    }
}

fn parse_part(parts: &mut SplitAsciiWhitespace) -> u64 {
    parts
        .next()
        .expect("element should exist")
        .parse()
        .expect("element should consist of digits only")
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
        assert_eq!(result, 35)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 323142486)
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
