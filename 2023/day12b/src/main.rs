#![feature(test)]

extern crate test;

use std::{
    collections::{btree_map::OccupiedEntry, HashMap},
    fs::File,
    io::Read,
    ops::Deref,
    str::FromStr,
    usize,
};

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

    let mut cache = HashMap::new();

    records
        .into_iter()
        .map(|record| process(&record.conditions, &record.groups, &mut cache))
        .inspect(|s| println!("\nprocessed one: {}\n", s))
        .sum()
}

type Cache = HashMap<(Vec<Condition>, Vec<usize>), usize>;

fn process(conditions: &[Condition], groups: &[usize], cache: &mut Cache) -> usize {
    if conditions.contains(&Condition::Operational) {
        split_chunks(conditions, groups, cache)
    } else {
        recurse_conditions(conditions, groups, cache)
    }
}

fn recurse_conditions(conditions: &[Condition], groups: &[usize], cache: &mut Cache) -> usize {
    fn inner(conditions: &[Condition], groups: &[usize], cache: &mut Cache) -> usize {
        if groups.is_empty() {
            if conditions.iter().any(|c| *c == Condition::Damaged) {
                0
            } else {
                1
            }
        } else {
            match conditions {
                [] => 0, // groups are non-empty at this point
                [Condition::Damaged, rest @ ..] => {
                    let first_group = groups[0] - 1;
                    if first_group > rest.len()
                        || (first_group < rest.len() && rest[first_group] != Condition::Unknown)
                    {
                        0
                    } else if first_group == rest.len() {
                        if groups.len() == 1 {
                            1
                        } else {
                            0
                        }
                    } else {
                        recurse_conditions(&rest[first_group + 1..], &groups[1..], cache)
                    }
                }
                [Condition::Unknown, rest @ ..] => {
                    let mut conditions_damaged = vec![Condition::Damaged];
                    conditions_damaged.extend_from_slice(rest);

                    recurse_conditions(&conditions_damaged, groups, cache)
                        + recurse_conditions(rest, groups, cache)
                }
                [Condition::Operational, ..] => {
                    unreachable!("the first field should never be operational at this point")
                }
            }
        }
    }

    let cached = cache.get(&(conditions.to_owned(), groups.to_owned()));
    match cached {
        Some(res) => *res,
        None => {
            let res = inner(conditions, groups, cache);
            cache.insert((conditions.to_owned(), groups.to_owned()), res);
            res
        }
    }
}

fn split_chunks(conditions: &[Condition], groups: &[usize], cache: &mut Cache) -> usize {
    let condition_chunks: Vec<&[Condition]> = conditions
        .split(|c| *c == Condition::Operational)
        .filter(|chunk| !chunk.is_empty())
        .collect();

    let mut res = 0;
    on_all_k_splits(
        &mut vec![],
        groups,
        condition_chunks.len(),
        &mut |group_split| {
            res += condition_chunks
                .iter()
                .zip(group_split.iter())
                .map(|(conditions, groups)| recurse_conditions(conditions, groups, cache))
                .product::<usize>()
        },
    );

    res
}

// based on:
// https://stackoverflow.com/questions/62486128/how-to-iterate-over-all-possible-partitions-of-a-slice-non-empty-subslices
fn on_all_k_splits<'a, F>(head: &mut Vec<&'a [usize]>, rest: &'a [usize], k: usize, f: &mut F)
where
    F: FnMut(&[&[usize]]),
{
    if k == 1 {
        head.push(rest);
        f(head);
        head.pop();
    } else {
        for i in 0..=rest.len() {
            let (next, tail) = rest.split_at(i);
            head.push(next);
            on_all_k_splits(head, tail, k - 1, f);
            head.pop();
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
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
        let folds = 4;

        let mut parts = line.split_ascii_whitespace();

        let condition_part = parts.next().expect("we know it has two parts");
        let condition_part = (0..folds).map(|_| condition_part).join("?");
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
        let group_part = (0..folds).map(|_| group_part).join(",");
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
