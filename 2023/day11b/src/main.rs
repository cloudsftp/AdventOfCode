#![feature(test)]

extern crate test;

use std::{fs::File, io::Read};

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
    let galaxies = parse(content);
    let (mty_cols, mty_rows) = get_empty(&galaxies);

    galaxies
        .into_iter()
        .combinations(2)
        .map(|galaxies| {
            compute_distance(
                galaxies.try_into().expect("we know the length"),
                &mty_cols,
                &mty_rows,
            )
        })
        .sum()
}

type Galaxies = Vec<(usize, usize)>;

fn compute_distance(
    galaxies: [(usize, usize); 2],
    mty_cols: &[usize],
    mty_rows: &[usize],
) -> usize {
    let (x1, y1) = galaxies[0];
    let (x2, y2) = galaxies[1];

    let (x1, x2) = if x1 > x2 { (x2, x1) } else { (x1, x2) };
    let (y1, y2) = if y1 > y2 { (y2, y1) } else { (y1, y2) };

    y2.abs_diff(y1)
        + x2.abs_diff(x1)
        + 999999 * mty_cols.iter().filter(|yc| y1 < **yc && **yc < y2).count()
        + 999999 * mty_rows.iter().filter(|xr| x1 < **xr && **xr < x2).count()
}

fn get_empty(galaxies: &Galaxies) -> (Vec<usize>, Vec<usize>) {
    let height = *galaxies
        .iter()
        .map(|(_, y)| y)
        .max()
        .expect("galaxies should be non-empty");
    let mty_cols = (0..height)
        .filter(|yc| galaxies.iter().all(|(_, yg)| yc != yg))
        .collect();

    let width = *galaxies
        .iter()
        .map(|(x, _)| x)
        .max()
        .expect("galaxies should be non-empty");
    let mty_rows = (0..width)
        .filter(|xr| galaxies.iter().all(|(xg, _)| xr != xg))
        .collect();

    (mty_cols, mty_rows)
}

// Parsing

fn parse(content: &str) -> Galaxies {
    content
        .lines()
        .enumerate()
        .map(|(y, line)| {
            line.chars()
                .enumerate()
                .filter(|(_, c)| *c == '#')
                .map(move |(x, _)| (x, y))
        })
        .flatten()
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
        assert_eq!(result, 82000210)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 597714117556)
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
