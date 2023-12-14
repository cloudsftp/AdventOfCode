#![feature(test)]

extern crate test;

use std::{char, collections::HashSet, fs::File, i64, io::Read, iter, str::Chars, usize};

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

fn run(content: &str) -> i64 {
    let field = parse(content);

    field.into_iter().map(process).sum()
}

fn process(col: Column) -> i64 {
    let chunks = get_rolling_chunks(&col);

    chunks
        .into_iter()
        .map(|(s, n)| n * (col.len as i64 - s) - (n * (n + 1)) / 2)
        .sum()
}

fn get_rolling_chunks(col: &Column) -> Vec<(i64, i64)> {
    let mut acc: Vec<(i64, i64)> = vec![];
    let mut rolling: HashSet<usize> = col.rolling.iter().cloned().collect();

    for s in col.steady.iter().cloned().rev() {
        let relevant: HashSet<usize> = rolling.iter().filter(|r| **r > s).cloned().collect();
        rolling = rolling.difference(&relevant).cloned().collect();

        acc.push((s as i64, relevant.len() as i64))
    }

    if rolling.len() > 0 {
        acc.push((-1, rolling.len() as i64))
    }

    acc
}

#[derive(Debug)]
struct Column {
    steady: Vec<usize>,
    rolling: Vec<usize>,
    len: usize,
}

// Parsing

fn parse(content: &str) -> Vec<Column> {
    fn get_coordinated_mathing(col: &Vec<char>, pred: fn(char) -> bool) -> Vec<usize> {
        col.iter()
            .enumerate()
            .filter_map(|(i, c)| pred(*c).then_some(i))
            .collect()
    }

    let mut cols: Vec<Column> = vec![];
    let mut lines: Vec<Chars> = content.lines().map(|line| line.chars()).collect();

    let len = lines.len();

    loop {
        let col: Vec<char> = lines.iter_mut().filter_map(|line| line.next()).collect();

        if col.len() == 0 {
            break;
        }

        let steady = get_coordinated_mathing(&col, |c| c == '#');
        let rolling = get_coordinated_mathing(&col, |c| c == 'O');

        cols.push(Column {
            steady,
            rolling,
            len,
        });
    }

    cols
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
        assert_eq!(result, 136)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 113486)
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
