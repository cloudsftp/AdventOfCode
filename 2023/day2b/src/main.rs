use std::{fs::File, io::Read};

use anyhow::{anyhow, Error};
use regex::Regex;

fn main() {
    let mut file = File::open("data").unwrap();

    let mut content: String = "".to_string();
    file.read_to_string(&mut content).unwrap();

    let lines = content.lines();
    let games: Vec<Game> = lines
        .map(|l| l.try_into())
        .collect::<Result<_, _>>()
        .unwrap();

    let result: u32 = games
        .iter()
        .map(Game::minimum_numbers)
        .map(MinimumGame::multiply_numbers)
        .sum();

    println!("result: {}", result)
}

#[derive(Debug)]
struct Game {
    rounds: Vec<Round>,
}

#[derive(Debug)]
struct MinimumGame {
    r: u32,
    g: u32,
    b: u32,
}

#[derive(Debug)]
struct Round {
    r: u32,
    g: u32,
    b: u32,
}

impl Game {
    fn minimum_numbers(&self) -> MinimumGame {
        let (mut r, mut g, mut b) = (0, 0, 0);

        for round in &self.rounds {
            if round.r > r {
                r = round.r
            }
            if round.g > g {
                g = round.g
            }
            if round.b > b {
                b = round.b
            }
        }

        MinimumGame { r, g, b }
    }
}

impl MinimumGame {
    fn multiply_numbers(self) -> u32 {
        self.r * self.g * self.b
    }
}

// Parsing

impl TryFrom<&str> for Game {
    type Error = Error;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        let parts: Vec<&str> = value.split(":").collect();
        if parts.len() != 2 {
            return Err(anyhow!(
                "first split of the game line was not successful: {}",
                value
            ));
        }

        let rounds = Self::parse_rounds(parts[1])?;

        Ok(Game { rounds })
    }
}

impl Game {
    fn parse_rounds(input: &str) -> Result<Vec<Round>, Error> {
        input.split(";").map(|r| r.try_into()).collect()
    }
}

impl TryFrom<&str> for Round {
    type Error = Error;

    fn try_from(value: &str) -> Result<Self, Self::Error> {
        let (mut r, mut g, mut b) = (0, 0, 0);

        let no_commas = value.replace(",", "");
        let parts: Vec<&str> = no_commas.trim().split(" ").collect();
        for chunk in parts.chunks(2) {
            let val: u32 = chunk[0].parse()?;
            match chunk[1] {
                "red" => r = val,
                "blue" => b = val,
                "green" => g = val,
                _ => return Err(anyhow!("expected color here: {}", chunk[1])),
            }
        }

        Ok(Round { r, g, b })
    }
}
