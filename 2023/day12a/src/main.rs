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

    records
        .into_iter()
        .map(|record| process(&record.conditions, &record.groups))
        .take(1)
        .sum()
}

fn process(conditions: &[Condition], groups: &[usize]) -> usize {
    if conditions.contains(&Condition::Operational) {
        split_chunks(conditions, groups)
    } else {
        recurse_conditions(conditions, groups)
    }
}

fn recurse_conditions(conditions: &[Condition], groups: &[usize]) -> usize {
    println!("####\nrecursing on: {:?} ({:?})", conditions, groups);

    if groups.is_empty() {
        if conditions.is_empty()
            || conditions
                .into_iter()
                .all_equal_value()
                .is_ok_and(|c| c == &Condition::Unknown)
        {
            1
        } else {
            0
        }
    } else {
        match conditions {
            [] => 0, // groups are non-empty at this point
            [Condition::Damaged, rest @ ..] => {
                let first_group = groups[0];
                if rest.len() < first_group - 1
                    || (first_group - 1 < rest.len() && rest[first_group - 1] != Condition::Unknown)
                {
                    0
                } else {
                    recurse_conditions(&conditions[first_group..], &groups[1..])
                }
            }
            [Condition::Unknown, rest @ ..] => {
                let mut conditions_damaged = vec![Condition::Damaged];
                conditions_damaged.extend_from_slice(rest);

                recurse_conditions(&conditions_damaged, groups) + recurse_conditions(rest, groups)
            }
            [Condition::Operational, ..] => {
                unreachable!("the first field should never be operational at this point")
            }
        }
    }
}

fn split_chunks(conditions: &[Condition], groups: &[usize]) -> usize {
    0
}

#[derive(Debug, Clone, Copy, PartialEq, Hash)]
enum Condition {
    Operational,
    Damaged,
    Unknown,
}

#[derive(Debug, Hash)]
struct Record {
    conditions: Vec<Condition>,
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
            .map(|c| match c {
                '.' => Ok(Condition::Operational),
                '#' => Ok(Condition::Damaged),
                '?' => Ok(Condition::Unknown),
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

    /*
    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 21)
    }

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

    #[test]
    fn test_process_record_one_chunk() {
        let conditions = vec![Condition::Damaged];
        let groups = vec![1];
        assert_eq!(process(&conditions, &groups), 1);

        let conditions = vec![Condition::Damaged, Condition::Unknown];
        let groups = vec![1];
        assert_eq!(process(&conditions, &groups), 1);

        let conditions = vec![Condition::Unknown, Condition::Unknown];
        let groups = vec![1];
        assert_eq!(process(&conditions, &groups), 2);

        let conditions = vec![Condition::Unknown, Condition::Unknown];
        let groups = vec![2];
        assert_eq!(process(&conditions, &groups), 1);

        let conditions = vec![Condition::Unknown, Condition::Unknown, Condition::Damaged];
        let groups = vec![2];
        assert_eq!(process(&conditions, &groups), 1);
    }
}
