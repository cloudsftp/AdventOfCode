use std::{fs::File, io::Read};

const WORDS: [&str; 9] = [
    "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
];

fn main() {
    let mut file = File::open("big_test_file").unwrap();

    let mut content: String = "".to_string();
    file.read_to_string(&mut content).unwrap();

    let mut calibration_numbers = vec![];

    for line in content.lines() {
        let mut new_line = "".to_string();

        for i in 0..line.len() {
            for (j, word) in WORDS.iter().enumerate() {
                if line.get(i..).unwrap().starts_with(word) {
                    new_line += (j + 1).to_string().as_str();
                    continue;
                }
            }
            new_line += line.chars().nth(i).unwrap().to_string().as_str();
        }

        let digits = new_line
            .chars()
            .filter(|c| c.is_digit(10))
            .collect::<Vec<_>>();

        let (c1, c2) = match digits.len() {
            0 => panic!("{}", line),
            1 => {
                let c = digits.first().expect("does exist");
                (c, c)
            }
            _ => (
                digits.first().expect("does exist"),
                digits.last().expect("does exist"),
            ),
        };

        let val = format!("{}{}", c1, c2)
            .parse::<u32>()
            .expect("all should be legal");

        calibration_numbers.push(val)
    }

    let result: u32 = calibration_numbers.iter().sum();

    println!("{}", result)
}
