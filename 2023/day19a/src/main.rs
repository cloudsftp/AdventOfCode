#![feature(test)]

extern crate test;

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
    let (workflows, parts) = parse(content);

    parts.into_iter().map(|part| part.process(&workflows)).sum()
}

impl Part {
    fn process(self, workflows: &HashMap<String, Workflow>) -> usize {
        let mut name = "in".to_string();
        let accepted = loop {
            let workflow = workflows.get(&name).unwrap();
            name = workflow.process(&self);

            if name.as_str() == "A" {
                break true;
            } else if name.as_str() == "R" {
                break false;
            }
        };

        if accepted {
            self.values.into_iter().sum()
        } else {
            0
        }
    }
}

impl Workflow {
    fn process(&self, part: &Part) -> String {
        for rule in &self.rules {
            if rule.accepts(part) {
                return rule.destination.clone();
            }
        }

        self.final_destination.clone()
    }
}

impl Rule {
    fn accepts(&self, part: &Part) -> bool {
        match self.condition {
            Condition::Less => part.values[self.variable as usize] < self.value,
            Condition::Greater => part.values[self.variable as usize] > self.value,
        }
    }
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

#[derive(Debug)]
struct Part {
    values: [usize; 4],
}

// Parsing

fn parse(content: &str) -> (HashMap<String, Workflow>, Vec<Part>) {
    let mut lines = content.lines();

    let workflows = (&mut lines)
        .take_while(|line| !line.is_empty())
        .map(|line| {
            let (name, workflow) = line.split_once("{").unwrap();
            let name = name.to_string();

            let workflow = workflow.strip_suffix("}").unwrap();
            Workflow::from_str(workflow).map(|workflow| (name, workflow))
        })
        .collect::<Result<_, _>>()
        .unwrap();

    let parts = lines.map(Part::from_str).collect::<Result<_, _>>().unwrap();

    (workflows, parts)
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

impl FromStr for Part {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s = s.strip_prefix("{").unwrap().strip_suffix("}").unwrap();

        let mut values = [0; 4];
        for v in s.split(",") {
            let var = Variable::from(v.chars().next().unwrap());
            let val = v[2..].parse().unwrap();

            values[var as usize] = val;
        }

        Ok(Part { values })
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
        assert_eq!(result, 19114)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 330820)
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
