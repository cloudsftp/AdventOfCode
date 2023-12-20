#![feature(test)]

extern crate test;

use core::panic;
use std::{char, collections::HashMap, fs::File, io::Read, str::FromStr, usize};

use anyhow::Error;
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

fn run(content: &str) -> usize {
    let workflows = parse(content);

    let mut parts = Vec::from([(
        "in".to_string(),
        PartRange {
            ranges: [(1, 4001); 4],
        },
    )]);

    let mut accepted = vec![];

    loop {
        parts = process_parts(parts, &workflows);

        parts = parts
            .into_iter()
            .filter_map(|(name, parts)| {
                if name.as_str() == "R" {
                    None
                } else if name.as_str() == "A" {
                    accepted.push(parts);
                    None
                } else {
                    Some((name, parts))
                }
            })
            .collect();

        if parts.is_empty() {
            break;
        }
    }

    accepted.into_iter().map(PartRange::score).sum()
}

impl PartRange {
    fn score(self) -> usize {
        self.ranges
            .into_iter()
            .map(|(min, max)| max.saturating_sub(min))
            .product()
    }
}

fn process_parts(
    parts: Vec<(String, PartRange)>,
    worklflows: &HashMap<String, Workflow>,
) -> Vec<(String, PartRange)> {
    parts
        .into_iter()
        .map(|(name, parts)| {
            let workflow = worklflows.get(&name).unwrap();
            workflow.process(parts).into_iter()
        })
        .flatten()
        .collect()
}

impl Workflow {
    fn process(&self, mut parts: PartRange) -> Vec<(String, PartRange)> {
        let mut res = vec![];

        for rule in &self.rules {
            if rule.splits(&parts) {
                let (split, left) = rule.split(parts);
                res.push((rule.destination.clone(), split));
                parts = left;
            }
        }
        res.push((self.final_destination.clone(), parts));

        res
    }
}

impl Rule {
    fn splits(&self, parts: &PartRange) -> bool {
        parts
            .ranges
            .iter()
            .any(|(min, max)| min <= &self.value && &self.value < max)
    }

    fn split(&self, parts: PartRange) -> (PartRange, PartRange) {
        let mut split = parts.clone();
        let mut left = parts;

        match self.condition {
            Condition::Less => {
                split.ranges[self.variable as usize].1 = self.value;
                left.ranges[self.variable as usize].0 = self.value;
            }
            Condition::Greater => {
                split.ranges[self.variable as usize].0 = self.value + 1;
                left.ranges[self.variable as usize].1 = self.value + 1;
            }
        }

        (split, left)
    }
}

#[derive(Debug, Clone)]
struct PartRange {
    ranges: [(usize, usize); 4],
}

#[derive(Debug)]
struct Workflow {
    rules: Vec<Rule>,
    final_destination: String,
}

#[derive(Debug)]
struct Rule {
    destination: String,
    variable: Variable,
    condition: Condition,
    value: usize,
}

#[derive(Debug)]
enum Condition {
    Less,
    Greater,
}

#[derive(Debug, Clone, Copy)]
enum Variable {
    X,
    M,
    A,
    S,
}

// Parsing

fn parse(content: &str) -> HashMap<String, Workflow> {
    content
        .lines()
        .take_while(|line| !line.is_empty())
        .map(|line| {
            let (name, workflow) = line.split_once("{").unwrap();
            let name = name.to_string();

            let workflow = workflow.strip_suffix("}").unwrap();
            Workflow::from_str(workflow).map(|workflow| (name, workflow))
        })
        .collect::<Result<_, _>>()
        .unwrap()
}

impl FromStr for Workflow {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let parts = s.split(",");

        let rules = parts
            .clone()
            .take_while(|p| p.contains(":"))
            .map(Rule::from_str)
            .collect::<Result<_, _>>()
            .unwrap();

        let final_destination = parts.last().unwrap().to_string();

        Ok(Workflow {
            rules,
            final_destination,
        })
    }
}

impl FromStr for Rule {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut chars = s.chars();
        let variable = Variable::from(chars.next().unwrap());
        let condition = Condition::from(chars.next().unwrap());

        let (value, destination) = &s[2..].split_once(":").unwrap();
        let value = value.parse().unwrap();
        let destination = destination.to_string();

        Ok(Rule {
            destination,
            variable,
            condition,
            value,
        })
    }
}

impl From<char> for Variable {
    fn from(value: char) -> Self {
        match value {
            'x' => Variable::X,
            'm' => Variable::M,
            'a' => Variable::A,
            's' => Variable::S,
            _ => unreachable!(),
        }
    }
}

impl From<char> for Condition {
    fn from(value: char) -> Self {
        match value {
            '<' => Condition::Less,
            '>' => Condition::Greater,
            _ => unreachable!(),
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
        assert_eq!(result, 167409079868000)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 123972546935551)
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
