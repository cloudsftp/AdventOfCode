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
    println!("{}", content);
    let tiles = parse(content);

    let pipe_loop = walk_loop(&tiles);
    get_enclosed(&tiles, pipe_loop)
}

// Enclosed
fn get_enclosed(tiles: &Tiles, pipe_loop: Vec<(Direction, Position)>) -> usize {
    let height = tiles.len();
    let width = tiles[0].len();

    let (vert_blocks, hor_blocks) = compute_blocks(pipe_loop, height, width);
    let mut corners = vec![vec![true; width + 1]; height + 1];
    walk_corners(&mut corners, &vert_blocks, &hor_blocks);

    // print_corners(&corners, &vert_blocks, &hor_blocks);

    (0..height)
        .map(|y| {
            (0..width)
                .filter(|x| {
                    let x = *x;
                    corners[y][x] && corners[y][x + 1] && corners[y + 1][x] && corners[y + 1][x + 1]
                })
                .count()
        })
        .sum()
}

fn print_corners(
    corners: &Vec<Vec<bool>>,
    vert_blocks: &Vec<Vec<bool>>,
    hor_blocks: &Vec<Vec<bool>>,
) {
    corners
        .iter()
        .skip(1)
        .zip(hor_blocks.iter())
        .zip(vert_blocks.iter())
        .for_each(|((row_cor, row_vert), row_hor)| {
            print!("  ");
            row_hor
                .iter()
                .for_each(|b| if *b { print!("--") } else { print!("  ") });
            println!();
            row_cor.iter().zip(row_vert.iter()).for_each(|(c, b)| {
                if *c {
                    print!(".")
                } else {
                    print!(" ")
                }
                if *b {
                    print!("|")
                } else {
                    print!(" ")
                }
            });
            println!();
        });
    println!();
}

fn compute_blocks(
    pipe_loop: Vec<(Direction, Position)>,
    height: usize,
    width: usize,
) -> (Vec<Vec<bool>>, Vec<Vec<bool>>) {
    let mut vert_blocks = vec![vec![false; width - 1]; height];
    let mut hor_blocks = vec![vec![false; width]; height - 1];

    for (dir, Position { x, y }) in pipe_loop {
        match dir {
            Direction::Up => hor_blocks[y][x] = true,
            Direction::Right => vert_blocks[y][x - 1] = true,
            Direction::Down => hor_blocks[y - 1][x] = true,
            Direction::Left => vert_blocks[y][x] = true,
        }
    }

    (vert_blocks, hor_blocks)
}

fn walk_corners(
    corners: &mut Vec<Vec<bool>>,
    vert_blocks: &Vec<Vec<bool>>,
    hor_blocks: &Vec<Vec<bool>>,
) {
    walk_corners_rec(corners, vert_blocks, hor_blocks, Position { x: 0, y: 0 })
}

fn walk_corners_rec(
    corners: &mut Vec<Vec<bool>>,
    vert_blocks: &Vec<Vec<bool>>,
    hor_blocks: &Vec<Vec<bool>>,
    Position { x, y }: Position,
) {
    if !corners[y][x] {
        return;
    }
    corners[y][x] = false;

    let last_row = corners.len() - 1;
    let last_col = corners[0].len() - 1;

    // Step up
    if y > 0 && (x == 0 || x == last_col || !vert_blocks[y - 1][x - 1]) {
        walk_corners_rec(corners, vert_blocks, hor_blocks, Position { x, y: y - 1 })
    }
    // Step right
    if x < last_col && (y == 0 || y == last_row || !hor_blocks[y - 1][x]) {
        walk_corners_rec(corners, vert_blocks, hor_blocks, Position { x: x + 1, y })
    }
    // Step down
    if y < last_row && (x == 0 || x == last_col || !vert_blocks[y][x - 1]) {
        walk_corners_rec(corners, vert_blocks, hor_blocks, Position { x, y: y + 1 })
    }
    // Step left
    if x > 0 && (y == 0 || y == last_row || !hor_blocks[y - 1][x - 1]) {
        walk_corners_rec(corners, vert_blocks, hor_blocks, Position { x: x - 1, y })
    }
}

// Loop

fn walk_loop(tiles: &Tiles) -> Vec<(Direction, Position)> {
    let start = get_starting_position(&tiles);

    let (mut dir, mut curr) = first_step_loop(tiles, &start);
    let mut pipe_loop = vec![(dir.clone(), curr.clone())];

    while tiles[curr.y][curr.x] != Tile::Start {
        (dir, curr) = step_loop(tiles, curr, dir);
        pipe_loop.push((dir.clone(), curr.clone()));
    }

    pipe_loop
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

fn step_loop(tiles: &Tiles, Position { x, y }: Position, dir: Direction) -> (Direction, Position) {
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

fn first_step_loop(tiles: &Tiles, Position { x, y }: &Position) -> (Direction, Position) {
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

#[derive(Debug, Clone, Copy)]
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

#[derive(Debug, Clone, Copy)]
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
    fn test_mini() {
        let file = "mini_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 1)
    }

    #[test]
    fn test_short() {
        let file = "short_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 4)
    }

    #[test]
    fn test_medium() {
        let file = "medium_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 10)
    }

    #[test]
    fn test_long() {
        let file = "long_data";
        let mut file = File::open(file).unwrap();
        let mut content = String::new();
        file.read_to_string(&mut content).unwrap();

        let result = run(&content);
        assert_eq!(result, 305)
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
