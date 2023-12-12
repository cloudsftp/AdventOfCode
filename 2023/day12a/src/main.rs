#![feature(test)]

extern crate test;

use std::{fs::File, io::Read, str::FromStr, usize};

use anyhow::{anyhow, Error};
use clap::Parser;

use iter_tools::Itertools;

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

fn run(content: &str) -> usize {
    let records = parse(content);

    for r in records {
        println!("{:?}", r)
    }

    //    records.iter().map(Record::process).sum()
    0
}

#[derive(Debug)]
enum ConditionGroup {
    Operational,
    Damaged(usize),
    Unknown(usize),
}

#[derive(Debug)]
struct Record {
    conditions: Vec<ConditionGroup>,
    groups: Vec<usize>,
}

// Parsing

fn parse(content: &str) -> Vec<Record> {
    content
        .lines()
        .map(Record::from_str)
        .collect::<Result<_, _>>()
        .expect("someting went wrong during parsing")
}

impl FromStr for Record {
    type Err = Error;

    fn from_str(line: &str) -> Result<Self, Self::Err> {
        let mut parts = line.split_ascii_whitespace();

        let condition_part = parts.next().expect("we know it has two parts");
        let conditions = condition_part
            .chars()
            .group_by(|c| c.clone())
            .into_iter()
            .map(|(c, group)| match c {
                '.' => Ok(ConditionGroup::Operational),
                '#' => Ok(ConditionGroup::Damaged(group.count())),
                '?' => Ok(ConditionGroup::Unknown(group.count())),
                _ => Err(anyhow!("unexpected character in input: {}", c)),
            })
            .collect::<Result<_, _>>()?;

        let group_part = parts.next().expect("we know it has two parts");
        let groups = group_part
            .split(",")
            .map(usize::from_str)
            .collect::<Result<_, _>>()?;

        Ok(Record { conditions, groups })
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
        assert_eq!(result, 21)
    }

    /*
    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 8180)
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        b.iter(|| run(&content));
    }
    */
}
