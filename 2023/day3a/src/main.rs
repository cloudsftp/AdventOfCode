use std::{fs::File, io::Read, u32};

use clap::Parser;
use regex::Regex;

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

fn run(content: &str) -> u32 {
    let sym_regex = Regex::new("[^\\.\\d]").unwrap();
    let symbol_positions = get_symbol_positions(content, &sym_regex);

    for (line_positions, line) in symbol_positions.iter().zip(content.lines()) {
        println!("{} - {:?}", line, line_positions)
    }

    let num_regex = Regex::new("\\d+").unwrap();
    content
        .lines()
        .map(|l| process_line(l, &num_regex, &sym_regex))
        .sum()
}

fn get_symbol_positions(content: &str, sym_regex: &Regex) -> Vec<Vec<usize>> {
    let mut positions = Vec::with_capacity(content.lines().count());

    for line in content.lines() {
        let mut line_positions = vec![];

        for sym_match in sym_regex.find_iter(line) {
            line_positions.push(sym_match.start());
        }

        positions.push(line_positions);
    }

    positions
}

fn process_line(line: &str, num_regex: &Regex, sym_regex: &Regex) -> u32 {
    let num_matches = num_regex.find_iter(line);

    //    println!("--- {}", line);
    for num_match in num_matches {
        //        println!("{:?}", num_match)
    }

    0
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 4361)
    }
}
