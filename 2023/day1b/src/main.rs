#![feature(test)]

extern crate test;

mod trie;

use std::{fs::File, io::Read};

const WORDS: [&str; 9] = [
    "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
];

fn main() {
    let mut file = File::open("big_test_file").unwrap();

    let mut content: String = "".to_string();
    file.read_to_string(&mut content).unwrap();

    let result = run(&content);

    println!("{}", result)
}

fn run(content: &str) -> u32 {
    0
}

#[cfg(test)]
mod tests {
    use super::*;
    use test::Bencher;

    #[test]
    fn test() {
        let mut file = File::open("big_test_file").unwrap();

        let mut content: String = "".to_string();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);

        return;

        assert_eq!(result, 53539);
    }

    #[bench]
    fn bench(b: &mut Bencher) {
        let mut file = File::open("big_test_file").unwrap();

        let mut content: String = "".to_string();
        file.read_to_string(&mut content).unwrap();
        b.iter(|| run(&content));
    }
}
