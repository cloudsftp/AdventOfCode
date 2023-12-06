#![feature(test)]

extern crate test;

use std::{fs::File, io::Read};

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
    let round = parse(content);

    number_of_ways_to_win(&round)
}

fn number_of_ways_to_win(round: &Round) -> u64 {
    (0..round.time).filter(|t| will_win(t, round)).count() as u64
}

fn will_win(hold_time: &u64, round: &Round) -> bool {
    let speed = hold_time;
    let travel_time = round.time - hold_time;
    let our_dist = travel_time * speed;

    our_dist > round.dist
}

// Parsing

fn parse(content: &str) -> Round {
    let mut lines = content.lines();

    let time = parse_line(lines.next().expect("input has two lines"));
    let dist = parse_line(lines.next().expect("input has two lines"));

    Round { time, dist }
}

fn parse_line(line: &str) -> u64 {
    line.split_ascii_whitespace()
        .skip(1)
        .collect::<String>()
        .parse()
        .expect("should consist of digits only")
}

#[derive(Debug, Clone, Copy)]
struct Round {
    time: u64,
    dist: u64,
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
        assert_eq!(result, 71503)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 49240091)
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
