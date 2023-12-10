#![feature(test)]

extern crate test;

use std::{fs::File, io::Read};

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
    let tiles = parse(content);

    let start = get_starting_position(&tiles);
    println!("{:?}", start);
    let length = walk(&tiles, start);

    length / 2
}

fn get_starting_position(tiles: &Tiles) -> Position {
    tiles
        .iter()
        .enumerate()
        .find_map(|(y, tile_row)| {
            tile_row
                .iter()
                .enumerate()
                .find(|(_, t)| *t == &Tile::Start)
                .map(|(x, _)| Position { x, y })
        })
        .expect("didn't find a starting tile")
}

fn walk(tiles: &Tiles, start: Position) -> usize {
    let (mut dir, mut curr) = get_connecting(tiles, &start);
    let mut len = 1;

    while tiles[curr.y][curr.x] != Tile::Start {
        (dir, curr) = step(tiles, curr, dir);
        len += 1;
    }

    len + 1
}

fn step(tiles: &Tiles, Position { x, y }: Position, dir: Direction) -> (Direction, Position) {
    let calc_result = |dir: Direction| -> (Direction, Position) {
        let (x, y) = match dir {
            Direction::Up => (x, y.checked_sub(1).expect("can't go up from here")),
            Direction::Right => (x + 1, y),
            Direction::Down => (x, y + 1),
            Direction::Left => ((x.checked_sub(1).expect("can't go left from here")), y),
        };

        if y >= tiles.len() {
            panic!("can't go down from here")
        }
        if x >= tiles[y].len() {
            panic!("can't go right from here")
        }

        (dir, Position { x, y })
    };

    match tiles[y][x] {
        Tile::Horizontal => match dir {
            Direction::Right => calc_result(Direction::Right),
            Direction::Left => calc_result(Direction::Left),
            Direction::Up | Direction::Down => unreachable!(),
        },
        Tile::Vertical => match dir {
            Direction::Up => calc_result(Direction::Up),
            Direction::Down => calc_result(Direction::Down),
            Direction::Right | Direction::Left => unreachable!(),
        },
        Tile::UpRight => match dir {
            Direction::Down => calc_result(Direction::Right),
            Direction::Left => calc_result(Direction::Up),
            Direction::Up | Direction::Right => unreachable!(),
        },
        Tile::RightDown => match dir {
            Direction::Up => calc_result(Direction::Right),
            Direction::Left => calc_result(Direction::Down),
            Direction::Right | Direction::Down => unreachable!(),
        },
        Tile::DownLeft => match dir {
            Direction::Right => calc_result(Direction::Down),
            Direction::Up => calc_result(Direction::Left),
            Direction::Down | Direction::Left => unreachable!(),
        },
        Tile::LeftUp => match dir {
            Direction::Right => calc_result(Direction::Up),
            Direction::Down => calc_result(Direction::Left),
            Direction::Up | Direction::Left => unreachable!(),
        },
        Tile::Empty | Tile::Start => unreachable!("shouldn't be executed"),
    }
}

fn get_connecting(tiles: &Tiles, Position { x, y }: &Position) -> (Direction, Position) {
    let x = *x;
    let y = *y;

    if y > 0 && tiles[y - 1][x].connects(Direction::Down) {
        (Direction::Up, Position { y: y - 1, x })
    } else if x < tiles[y].len() - 1 && tiles[y][x + 1].connects(Direction::Left) {
        (Direction::Right, Position { y, x: x + 1 })
    } else if y < tiles.len() - 1 && tiles[y + 1][x].connects(Direction::Up) {
        (Direction::Down, Position { y: y + 1, x })
    } else if x > 0 && tiles[y][x - 1].connects(Direction::Right) {
        (Direction::Left, Position { y, x: x - 1 })
    } else {
        unreachable!("starting tile should have at least one connecting neighbor")
    }
}

type Tiles = Vec<Vec<Tile>>;

#[derive(Debug)]
struct Position {
    x: usize,
    y: usize,
}

#[derive(Debug, PartialEq, Eq)]
enum Tile {
    Empty,
    Start,
    Horizontal,
    Vertical,
    UpRight,
    RightDown,
    DownLeft,
    LeftUp,
}

impl Tile {
    fn connects(&self, dir: Direction) -> bool {
        match dir {
            Direction::Up => {
                [Self::Start, Self::Vertical, Self::UpRight, Self::LeftUp].contains(self)
            }
            Direction::Right => [
                Self::Start,
                Self::Horizontal,
                Self::UpRight,
                Self::RightDown,
            ]
            .contains(self),
            Direction::Down => {
                [Self::Start, Self::Vertical, Self::RightDown, Self::DownLeft].contains(self)
            }
            Direction::Left => {
                [Self::Start, Self::Horizontal, Self::DownLeft, Self::LeftUp].contains(self)
            }
        }
    }
}

#[derive(Debug)]
enum Direction {
    Up,
    Right,
    Down,
    Left,
}

// Parsing

fn parse(content: &str) -> Tiles {
    content.lines().map(parse_line).collect()
}

fn parse_line(line: &str) -> Vec<Tile> {
    line.chars().map(Tile::from).collect()
}

impl From<char> for Tile {
    fn from(value: char) -> Self {
        match value {
            'S' => Self::Start,
            '.' => Self::Empty,
            '-' => Self::Horizontal,
            '|' => Self::Vertical,
            'L' => Self::UpRight,
            'F' => Self::RightDown,
            '7' => Self::DownLeft,
            'J' => Self::LeftUp,
            _ => unreachable!("should not be contained in the input"),
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
        assert_eq!(result, 8)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 6831)
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
