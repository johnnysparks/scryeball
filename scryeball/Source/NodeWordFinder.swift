import Foundation

struct CharacterOffset {
    let character: Character
    var offset: Int

    init(_ character: String, at offset: Int) {
        self.character = Character(character)
        self.offset = offset
    }
}

class Node<T: Hashable>: CustomStringConvertible {
    var children: [T:Node<T>] = [:]
    var value: T
    var parent: Node<T>?
    var isTerminal = false

    init(value: T, parent: Node<T>?) {
        self.value = value
        self.parent = parent
    }

    func suffix(values: [T]) {
        guard let next = values.first else {
            isTerminal = true
            return
        }

        let succeedingValues = Array(values.dropFirst())
        let succeedingNode = children[next] ?? Node<T>(value: next, parent: self)
        succeedingNode.suffix(values: succeedingValues)
        children[next] = succeedingNode
    }

    func suffixes() -> [[T]] {
        var all: [[T]] = []
        if isTerminal {
            all.append([value])
        }
        for next in children.values {
            for suffix in next.suffixes() {
                all.append([value] + suffix)
            }
        }
        return all
    }

    func prefix() -> [T] {
        var all: [T] = []

        var prev = parent
        while let val = prev?.value {
            all.insert(val, at: 0)
            prev = prev?.parent
        }
        return all
    }

    func sequences() -> [[T]] {
        var all: [[T]] = []
        let prefix = self.prefix()
        for suffix in suffixes() {
            all.append(prefix + suffix)
        }
        return all
    }

    func countTerminals() -> Int {
        return children.reduce(isTerminal ? 1 : 0) { $0 + $1.value.countTerminals() }
    }

    var description: String {
        return "VAL: \(value), preceding: \(prefix().count) succeeding: \(children.count) terminal: \(isTerminal)"
    }
}


protocol WordFinder {
    func load(words: [String])
    func words() -> [String]
    func findWords(for: [CharacterOffset]) -> [String]
}


class NodeWordFinder: WordFinder, CustomStringConvertible {
    var nodeMap: [Character: Node<Character>] = [:]

    func setup() {
        load(words: Wordlist.test.all)
    }

    func clear() {
        nodeMap = [:]
    }

    func load(words: [String]) {
        for word in words {
            load(word: word)
        }
    }

    func words() -> [String] {
        return nodeMap.mapValues({ $0.sequences().map({ String($0) }) }).flatMap({ $0.value })
    }

    func load(word: String) {
        let letters = Array(word)
        guard let letter = letters.first else {
            return
        }

        let node: Node<Character> = nodeMap[letter] ?? Node<Character>(value: letter, parent: nil)

        node.suffix(values: Array(word.dropFirst()))

        nodeMap[letter] = node
    }

    func findWords(for offsets: [CharacterOffset]) -> [String] {
        guard offsets.count > 0 else {
            return []
        }

        var nodes: [Node<Character>] = nodeMap.map({ $1 })
        let lastOffset = offsets.map({ $0.offset }).max()!

        for offset in 0...lastOffset {
            if let character = offsets.first(where: { $0.offset == offset })?.character {
                nodes = nodes.filter({ $0.value == character }).map({ $0.children.values }).flatMap({ $0 })
            } else {
                nodes = nodes.map({ $0.children.values }).flatMap({ $0 })
            }
        }

        return Array(Set(nodes.map({ $0.sequences().map({ String($0) }) }).flatMap({ $0 })))
    }

    func findWords(for offsetChar: CharacterOffset) -> [String] {

        var nodes: [Node<Character>] = nodeMap.map({ $1 })
        var searchNodes: [Node<Character>] = nodes

        offsetChar.offset.times {
            for node in nodes {
                searchNodes.append(contentsOf: node.children.map({ $1 }))
            }
            nodes = searchNodes
        }

        let words = searchNodes.filter({ $0.value == offsetChar.character }).map({ $0.sequences().map({ String($0) }) })

        return words.flatMap({ $0 })
    }

    var description: String {
        var out = ""

        for (_, node) in nodeMap {
            out += "\t\(node)\n"
        }

        out += "All words counted: \(nodeMap.first!.value.countTerminals())"
        return out
    }
}
