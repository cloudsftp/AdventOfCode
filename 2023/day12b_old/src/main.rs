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

    records.iter().map(Record::process).sum()
}

#[derive(Debug)]
struct Record {
    damaged: Vec<Option<bool>>,
    groups: Vec<usize>,
}

impl Record {
    fn process(&self) -> usize {
        process_rec(&self.damaged, &self.groups)
    }
}

fn process_rec(damaged: &Vec<Option<bool>>, groups: &Vec<usize>) -> usize {
    let complete = damaged.iter().all(|d| *d != None);

    if !grouping_possible(damaged, groups, complete) {
        return 0;
    }

    if complete {
        return 1;
    }

    let (next_false, next_true) = create_reucursion_damaged(damaged);
    process_rec(&next_false, groups) + process_rec(&next_true, groups)
}

fn grouping_possible(damaged: &Vec<Option<bool>>, groups: &Vec<usize>, complete: bool) -> bool {
    let mut curr_groups = vec![];
    let mut curr_group = 0;

    let mut last_incomplete = damaged.len() == 0;
    for d in damaged {
        match d {
            None => {
                if curr_group > 0 {
                    curr_groups.push(curr_group);
                    curr_group = 0;
                    last_incomplete = true;
                }
                break;
            }
            Some(true) => curr_group += 1,
            Some(false) => {
                if curr_group > 0 {
                    curr_groups.push(curr_group);
                    curr_group = 0;
                }
            }
        }
    }
    if curr_group > 0 {
        curr_groups.push(curr_group);
    }

    let mut pairs = curr_groups.iter().zip(groups.iter()).peekable();
    let mut res = !complete || curr_groups.len() == groups.len();
    while let Some((c, g)) = pairs.next() {
        res = res
            && if last_incomplete && pairs.peek() == None {
                c <= g
            } else {
                c == g
            }
    }

    res
}

fn create_reucursion_damaged(
    damaged: &Vec<Option<bool>>,
) -> (Vec<Option<bool>>, Vec<Option<bool>>) {
    let (index, _) = damaged
        .iter()
        .enumerate()
        .find(|(_, d)| *d == &None)
        .expect("We know that one element must be none");

    let mut next_false = damaged.clone();
    next_false[index] = Some(false);

    let mut next_true = damaged.clone();
    next_true[index] = Some(true);

    (next_false, next_true)
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

        let damage_part = parts.next().expect("we know it has two parts");
        let damage_part = (0..5).map(|_| damage_part).join("?");
        let damaged = damage_part
            .chars()
            .map(|c| match c {
                '.' => Ok(Some(false)),
                '#' => Ok(Some(true)),
                '?' => Ok(None),
                _ => Err(anyhow!("unknown character in input: {}", c)),
            })
            .collect::<Result<_, _>>()?;

        let group_part = parts.next().expect("we know it has two parts");
        let group_part = (0..5).map(|_| group_part).join(",");
        let groups = group_part
            .split(",")
            .map(usize::from_str)
            .collect::<Result<_, _>>()?;

        Ok(Record { damaged, groups })
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
        assert_eq!(result, 525152)
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
}
