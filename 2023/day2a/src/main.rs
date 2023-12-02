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

    let numbers = (12, 13, 14);
    let result: u32 = games
        .into_iter()
        .filter(|g| g.possible(numbers))
        //.inspect(|g| println!("debug: {:?}", g))
        .map(|g| g.id)
        .sum();

    println!("result: {}", result)
}

#[derive(Debug)]
struct Game {
    id: u32,
    rounds: Vec<Round>,
}

#[derive(Debug)]
struct Round {
    r: u32,
    g: u32,
    b: u32,
}

impl Game {
    fn possible(&self, numbers: (u32, u32, u32)) -> bool {
        self.rounds.iter().map(|r| r.possible(numbers)).all(|b| b)
    }
}

impl Round {
    fn possible(&self, numbers: (u32, u32, u32)) -> bool {
        self.r <= numbers.0 && self.g <= numbers.1 && self.b <= numbers.2
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

        let id = Self::parse_id(parts[0])?;
        let rounds = Self::parse_rounds(parts[1])?;

        Ok(Game { id, rounds })
    }
}

impl Game {
    fn parse_id(input: &str) -> Result<u32, Error> {
        let game_id_pattern = Regex::new("Game (\\d+)$").expect("must compile");
        let captured = game_id_pattern
            .captures(input)
            .ok_or(anyhow!("invalid game id part: {}", input))?;
        if captured.len() != 2 {
            return Err(anyhow!(
                "captured more or less than 1 ids for the game: {}",
                input
            ));
        }

        let id = (&captured[1])
            .parse::<u32>()
            .expect("match consists of only digits");

        Ok(id)
    }

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
