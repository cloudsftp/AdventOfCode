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

    let max_seed = seeds
        .iter()
        .map(|Seeds { start, len }| start + len)
        .max()
        .expect("should have at least one seed range in the input");
    let maps = fill_map_gaps(maps, max_seed);

    maps.iter()
        .fold(seeds, apply_maps)
        .into_iter()
        .map(|s| s.start)
        .min()
        .expect("resulting vector should have at least one element")
}

fn fill_map_gaps(maps: Vec<Vec<IngredientMap>>, max_seed: i64) -> Vec<Vec<IngredientMap>> {
    maps.into_iter()
        .map(|m| fill_map_gaps_step(m, max_seed))
        .collect()
}

fn fill_map_gaps_step(og_maps: Vec<IngredientMap>, max_seed: i64) -> Vec<IngredientMap> {
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

    if last_not_mapped < max_seed {
        maps.push(IngredientMap {
            dest: last_not_mapped,
            src: last_not_mapped,
            len: max_seed - last_not_mapped,
        })
    }

    maps
}

fn apply_maps(seeds: Vec<Seeds>, maps: &Vec<IngredientMap>) -> Vec<Seeds> {
    seeds
        .into_iter()
        .map(|s| apply_maps_single(s, maps))
        .flatten()
        .collect()
}

fn apply_maps_single(seeds: Seeds, maps: &Vec<IngredientMap>) -> Vec<Seeds> {
    let maps: Vec<&IngredientMap> = maps
        .into_iter()
        .filter(|m| m.src < seeds.start + seeds.len && m.src + m.len > seeds.start)
        .collect();

    let mut new_seeds = vec![];

    for map in maps {
        let start = if map.src < seeds.start {
            map.dest + seeds.start - map.src
        } else {
            map.dest
        };
        println!("{}", start);
        let mut len = map.len;
        let over = map.src + map.len - (seeds.start + seeds.len);
        if over > 0 {
            len -= over;
        }
        let under = map.src - seeds.start;
        if under < 0 {
            len += under;
        }
        new_seeds.push(Seeds { start, len })
    }

    new_seeds
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

    // Debugging:

    #[test]
    fn test_apply_one_map() {
        let seeds = Seeds { start: 10, len: 10 };
        let maps = vec![IngredientMap {
            dest: 100,
            src: 10,
            len: 10,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 1);
        assert_eq!(
            result[0],
            Seeds {
                start: 100,
                len: 10
            }
        );
    }

    #[test]
    fn test_apply_two_maps() {
        let seeds = Seeds { start: 10, len: 10 };
        let maps = vec![
            IngredientMap {
                dest: 100,
                src: 8,
                len: 7,
            },
            IngredientMap {
                dest: 100,
                src: 15,
                len: 8,
            },
        ];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0], Seeds { start: 102, len: 5 });
        assert_eq!(result[1], Seeds { start: 100, len: 5 });
    }
}
