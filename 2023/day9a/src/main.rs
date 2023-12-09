#![feature(test)]

extern crate test;

use std::{collections::VecDeque, fs::File, io::Read, str::FromStr};

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

fn run(content: &str) -> i64 {
    let histrories = parse(content);

    histrories.into_iter().map(predict).sum()
}

fn predict(history: Vec<i64>) -> i64 {
    let differences = compute_differences_func(history);

    differences.into_iter().fold(0, |acc, difference| {
        acc + difference
            .last()
            .expect("differences should always have at least one element")
    })
}

fn compute_differences(history: Vec<i64>) -> Vec<Vec<i64>> {
    let mut res = VecDeque::from([history.clone()]);
    let mut curr = history;

    while !curr.iter().all(|e| *e == 0) {
        curr = curr.iter().tuple_windows().map(|(a, b)| b - a).collect();

        res.push_front(curr.clone());
    }

    res.into()
}

fn compute_differences_func(history: Vec<i64>) -> Vec<Vec<i64>> {
    compute_differences_rec(VecDeque::from([history]))
}

fn compute_differences_rec(differences: VecDeque<Vec<i64>>) -> Vec<Vec<i64>> {
    let first = differences
        .get(0)
        .expect("differences should always have one history of differences");

    if first.iter().all(|e| *e == 0) {
        return differences.into();
    }

    let difference = first.iter().tuple_windows().map(|(a, b)| b - a).collect();

    let mut differences = differences.clone();
    differences.push_front(difference);
    compute_differences_rec(differences)
}

fn parse(content: &str) -> Vec<Vec<i64>> {
    content
        .lines()
        .map(|l| {
            l.split_ascii_whitespace()
                .map(i64::from_str)
                .collect::<Result<_, _>>()
                .expect("should be able to parse all numbers")
        })
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
        assert_eq!(result, 114)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 2043183816)
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
