#![feature(test)]

extern crate test;

mod trie;

use std::{fs::File, io::Read};

use trie::TNode;

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

fn create_root() -> TNode {
    let mut root = TNode::new();

    root.add("1", 1);
    root.add("2", 2);
    root.add("3", 3);
    root.add("4", 4);
    root.add("5", 5);
    root.add("6", 6);
    root.add("7", 7);
    root.add("8", 8);
    root.add("9", 9);
    root.add("one", 1);
    root.add("two", 2);
    root.add("three", 3);
    root.add("four", 4);
    root.add("five", 5);
    root.add("six", 6);
    root.add("seven", 7);
    root.add("eight", 8);
    root.add("nine", 9);

    root
}

fn run(content: &str) -> u32 {
    let root = create_root();
    content.lines().map(|l| process(l, &root)).sum()
}

fn process(line: &str, root: &TNode) -> u32 {
    let mut open = vec![];
    let mut digits = vec![];

    // let collect_terminal = || {
    //};

    for c in line.chars() {
        open.retain(|o: &&TNode| match o.value {
            None => true,
            Some(value) => {
                digits.push(value);
                false
            }
        });

        open = open.iter().filter_map(|p| p.next.get(&c)).collect();

        if let Some(child) = root.next.get(&c) {
            open.push(child)
        }
    }
    open.retain(|o: &&TNode| match o.value {
        None => true,
        Some(value) => {
            digits.push(value);
            false
        }
    });

    match digits.len() {
        0 => panic!("malformed line: {}", line),
        1 => {
            let first = digits.first().expect("has at least one digit");
            first * 10 + first
        }
        _ => {
            let first = digits.first().expect("has at least one digit");
            let last = digits.last().expect("has at least one digit");

            first * 10 + last
        }
    }
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
