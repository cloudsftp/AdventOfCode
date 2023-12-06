#![feature(test)]

extern crate test;

use std::{
    fs::File,
    io::{BufRead, Read},
    ops::IndexMut,
    str::{Lines, SplitAsciiWhitespace},
    u32, u64,
};

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

fn run(content: &str) -> u32 {
    let rounds = parse(content);

    rounds.iter().map(number_of_ways_to_win).product()
}

fn number_of_ways_to_win(round: &Round) -> u32 {
    (0..round.time).filter(|t| will_win(t, round)).count() as u32
}

fn will_win(hold_time: &u32, round: &Round) -> bool {
    let speed = hold_time;
    let travel_time = round.time - hold_time;
    let our_dist = travel_time * speed;

    our_dist > round.dist
}

// Parsing

fn parse(content: &str) -> Vec<Round> {
    let mut lines = content.lines();

    let times = parse_line(lines.next().expect("input has two lines"));
    let dists = parse_line(lines.next().expect("input has two lines"));

    times
        .zip(dists)
        .map(|(time, dist)| Round { time, dist })
        .collect()
}

fn parse_line<'a>(line: &'a str) -> Box<dyn Iterator<Item = u32> + 'a> {
    Box::new(line.split_ascii_whitespace().skip(1).map(|p| {
        p.parse::<u32>()
            .expect("parts should consist of digits only")
    }))
}

#[derive(Debug, Clone, Copy)]
struct Round {
    time: u32,
    dist: u32,
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
        assert_eq!(result, 288)
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
