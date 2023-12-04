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
    let cards: Vec<Card> = content.lines().map(|l| l.try_into().unwrap()).collect();
    let mut num_of_cards = vec![1; cards.len()];

    for (i, card) in cards.iter().enumerate() {
        let wins = card.wins();
        for j in i + 1..i + 1 + wins {
            num_of_cards[j] += num_of_cards[i];
        }
    }

    num_of_cards.iter().sum()
}

#[derive(Debug)]
struct Card {
    winning: Vec<u32>,
    have: Vec<u32>,
}

impl Card {
    fn wins(&self) -> usize {
        self.have
            .iter()
            .filter(|n| self.winning.contains(n))
            .count()
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
        assert_eq!(result, 30)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 8063216)
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
