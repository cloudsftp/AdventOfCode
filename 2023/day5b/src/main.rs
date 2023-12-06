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

    maps.iter()
        .fold(seeds, apply_maps)
        .into_iter()
        .map(|s| s.start)
        //.inspect(|s| println!("{:?}", s))
        .min()
        .expect("resulting vector should have at least one element")
}
fn apply_maps(seeds: Vec<Seeds>, maps: &Vec<IngredientMap>) -> Vec<Seeds> {
    println!("\n\n\n#################################\nmaps:\n{:?}", maps);
    seeds
        .into_iter()
        .map(|s| apply_maps_single(s, maps))
        .flatten()
        .collect()
}

fn apply_maps_single(seeds: Seeds, maps: &Vec<IngredientMap>) -> Vec<Seeds> {
    let mut maps: Vec<&IngredientMap> = maps
        .into_iter()
        .filter(|m| m.src < seeds.start + seeds.len && m.src + m.len > seeds.start)
        .collect();
    maps.sort_by_key(|m| m.src);

    let mut new_seeds = vec![];
    let mut last_not_mapped = seeds.start;

    for map in maps {
        // Without mapping
        if last_not_mapped < map.src {
            new_seeds.push(Seeds {
                start: last_not_mapped,
                len: map.src - last_not_mapped,
            });
        }

        // With mapping
        if last_not_mapped <= map.src {
            let start = map.dest;
            let len = map.len.min(seeds.start + seeds.len - map.src);
            last_not_mapped = map.src + len;
            new_seeds.push(Seeds { start, len });
        } else {
            let start = last_not_mapped + map.dest - map.src;
            let len = (map.src + map.len - seeds.start).min(seeds.len);
            last_not_mapped += len;
            new_seeds.push(Seeds { start, len });
        }
    }

    // Without mapping
    if last_not_mapped < seeds.start + seeds.len {
        new_seeds.push(Seeds {
            start: last_not_mapped,
            len: seeds.start + seeds.len - last_not_mapped,
        })
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
    fn test_apply_map_longer_than_seeds() {
        let seeds = Seeds { start: 1, len: 8 };
        let maps = vec![IngredientMap {
            dest: 100,
            src: 0,
            len: 10,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].start, 101);
        assert_eq!(result[0].len, 8);

        let maps = vec![IngredientMap {
            dest: 100,
            src: 1,
            len: 10,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].start, 100);
        assert_eq!(result[0].len, 8);

        let maps = vec![IngredientMap {
            dest: 100,
            src: 2,
            len: 10,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0].start, 1);
        assert_eq!(result[0].len, 1);
        assert_eq!(result[1].start, 100);
        assert_eq!(result[1].len, 7);
    }

    #[test]
    fn test_apply_map_shorter_than_seeds() {
        let seeds = Seeds { start: 1, len: 8 };
        let maps = vec![IngredientMap {
            dest: 100,
            src: 0,
            len: 9,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].start, 101);
        assert_eq!(result[0].len, 8);

        let maps = vec![IngredientMap {
            dest: 100,
            src: 0,
            len: 8,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0].start, 101);
        assert_eq!(result[0].len, 7);
        assert_eq!(result[1].start, 8);
        assert_eq!(result[1].len, 1);
    }
    #[test]
    fn test_apply_map_inside() {
        let seeds = Seeds { start: 10, len: 10 };
        let maps = vec![IngredientMap {
            dest: 100,
            src: 12,
            len: 6,
        }];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 3);
        assert_eq!(result[0], Seeds { start: 10, len: 2 });
        assert_eq!(result[1], Seeds { start: 100, len: 6 });
        assert_eq!(result[2], Seeds { start: 18, len: 2 });
    }

    #[test]
    fn test_apply_two_maps() {
        let seeds = Seeds { start: 10, len: 10 };
        let maps = vec![
            IngredientMap {
                dest: 100,
                src: 12,
                len: 2,
            },
            IngredientMap {
                dest: 100,
                src: 16,
                len: 2,
            },
        ];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 5);
        assert_eq!(result[0], Seeds { start: 10, len: 2 });
        assert_eq!(result[1], Seeds { start: 100, len: 2 });
        assert_eq!(result[2], Seeds { start: 14, len: 2 });
        assert_eq!(result[3], Seeds { start: 100, len: 2 });
        assert_eq!(result[4], Seeds { start: 18, len: 2 });

        let maps = vec![
            IngredientMap {
                dest: 100,
                src: 8,
                len: 6,
            },
            IngredientMap {
                dest: 100,
                src: 16,
                len: 2,
            },
        ];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 4);
        assert_eq!(result[0], Seeds { start: 102, len: 4 });
        assert_eq!(result[1], Seeds { start: 14, len: 2 });
        assert_eq!(result[2], Seeds { start: 100, len: 2 });
        assert_eq!(result[3], Seeds { start: 18, len: 2 });

        let maps = vec![
            IngredientMap {
                dest: 100,
                src: 12,
                len: 2,
            },
            IngredientMap {
                dest: 100,
                src: 16,
                len: 6,
            },
        ];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 4);
        assert_eq!(result[0], Seeds { start: 10, len: 2 });
        assert_eq!(result[1], Seeds { start: 100, len: 2 });
        assert_eq!(result[2], Seeds { start: 14, len: 2 });
        assert_eq!(result[3], Seeds { start: 100, len: 4 });

        let maps = vec![
            IngredientMap {
                dest: 100,
                src: 8,
                len: 6,
            },
            IngredientMap {
                dest: 100,
                src: 16,
                len: 6,
            },
        ];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 3);
        assert_eq!(result[0], Seeds { start: 102, len: 4 });
        assert_eq!(result[1], Seeds { start: 14, len: 2 });
        assert_eq!(result[2], Seeds { start: 100, len: 4 });

        let maps = vec![
            IngredientMap {
                dest: 100,
                src: 10,
                len: 5,
            },
            IngredientMap {
                dest: 100,
                src: 15,
                len: 5,
            },
        ];

        let result = apply_maps_single(seeds, &maps);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0], Seeds { start: 100, len: 5 });
        assert_eq!(result[1], Seeds { start: 100, len: 5 });
    }
}
