use std::{fs::File, io::Read};

fn main() {
    let mut file = File::open("big_test_file").unwrap();

    let mut content: String = "".to_string();
    file.read_to_string(&mut content).unwrap();

    let mut calibration_numbers = vec![];

    for line in content.split("\n") {
        if line.len() == 0 {
            continue;
        }

        let digits = line.chars().filter(|c| c.is_digit(10)).collect::<Vec<_>>();
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
