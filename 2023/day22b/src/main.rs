use std::{collections::HashSet, fs::File, io::Read, str::FromStr, usize};

use anyhow::Error;
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
    let blocks = parse(content);

    let blocks = settle(blocks);
    let bottoms = blocks
        .iter()
        .enumerate()
        .filter_map(|(i, block)| if block.start.z == 1 { Some(i) } else { None })
        .collect_vec();
    let supporting = calculate_supporting(blocks);

    (0..supporting.len())
        .map(|i| chain(&supporting, &bottoms, i))
        .sum()
}

fn chain(supporting: &Vec<Vec<usize>>, bottoms: &Vec<usize>, i: usize) -> usize {
    let mut all_fallen: HashSet<usize> = HashSet::new();
    let mut just_fallen = HashSet::from([i]);

    while !just_fallen.is_empty() {
        all_fallen.extend(just_fallen.iter());

        just_fallen = (0..supporting.len())
            .filter(|id| !all_fallen.contains(id))
            .filter(|top| {
                !bottoms.contains(top)
                    && supporting[*top].iter().all(|bot| all_fallen.contains(bot))
            })
            .collect();
    }

    all_fallen.len() - 1
}

fn settle(mut blocks: Blocks) -> Blocks {
    blocks.sort_by_key(|block| block.start.z);

    let width = blocks.iter().map(|block| block.end.x).max().unwrap() + 1;
    let breadth = blocks.iter().map(|block| block.end.y).max().unwrap() + 1;

    let mut support = (0..breadth).map(|_| vec![0; width]).collect_vec();

    for block in blocks.iter_mut() {
        let curr_support = support
            .iter()
            .enumerate()
            .filter(|(y, _)| block.start.y <= *y && *y <= block.end.y)
            .map(|(_, row)| {
                row.iter()
                    .enumerate()
                    .filter(|(x, _)| block.start.x <= *x && *x <= block.end.x)
                    .map(|(_, v)| *v)
            })
            .flatten()
            .max()
            .unwrap()
            + 1;

        let height = block.end.z - block.start.z;
        block.start.z = curr_support;
        block.end.z = curr_support + height;

        for x in block.start.x..=block.end.x {
            for y in block.start.y..=block.end.y {
                support[y][x] = block.end.z;
            }
        }
    }

    blocks
}

fn calculate_supporting(blocks: Blocks) -> Vec<Vec<usize>> {
    let mut res = vec![];

    for (i, block) in blocks.iter().enumerate() {
        let mut resting = vec![];

        for (j, other) in blocks.iter().enumerate() {
            if bases_intersect(other, block) && other.end.z + 1 == block.start.z {
                resting.push(j);
            }
        }

        res.push(resting);
    }

    res
}

fn bases_intersect(block: &Block, other: &Block) -> bool {
    block.start.x <= other.end.x
        && block.end.x >= other.start.x
        && block.start.y <= other.end.y
        && block.end.y >= other.start.y
}

type Blocks = Vec<Block>;

#[derive(Debug)]
struct Block {
    start: Coordinates,
    end: Coordinates,
}

#[derive(Debug, PartialEq, PartialOrd)]
struct Coordinates {
    x: usize,
    y: usize,
    z: usize,
}

// Parsing

fn parse(content: &str) -> Blocks {
    content
        .lines()
        .map(Block::from_str)
        .collect::<Result<_, _>>()
        .unwrap()
}

impl FromStr for Block {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let (start, end) = s.split_once("~").unwrap();

        let start = Coordinates::from_str(start).unwrap();
        let end = Coordinates::from_str(end).unwrap();

        assert!(start <= end);

        Ok(Block { start, end })
    }
}

impl FromStr for Coordinates {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut parts = s.split(",").map(usize::from_str);

        Ok(Coordinates {
            x: parts.next().unwrap().unwrap(),
            y: parts.next().unwrap().unwrap(),
            z: parts.next().unwrap().unwrap(),
        })
    }
}

// testing
#[cfg(test)]
mod tests {

    use super::*;

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 7);
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 61297)
    }
}
