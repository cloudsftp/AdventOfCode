#![feature(test)]

extern crate test;

use core::panic;
use std::{collections::HashSet, fs::File, io::Read, usize};

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
    let fields = parse(content);

    fields.iter().map(Field::process).sum()
}

#[derive(Debug)]
struct Field {
    coordinates: Vec<(usize, usize)>,
    height: usize,
    width: usize,
}

impl Field {
    fn process(&self) -> usize {
        let v = self.vertical_reflections();
        let h = self.horizontal_reflections();

        v + 100 * h
    }

    fn vertical_reflections(&self) -> usize {
        let cols = get_sets(&self.coordinates, |(x, _)| x, |(_, y)| y, self.width);

        (0..self.width - 1)
            .filter(|i| is_almost_reflection(&cols, *i))
            .map(|i| i + 1)
            .next()
            .unwrap_or(0)
    }

    fn horizontal_reflections(&self) -> usize {
        let rows = get_sets(&self.coordinates, |(_, y)| y, |(x, _)| x, self.height);

        (0..self.height - 1)
            .filter(|i| is_almost_reflection(&rows, *i))
            .map(|i| i + 1)
            .next()
            .unwrap_or(0)
    }
}

type Coordinates = (usize, usize);
type CoordinateProjection = fn(&Coordinates) -> &usize;

fn get_sets(
    coordinates: &Vec<Coordinates>,
    filter_proj: CoordinateProjection,
    map_proj: CoordinateProjection,
    length: usize,
) -> Vec<HashSet<usize>> {
    (0..length)
        .map(|i| {
            coordinates
                .iter()
                .filter(|c| filter_proj(*c) == &i)
                .map(|c| map_proj(c))
                .cloned()
                .collect()
        })
        .collect()
}

fn is_almost_reflection(sets: &Vec<HashSet<usize>>, i: usize) -> bool {
    let hypothetical_len = 2 * (i + 1);
    let (l, r) = if hypothetical_len <= sets.len() {
        (0, hypothetical_len)
    } else {
        (2 * i + 2 - sets.len(), sets.len())
    };

    is_almost_symmetric(&sets[l..r])
}

fn is_almost_symmetric(sets: &[HashSet<usize>]) -> bool {
    let mid = sets.len() / 2 - 1;

    let differences: Vec<usize> = (0..mid + 1)
        .map(|i| {
            sets[mid - i]
                .symmetric_difference(&sets[mid + i + 1])
                .count()
        })
        .collect();

    differences.iter().filter(|d| **d == 0).count() == differences.len() - 1
        && differences.iter().filter(|d| **d == 1).count() == 1
}

// Parsing

fn parse(content: &str) -> Vec<Field> {
    content
        .lines()
        .collect::<Vec<&str>>()
        .split(|line| line.is_empty())
        .map(Field::from)
        .collect()
}

impl From<&[&str]> for Field {
    fn from(lines: &[&str]) -> Self {
        let height = lines.len();
        let width = lines[0].len();

        let coordinates = lines
            .iter()
            .enumerate()
            .map(|(y, line)| {
                line.chars()
                    .enumerate()
                    .filter_map(move |(x, c)| if c == '#' { Some((x, y)) } else { None })
            })
            .flatten()
            .collect();

        Field {
            coordinates,
            height,
            width,
        }
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
        assert_eq!(result, 400)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 36919)
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
