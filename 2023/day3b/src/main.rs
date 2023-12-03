#![feature(test)]

extern crate test;

use std::{fs::File, io::Read, u32};

use clap::Parser;
use regex::{Match, Regex};

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
    let num_regex = Regex::new("\\d+").unwrap();
    let number_matches = get_number_positions(content, &num_regex);

    content
        .lines()
        .enumerate()
        .map(|(i, l)| process_line(i, l, &number_matches))
        .sum()
}

fn get_number_positions<'a>(content: &'a str, num_regex: &'a Regex) -> Vec<Vec<Match<'a>>> {
    let mut positions = vec![];

    for line in content.lines() {
        let mut line_positions = vec![];

        for num_match in num_regex.find_iter(line) {
            line_positions.push(num_match);
        }

        positions.push(line_positions);
    }

    positions
}

fn process_line(i: usize, line: &str, number_matches: &Vec<Vec<Match>>) -> u32 {
    let mut num_matches = number_matches[i].clone();
    if i > 0 {
        num_matches.extend_from_slice(&number_matches[i - 1])
    }
    if i < number_matches.len() - 1 {
        num_matches.extend_from_slice(&number_matches[i + 1])
    }

    line.chars()
        .enumerate()
        .filter(|(_, c)| *c == '*')
        .filter_map(|(i, _)| {
            let adj_num_matches : Vec<&Match<'_>> = num_matches.iter()
            .filter(|m| if m.start() == 0 { true } else { i >= m.start() - 1 } && i <= m.end()).collect();

            match adj_num_matches.len() {
                2 => {
                    let a = adj_num_matches[0].as_str().parse::<u32>().expect("match is only digits");
                    let b = adj_num_matches[1].as_str().parse::<u32>().expect("match is only digits");

                    Some(a * b)
                },
                _ => None,
                
            }
        })
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
        assert_eq!(result, 467835)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 78915902)
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
