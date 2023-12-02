use std::{collections::HashMap, str::Chars};

#[derive(Debug)]
pub struct TNode {
    pub value: Option<u32>,
    pub next: HashMap<char, Self>,
}

impl TNode {
    pub fn new() -> Self {
        TNode {
            value: None,
            next: HashMap::new(),
        }
    }

    pub fn add(&mut self, word: &str, value: u32) {
        self.add_rec(&mut word.chars(), value)
    }

    fn add_rec(&mut self, word: &mut Chars, value: u32) {
        match word.next() {
            None => self.value = Some(value),
            Some(c) => self
                .next
                .entry(c)
                .or_insert(Self::new())
                .add_rec(word, value),
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_create() {
        let mut root = TNode::new();

        root.add("one", 1);
        root.add("two", 2);
        root.add("three", 3);

        assert!(root.value.is_none());
        assert_eq!(root.next.len(), 2);

        let o = root.next.get(&'o').unwrap();
        assert!(o.value.is_none());
        assert_eq!(o.next.len(), 1);

        let n = o.next.get(&'n').unwrap();
        assert!(n.value.is_none());
        assert_eq!(n.next.len(), 1);

        let e = n.next.get(&'e').unwrap();
        assert!(e.value.is_some_and(|v| v == 1));
        assert_eq!(e.next.len(), 0);
    }
}
