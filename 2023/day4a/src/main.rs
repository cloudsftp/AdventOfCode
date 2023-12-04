#![feature(test)]

extern crate test;

use std::{fs::File, io::Read, u32};

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

fn run(content: &str) -> u32 {
    content.lines().map(|l| process_line(l)).sum()
}

fn process_line(line: &str) -> u32 {
    let card: Card = line.try_into().unwrap();

    let wins = card.wins();
    if wins > 0 {
        2u32.pow(wins - 1)
    } else {
        0
    }
}

#[derive(Debug)]
struct Card {
    winning: Vec<u32>,
    have: Vec<u32>,
}

impl Card {
    fn wins(&self) -> u32 {
        self.have
            .iter()
            .filter(|n| self.winning.contains(n))
            .count() as u32
    }
}

// Parsing

impl TryFrom<&str> for Card {
    type Error = Error;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        let parts: Vec<&str> = value.split(":").collect();
        if parts.len() != 2 {
            return Err(anyhow!(
                "first split of the card line was not successful: {}",
                value
            ));
        }

        let number_lists: Vec<&str> = parts[1].split("|").collect();
        if number_lists.len() != 2 {
            return Err(anyhow!(
                "second split of the card line was not successful: {}",
                parts[1]
            ));
        }

        let winning = convert_number_list(number_lists[0]);
        let have = convert_number_list(number_lists[1]);

        Ok(Card { winning, have })
    }
}

fn convert_number_list(list: &str) -> Vec<u32> {
    list.trim()
        .split(" ")
        .filter(|n| !n.is_empty())
        .map(|n| n.parse::<u32>().expect("parts should be all digits"))
        .collect()
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
        assert_eq!(result, 13)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 18619)
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
