#![feature(test)]

extern crate test;

use std::{collections::HashMap, fs::File, io::Read, str::FromStr, usize};

use anyhow::{Error, Ok};
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
    let mut circuit = parse(content);

    //dbg!(&circuit);

    let mut low_sum = 0;
    let mut high_sum = 0;

    for _ in 0..1000 {
        let (low, high) = circuit.press();
        low_sum += low;
        high_sum += high;
    }

    low_sum * high_sum
}

impl Circuit {
    fn press(&mut self) -> (usize, usize) {
        let mut signals = vec![("".to_string(), "broadcaster".to_string(), false)];

        let mut low_count = 0;
        let mut high_count = 0;

        while !signals.is_empty() {
            let mut outputs = vec![];

            for (source, destination, signal) in signals {
                if signal {
                    high_count += 1;
                } else {
                    low_count += 1;
                }

                self.gates.get_mut(&destination).map(|gate| {
                    let mut gate_out = gate.process(source, signal);
                    outputs.append(&mut gate_out);
                });
            }

            signals = outputs;
        }

        (low_count, high_count)
    }
}

impl Gate {
    fn process(&mut self, source: String, signal: bool) -> Vec<(String, String, bool)> {
        let mut out = vec![];

        let mut send = |signal| {
            for destination in &self.destinations {
                out.push((self.name.to_string(), destination.to_string(), signal));
            }
        };

        match &mut self.gate_type {
            GateType::ID => send(signal),
            GateType::FlipFlop { state } => {
                if !signal {
                    *state = !*state;
                    send(*state)
                }
            }
            GateType::Conjunction { state } => {
                state.entry(source).and_modify(|v| *v = signal);
                let signal = !state.values().all(|v| *v);
                send(signal)
            }
        }

        out
    }
}

#[derive(Debug)]
struct Circuit {
    gates: HashMap<String, Gate>,
}

#[derive(Debug)]
struct Gate {
    name: String,
    destinations: Vec<String>,
    gate_type: GateType,
}

#[derive(Debug)]
enum GateType {
    ID,
    FlipFlop { state: bool },
    Conjunction { state: HashMap<String, bool> },
}

// Parsing

fn parse(content: &str) -> Circuit {
    let builder: CircuitBuilder = content.parse().unwrap();
    builder.build()
}

struct CircuitBuilder {
    sources: HashMap<String, Vec<String>>,
    gates: HashMap<String, Gate>,
}

impl FromStr for CircuitBuilder {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut sources = HashMap::new();
        let mut gates = HashMap::new();

        for line in s.lines() {
            let (gate, destinations) = line.split_once(" -> ").unwrap();

            let destinations = destinations
                .split(", ")
                .map(|d| d.to_string())
                .collect_vec();

            let gate = if gate.starts_with("%") {
                Gate {
                    name: gate[1..].to_string(),
                    destinations: destinations.clone(),
                    gate_type: GateType::FlipFlop { state: false },
                }
            } else if gate.starts_with("&") {
                Gate {
                    name: gate[1..].to_string(),
                    destinations: destinations.clone(),
                    gate_type: GateType::Conjunction {
                        state: HashMap::new(),
                    },
                }
            } else {
                Gate {
                    name: gate.to_string(),
                    destinations: destinations.clone(),
                    gate_type: GateType::ID,
                }
            };

            for destination in destinations {
                sources
                    .entry(destination.to_string())
                    .or_insert_with(|| Vec::new());
                sources
                    .entry(destination)
                    .and_modify(|sources| sources.push(gate.name.to_string()));
            }

            gates.insert(gate.name.to_string(), gate);
        }

        Ok(Self { sources, gates })
    }
}

impl CircuitBuilder {
    fn build(mut self) -> Circuit {
        for gate in self.gates.values_mut() {
            match &mut gate.gate_type {
                GateType::Conjunction { state } => {
                    let sources = self.sources.get(&gate.name).unwrap();
                    for s in sources {
                        state.insert(s.to_string(), false);
                    }
                }
                _ => (),
            }
        }

        Circuit { gates: self.gates }
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
        assert_eq!(result, 32000000)
    }

    #[test]
    fn test_extra() {
        let file = "extra_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 11687500)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 807069600)
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
