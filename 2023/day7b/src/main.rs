#![feature(test)]

extern crate test;

use std::{
    cmp::Ordering::Equal,
    collections::HashSet,
    fs::File,
    io::{BufRead, Read},
    str::{FromStr, Lines, SplitAsciiWhitespace},
    u32, u64,
};

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

fn run(content: &str) -> u64 {
    let mut hands = parse(content);
    hands.sort();

    hands
        .iter()
        .enumerate()
        .map(|(i, h)| (i as u64 + 1) * h.bid)
        .sum()
}

fn parse(content: &str) -> Vec<Hand> {
    content
        .lines()
        .map(Hand::from_str)
        .collect::<Result<_, _>>()
        .expect("error while parsing input")
}

#[derive(Debug)]
struct Hand {
    cards: Vec<Card>,
    bid: u64,
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
enum HandType {
    HighestCard,
    Pair,
    TwoPair,
    Triplet,
    FullHouse,
    Four,
    Five,
}

impl Eq for Hand {}
impl PartialEq for Hand {
    fn eq(&self, other: &Self) -> bool {
        self.compare(other) == Equal
    }
}

impl Ord for Hand {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.compare(other)
    }
}
impl PartialOrd for Hand {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.compare(other))
    }
}

impl Hand {
    fn compare(&self, other: &Self) -> std::cmp::Ordering {
        let self_hand_type = self.hand_type();
        let other_hand_type = other.hand_type();

        if self_hand_type == other_hand_type {
            self.cards.iter().cmp(&other.cards)
        } else {
            self_hand_type.cmp(&other_hand_type)
        }
    }

    fn hand_type(&self) -> HandType {
        let same: HashSet<(usize, &Card)> = self
            .cards
            .iter()
            .filter(|c| **c != Card::Jack)
            .map(|c| (self.cards.iter().filter(|o| c == *o).count(), c))
            .collect();
        let mut same: Vec<(usize, &Card)> = same.into_iter().collect();
        same.sort_by_key(|t| t.0);
        same.reverse();

        let num_jokers = self.cards.iter().filter(|c| *c == &Card::Jack).count();
        match same.get(0).map(|t| t.0 + num_jokers).unwrap_or(5) {
            5 => HandType::Five,
            4 => HandType::Four,
            3 => {
                if same.get(1).expect("should always exist").0 == 2 {
                    HandType::FullHouse
                } else {
                    HandType::Triplet
                }
            }
            2 => {
                if same.get(1).expect("should always exist").0 == 2 {
                    HandType::TwoPair
                } else {
                    HandType::Pair
                }
            }
            _ => HandType::HighestCard,
        }
    }
}

impl FromStr for Hand {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut parts = s.split_ascii_whitespace();

        let hand_part = parts.next().ok_or(anyhow!("line should have two parts"))?;
        let cards: Vec<Card> = hand_part
            .chars()
            .take(5)
            .map(|c| Card::try_from(c))
            .collect::<Result<_, _>>()
            .expect("problen while parsing hand");

        let bid_part = parts.next().ok_or(anyhow!("line should have two parts"))?;
        let bid = bid_part.parse()?;

        Ok(Hand { cards, bid })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
enum Card {
    Jack,
    Number(u8),
    Queen,
    King,
    Ass,
}

impl TryFrom<char> for Card {
    type Error = Error;

    fn try_from(value: char) -> Result<Self, Self::Error> {
        Ok(match value {
            'A' => Self::Ass,
            'K' => Self::King,
            'Q' => Self::Queen,
            'J' => Self::Jack,
            'T' => Self::Number(10),
            c => {
                let num = String::from(c).parse()?;
                Self::Number(num)
            }
        })
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
        assert_eq!(result, 5905)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 246436046)
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        b.iter(|| run(&content));
    }

    #[test]
    fn test_five() {
        let h = Hand {
            cards: vec![Card::Ass, Card::Ass, Card::Ass, Card::Ass, Card::Ass],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Five);
        let h = Hand {
            cards: vec![Card::Ass, Card::Ass, Card::Ass, Card::Ass, Card::Jack],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Five);
        let h = Hand {
            cards: vec![Card::Ass, Card::Ass, Card::Ass, Card::Jack, Card::Jack],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Five);
        let h = Hand {
            cards: vec![Card::Ass, Card::Ass, Card::Jack, Card::Jack, Card::Jack],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Five);
        let h = Hand {
            cards: vec![Card::Ass, Card::Jack, Card::Jack, Card::Jack, Card::Jack],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Five);
    }

    #[test]
    fn test_four() {
        let h = Hand {
            cards: vec![Card::Ass, Card::Ass, Card::Ass, Card::Ass, Card::Number(2)],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Four);
        let h = Hand {
            cards: vec![Card::Ass, Card::Ass, Card::Ass, Card::Jack, Card::Number(2)],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Four);
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::Jack,
                Card::Jack,
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Four);
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Jack,
                Card::Jack,
                Card::Jack,
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Four);
    }

    #[test]
    fn test_triple() {
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::Ass,
                Card::Number(2),
                Card::Number(3),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Triplet);
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::Jack,
                Card::Number(2),
                Card::Number(3),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Triplet);
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Jack,
                Card::Jack,
                Card::Number(2),
                Card::Number(3),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Triplet);
    }

    #[test]
    fn test_full_house() {
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::Ass,
                Card::Number(2),
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::FullHouse);
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::Jack,
                Card::Number(2),
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::FullHouse);
    }

    #[test]
    fn test_two_pair() {
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::King,
                Card::King,
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::TwoPair);
    }

    #[test]
    fn test_pair() {
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Ass,
                Card::King,
                Card::Queen,
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Pair);
        let h = Hand {
            cards: vec![
                Card::Ass,
                Card::Jack,
                Card::King,
                Card::Queen,
                Card::Number(2),
            ],
            bid: 0,
        };
        assert_eq!(h.hand_type(), HandType::Pair);
    }
}
