#![feature(test)]

extern crate test;

use std::{fs::File, i64, io::Read, str::SplitAsciiWhitespace};

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
    let (seeds, maps) = parse(content);

    let maps = fill_map_gaps(maps);

    for m in &maps {
        println!("{:?}", m);
    }

    seeds
        .iter()
        .map(|s| process_seeds(&maps, s))
        .min()
        .expect("at least one set of seeds in input")
}

fn process_seeds(maps: &Vec<Vec<IngredientMap>>, seeds: &Seeds) -> i64 {
    let mut terminals = vec![];

    let mut start = seeds.start;
    while start < seeds.start + seeds.len {
        let (terminal, processed) = walk(maps, start, seeds.start + seeds.len - start);

        terminals.push(terminal);
        start += processed;
    }

    terminals
        .into_iter()
        .min()
        .expect("at least one terminal expected")
}

fn walk(maps: &[Vec<IngredientMap>], start: i64, len: i64) -> (i64, i64) {
    if maps.len() == 0 {
        return (start, len);
    }

    let map = maps
        .get(0)
        .expect("length is greater than 0")
        .iter()
        .filter(|m| m.src <= start && start < m.src + m.len)
        .next()
        .expect("at least one map should fulfill this map");

    let len = len.min(map.len - (start - map.src));
    let start = start + map.dest - map.src;

    walk(&maps[1..], start, len)
}

// Fill Gaps

fn fill_map_gaps(maps: Vec<Vec<IngredientMap>>) -> Vec<Vec<IngredientMap>> {
    maps.into_iter().map(fill_map_gaps_step).collect()
}

fn fill_map_gaps_step(og_maps: Vec<IngredientMap>) -> Vec<IngredientMap> {
    let mut og_maps = og_maps;
    og_maps.sort_by_key(|m| m.src);

    let mut maps = vec![];
    let mut last_not_mapped = 0;

    for map in og_maps {
        if map.src > last_not_mapped {
            maps.push(IngredientMap {
                dest: last_not_mapped,
                src: last_not_mapped,
                len: map.src - last_not_mapped,
            })
        }
        last_not_mapped = map.src + map.len;

        maps.push(map);
    }

    maps.push(IngredientMap {
        dest: last_not_mapped,
        src: last_not_mapped,
        len: i64::max_value() - last_not_mapped,
    });

    maps
}

// Parsing

fn parse(content: &str) -> (Vec<Seeds>, Vec<Vec<IngredientMap>>) {
    let mut lines = content.lines();

    let seeds = parse_seeds(lines.next().expect("input has at least one line"));

    lines.next();

    let mut maps = vec![];
    while let Some(_) = lines.next() {
        maps.push(
            (&mut lines)
                .take_while(|l| !l.is_empty())
                .map(|l| l.into())
                .collect(),
        );
    }

    (seeds, maps)
}

fn parse_seeds(line: &str) -> Vec<Seeds> {
    let numbers: Vec<i64> = line
        .split_ascii_whitespace()
        .skip(1)
        .map(|n| {
            n.parse::<i64>()
                .expect("all parts should consist of digits only")
        })
        .collect();

    numbers
        .chunks(2)
        .map(|c| {
            if c.len() != 2 {
                panic!("something wrong with parsing the seed line")
            }

            Seeds {
                start: c[0],
                len: c[1],
            }
        })
        .collect()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct Seeds {
    start: i64,
    len: i64,
}

#[derive(Debug)]
struct IngredientMap {
    dest: i64,
    src: i64,
    len: i64,
}

impl From<&str> for IngredientMap {
    fn from(value: &str) -> Self {
        let mut parts = value.split_ascii_whitespace();

        IngredientMap {
            dest: parse_part(&mut parts),
            src: parse_part(&mut parts),
            len: parse_part(&mut parts),
        }
    }
}

fn parse_part(parts: &mut SplitAsciiWhitespace) -> i64 {
    parts
        .next()
        .expect("element should exist")
        .parse()
        .expect("element should consist of digits only")
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
        assert_eq!(result, 46)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 79874951)
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
