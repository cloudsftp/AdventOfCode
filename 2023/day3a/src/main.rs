#![feature(test)]

extern crate test;

use std::{fs::File, io::Read, u32};

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

fn run(content: &str) -> u32 {
    let sym_regex = Regex::new("[^\\.\\d]").unwrap();
    let symbol_positions = get_symbol_positions(content, &sym_regex);

    let num_regex = Regex::new("\\d+").unwrap();
    content
        .lines()
        .enumerate()
        .map(|(i, l)| process_line(i, l, &num_regex, &symbol_positions))
        .sum()
}

fn get_symbol_positions(content: &str, sym_regex: &Regex) -> Vec<Vec<usize>> {
    let mut positions = vec![];

    for line in content.lines() {
        let mut line_positions = vec![];

        for sym_match in sym_regex.find_iter(line) {
            line_positions.push(sym_match.start());
        }

        positions.push(line_positions);
    }

    positions
}

fn process_line(
    i: usize,
    line: &str,
    num_regex: &Regex,
    symbol_positions: &Vec<Vec<usize>>,
) -> u32 {
    let mut positions = symbol_positions[i].clone();
    if i > 0 {
        positions.extend_from_slice(&symbol_positions[i - 1])
    }
    if i < symbol_positions.len() - 1 {
        positions.extend_from_slice(&symbol_positions[i + 1])
    }

    num_regex
        .find_iter(line)
        .filter(|m| {
            positions
                .iter()
                .any(|p| if m.start() == 0 { true } else { *p >= m.start() - 1 } && *p <= m.end())
        })
        .map(|m| m.as_str().parse::<u32>().expect("match is only digits"))
        .sum()
}

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
        assert_eq!(result, 4361)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 514969)
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
