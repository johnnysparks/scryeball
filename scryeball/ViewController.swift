//
//  ViewController.swift
//  scryeball
//
//  Created by Johnny Sparks  on 9/16/18.
//  Copyright © 2018 Johnny Sparks . All rights reserved.
//

import UIKit

extension String: Error { }

extension Int {
    static func random(_ range: CountableRange<Int>) -> Int {
        let rand = Float(arc4random()) / Float(UInt32.max)
        return range.lowerBound + Int(Float(range.upperBound - range.lowerBound) * rand)
    }

    func times(_ execute: () -> ()) {
        guard self > 0 else { return }
        for _ in 0..<self {
            execute()
        }
    }
}

extension UIView {
    func boarderize() {
        layer.borderColor = UIColor.yellow.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 1
    }
}

class ViewController: UIViewController {

    let boardView = BoardView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let board = Board()

        boardView.boarderize()
        boardView.frame = CGRect(x: 0, y: 20, width: view.bounds.width, height: view.bounds.width)
        view.addSubview(boardView)

        func randMove() -> Move? {
            guard let letter = board.pickupTile() else {
                return nil
            }
            let pos = Position(x: Int.random(0..<3), y: Int.random(0..<3))
            return Move(position: pos, letter: letter)
        }

        5.times {
            guard let move = randMove() else {
                return
            }

            board.make(move: move)
            boardView.board = board
        }

        let ai = GameAI()
        board.initializeHands()
        ai.board = board
        boardView.board = ai.play()
        DispatchQueue.main.async {
            ai.board = self.boardView.board
            self.boardView.board = ai.play()
        }
    }
}

extension String {
    func containsOnlyCharacters(of other: String) -> Bool {
        var this = self
        for character in other {
            if let idx = this.index(of: character) {
                this.remove(at: idx)
            }
        }
        return this.count == 0
    }
}

extension FixedWidthInteger {
    func exp(_ power: Self) -> Self {
        var ret = self
        for _ in 0..<Int(power) {
            ret = ret * self
        }
        return ret
    }
}

extension String {

    /// IRONICALLY, NOT FAST
    func containsOnlyCharactersFast(of other: String) -> Bool {
        var bitmap: Int = 0
        for character in other {
            var start = 0
            while start < self.count {
                let str = start == 0 ? Substring(self) : self.suffix(self.count - start)
                guard let idx = str.index(of: character) else {
                    break
                }

                let position = 2.exp(idx.encodedOffset)
                if bitmap & position != position {
                    bitmap = bitmap + position
                    break
                }

                start += idx.encodedOffset + 1
            }
        }

        return bitmap.nonzeroBitCount == self.count
    }
}


class BoardView: UIView {
    var size = 15
    var tileLabels: [[UILabel]] = []
    var margin: CGFloat = 2.0
    var board: Board = Board() {
        didSet {
            setNeedsLayout()
            populate(board: board)
        }
    }

    func populate(board: Board) {

        for row in 0..<size {
            for col in 0..<size {
                let label = tileLabels[row][col]
                let position = Position(x: col, y: row)
                let multiplier = board.multiplier(at: position)
                let character = board.letter(at: position)
                label.text = character != nil ? String(character!) : ""
                label.backgroundColor = multiplier.backgroundColor
                label.textColor = .white
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        for _ in 0..<size {
            var labelRow: [UILabel] = []
            for _ in 0..<size {
                let label = UILabel()
                label.textAlignment = .center
                label.boarderize()
                addSubview(label)
                labelRow.append(label)
            }
            tileLabels.append(labelRow)
        }
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let tileSize = CGSize(width: bounds.width / CGFloat(size), height: bounds.height / CGFloat(size))

        tileLabels.enumerated().forEach { row, labelRow in
            labelRow.enumerated().forEach({ col, label in
                let origin = CGPoint(x: CGFloat(col) * tileSize.width, y: CGFloat(row) * tileSize.height)
                label.frame = CGRect(origin: origin, size: tileSize).insetBy(dx: margin, dy: margin)
            })
        }
    }
}


class GameAI {

    var board = Board()

    func play() -> Board {
        let startSlow = Date()
        let hand = String(board.currentPlayerHand())

        print("STARTING TURN... \(hand)")
        let matches = bestWords()
        print(board.letters)
        var next = board.boardAfter(moves: matches.first!.toMoves())
        print(next.letters)

        print("ENDING in \(Date().timeIntervalSince(startSlow))sec, found: ")  //\(matches) matches.")
        return next
    }

    func bestWords() -> [MoveResult] {
        let matches = findMatches().map({ $0.toMatchWords() }).flatMap({ $0 })
        let results = matches.map({ board.scoreFor(turn: $0) }).flatMap({ $0 })
        let validResults: [MoveResult?] = results.map({
            let next = board.boardAfter(moves: $0.toMoves())
            let score = next.secondaryScore(turn: $0)
            return score != nil ? MoveResult(points: $0.points + score!, word: $0.word, usedChars: $0.usedChars, position: $0.position, direction: $0.direction) : nil
        })
        return validResults.compactMap({ $0 }).sorted(by: { $0.points > $1.points })
    }

    func findMatches() -> [MatchResult] {
        let hand = String(board.currentPlayerHand())

        var allResults: [MatchResult] = []

        for rowCol in 0..<3 {//Board.size {
            let rowTemplate = board.templateFor(row: rowCol)
            let colTemplate = board.templateFor(column: rowCol)

            allResults += resultsFor(template: rowTemplate, hand: hand, direction: .right, position: Position(x: 0, y: rowCol))
            allResults += resultsFor(template: colTemplate, hand: hand, direction: .down, position: Position(x: rowCol, y: 0))
        }

        return allResults
    }

    func resultsFor(template: String, hand: String, direction: Direction, position: Position) -> [MatchResult] {
        let filteredTemplate = template.filter({ $0 != "_" })
        guard filteredTemplate != "" else {
            return []
        }
        let validChars = (filteredTemplate + hand)
        let availableWords = Wordlist.main.long.filter({ $0.containsOnlyCharacters(of: validChars) })
        let results = patternsFor(template: template, withHand: hand).map { (regex) -> MatchResult in
            print("\(direction == .down ? "C: " : "R: ") \(template)")
            let matches = availableWords.filter({ $0.matches(pattern: regex.pattern) })
            return MatchResult(hand: hand, position: position, direction: direction, regex: regex, results: matches)
        }
        return results
    }

//    func resultsFor(template: String, hand: String, row: Int?, col: Int?) -> [MatchResult] {
//        let filteredTemplate = template.filter({ $0 != "_" })
//        guard filteredTemplate != "" else {
//            return []
//        }
//        let validChars = (filteredTemplate + hand)
//        let availableWords = Wordlist.main.long.filter({ $0.containsOnlyCharacters(of: validChars) })
//        let results = patternsFor(template: template, withHand: hand).map { (regex) -> MatchResult in
//            print("\(row == nil ? "C: " : "R: ") \(template)")
//            let matches = availableWords.filter({ $0.matches(pattern: regex.pattern) })
//            return MatchResult(row: row, col: col, regex: regex, results: matches)
//        }
//        return results
//    }
}



class Wordlist {

    static var main = Wordlist(file: "wordlist")
    static var test = Wordlist(file: "testlist")

    var all: [String] = []
    var long: [String] = []

    init(file: String) {
        load(listname: file)
    }

    private func load(listname: String) {

        guard let wordslist = Bundle.main.path(forResource: listname, ofType: "txt") else {
            print("Error: Unable to find file \(listname).txt in main bundle.")
            return
        }

        guard let wordString = try? String(contentsOfFile: wordslist) else {
            print("Error: Unable to read file \(listname).txt in main bundle.")
            return
        }

        all = wordString.split(separator: "\n").map { String($0) }
        long = all.filter { $0.count > 3 }
    }
}


enum Multiplier {
    case word(value: Int)
    case letter(value: Int)
    case none

    static func from(_ character: Character) -> Multiplier {
        switch character {
        case "W":
            return .word(value: 3)
        case "w":
            return .word(value: 2)
        case "L":
            return .letter(value: 3)
        case "l":
            return .letter(value: 2)
        default:
            return .none
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .word(let value):
            return UIColor.blue.withAlphaComponent(value == 3 ? 0.5 : 0.25)
        case .letter(let value):
            return UIColor.green.withAlphaComponent(value == 3 ? 0.5 : 0.25)
        case .none:
            return UIColor.lightGray.withAlphaComponent(0.25)
        }
    }
}

enum Direction {
    case right
    case down

    var other: Direction {
        switch self {
        case .right: return .down
        case .down: return .right
        }
    }
}

struct Position {
    let x: Int
    let y: Int
}

struct Move {
    let position: Position
    let letter: Character
}

typealias Turn = [Move]
typealias Score = Int

typealias TileConifg = (count: Int, points: Int)

class Board {
    static let size = 15
    static let handSize = 6

    var letters: [String] = [
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
        "_______________",
    ]

    static let multipliers = [
        "W__l___W___l__W",
        "_w___L___L___w_",
        "__w___l_l___w__",
        "___w___l___w___",
        "____w_____w____",
        "_L___L___L___L_",
        "__l___l_l___l__",
        "W__l_______l__W",
        "__l___l_l___l__",
        "_L___L___L___L_",
        "____w_____w____",
        "___w___l___w___",
        "__w___l_l___w__",
        "_w___L___L___w_",
        "W__l___W___l__W",
    ]

    static let tileConfig: [Character: TileConifg] = [
        "A": (9, 1),
        "B": (2, 3),
        "C": (2, 3),
        "D": (2, 4),
        "E": (12, 1),
        "F": (2, 4),
        "G": (3, 2),
        "H": (2, 4),
        "I": (9, 1),
        "J": (1, 8),
        "K": (1, 5),
        "L": (4, 1),
        "M": (2, 3),
        "N": (6, 1),
        "O": (8, 1),
        "P": (2, 3),
        "Q": (1, 10),
        "R": (6, 1),
        "S": (4, 1),
        "T": (6, 1),
        "U": (4, 1),
        "V": (2, 4),
        "W": (2, 4),
        "X": (1, 8),
        "Y": (2, 4),
        "Z": (1, 10),
    ]

    static func makeBag() -> [Character] {
        return Board.tileConfig.enumerated().map({ Array(repeating: $1.key, count: $1.value.count) }).flatMap({ $0 })
    }

    func points(for char: Character) -> Int {
        return Board.tileConfig[char]?.points ?? -1 // -1 for some error
    }

    lazy var tileBag: [Character] = { return Board.makeBag() }()
    func pickupTile() -> Character? {
        guard tileBag.count > 0 else {
            return nil
        }
        let removeAt = Int.random(0..<tileBag.count)
        return tileBag.remove(at: removeAt)
    }

    var player1Hand: [Character] = []
    var player2Hand: [Character] = []

    func currentPlayerHand() -> [Character] {
        return player1Hand
    }

    func initializeHands() {
        Board.handSize.times {
            if let tile = pickupTile() {
                player1Hand.append(tile)
            }

            if let tile = pickupTile() {
                player2Hand.append(tile)
            }
        }
    }
}

struct MoveResult {
    let points: Int
    let word: String
    let usedChars: String
    let position: Position
    let direction: Direction

    func toMoves() -> [Move] {
        switch direction {
        case .right:
            return Array(word).enumerated().map { Move(position: Position(x: position.x + $0.offset, y: position.y), letter: $0.element) }
        case .down:
            return Array(word).enumerated().map { Move(position: Position(x: position.x, y: position.y + $0.offset), letter: $0.element) }
        }
    }
}

extension Board {

    func isOnBoard(position: Position) -> Bool {
        return position.x >= 0 && position.x < Board.size && position.y >= 0 && position.y < Board.size
    }

    func letter(at pos: Position) -> Character? {
        guard isOnBoard(position: pos) else {
            print("Looking for invalid letter position: \(pos)")
            return nil
        }

        let char = Array(letters[pos.y])[pos.x]
        return char == "_" ? nil : char
    }

    func multiplier(at pos: Position) -> Multiplier {
        guard isOnBoard(position: pos) else {
            print("Looking for invalid multiplier position: \(pos)")
            return .none
        }

        return Multiplier.from(Array(Board.multipliers[pos.x])[pos.y])
    }

    func existingMoves() -> [Move] {
        var moves: [Move] = []
        letters.enumerated().forEach { y, row in
            row.enumerated().forEach({ x, letter in
                moves.append(Move(position: Position(x: x, y: y), letter: letter))
            })
        }
        return moves
    }

    func make(move: Move) {
        var chars = Array(letters[move.position.y])
        chars[move.position.x] = move.letter
        letters[move.position.y] = String(chars)
    }

    func boardAfter(moves: [Move]) -> Board {
        let next = self
        moves.forEach { next.make(move: $0) }
        return next
    }

    func scoreFor(turn: MatchWord) -> [MoveResult] {

        print("\(turn.position), \(turn.direction == .down ? "⬇️" : "➡️") \(turn.string)")

        if !isOnBoard(position: turn.position) {
            return []
        }

        let dir = turn.direction
        var moveResults: [MoveResult] = []
        var increment = 0

        while increment < Board.size - turn.string.count {

            var played: String = ""
            var wordMultiplier = 1
            var wordPoints = 0
            var intersected: Bool = false
            var mismatch: Bool = false

            for idx in 0..<turn.string.count {

                let pos = Position(x: dir == .right ? increment + idx : turn.position.x,
                                   y: dir == .down ? increment + idx : turn.position.y)

                let char = Array(turn.string)[idx]

                var letterPoints = points(for: char)

                if let existingChar = letter(at: pos) {
                    intersected = true
                    if existingChar != char {
                        mismatch = true
                        break
                    }
                } else {
                    switch multiplier(at: pos) {
                    case .word(let x):
                        wordMultiplier *= x
                    case .letter(let x):
                        letterPoints += x
                    case .none: break
                    }
                    played.append(char)
                }

                wordPoints += letterPoints
            }

            if intersected && !mismatch {
                if turn.direction == .right {
                    print("R: "+String(Array(repeating: "_", count: increment) + Array(turn.string)))
                    print("R: "+templateFor(row: turn.position.y) + "\n")
                } else {
                    print("C: "+String(Array(repeating: "_", count: increment) + Array(turn.string)))
                    print("C: "+templateFor(column: turn.position.x) + "\n")
                }

                moveResults.append(MoveResult(points: wordPoints * wordMultiplier,
                                              word: turn.string,
                                              usedChars: played,
                                              position: Position(x: dir == .right ? increment : turn.position.x,
                                                                 y: dir == .down ? increment : turn.position.y),
                                              direction: dir))
            }

            increment += 1
        }

        return moveResults
    }

    func secondaryWordScore(inDirection dir: Direction, intersecting: Position) -> (MoveResult?, Error?) {

        func position(at offset: Int) -> Position {
            // word in col, intersecting row
            return dir == .right
                ? Position(x: offset, y: intersecting.y)
                : Position(x: intersecting.x, y: offset)
        }

        let idx = dir == .right ? intersecting.x : intersecting.y
        var start = idx
        var end = idx
        var wordMultiplier = 1
        var wordScore = 0
        var inWord = true

        var pos = position(at: idx)
        while inWord {
            pos = position(at: start - 1)
            if isOnBoard(position: pos) && letter(at: pos) != nil {
                start -= 1
            } else {
                inWord = false
            }
        }

        inWord = true
        while inWord {
            pos = position(at: end)
            if isOnBoard(position: pos) && letter(at: pos) != nil {
                end += 1
            } else {
                inWord = false
            }
        }

        for charIdx in start..<end {
            pos = position(at: charIdx)
            guard let char = letter(at: pos) else {
                continue
            }
            var letterPoints = points(for: char)

            if idx == charIdx {
                switch multiplier(at: pos) {
                case .letter(let value):
                    letterPoints *= value
                case .word(let value):
                    wordMultiplier *= value
                case .none: break
                }
            }

            wordScore += letterPoints
        }

        guard end - start > 1 else {
            return (nil, nil)
        }

        let pattern = template(in: dir, offset: dir == .right ? intersecting.y : intersecting.x)
        let word = String(Array(pattern)[start..<end])

        guard Wordlist.main.long.contains(word) else {
            return (nil, "Invalid Word")
        }

        return (MoveResult(points: wordScore * wordMultiplier,
                          word: word,
                          usedChars: "",
                          position: position(at: start),
                          direction: dir), nil)
    }


    func secondaryScore(turn: MoveResult) -> Int? {
        // skip intersecting row

        // validate that any other range of intersecting letters is a word
        var scores: [MoveResult] = []
        let x = turn.position.x
        let y = turn.position.y
        let dir = turn.direction
        for idx in 0..<turn.word.count {
            let pos = Position(x: dir == .right ? x + idx : y,
                               y: dir == .right ? y : x + idx)
            let res = secondaryWordScore(inDirection: dir.other, intersecting: pos)

            if let error = res.1 {
                print(error)
                return nil
            }

            if let score = res.0, res.1 == nil {
                scores.append(score)
            }
        }

        return scores.reduce(0, { $0 + $1.points })
    }

    func template(in direction: Direction, offset: Int) -> String {
        assert(offset >= 0 && offset < Board.size, "Attempted to access template not on board")

        if direction == .right {
            return letters[offset]
        } else {
            return String(letters.map({ Array($0)[offset] }))
        }
    }

    func templateFor(row: Int) -> String {
        assert(row >= 0 && row < Board.size, "Attempted to access row template not on board")

        return letters[row]
    }

    func templateFor(column: Int) -> String {
        assert(column >= 0 && column < Board.size, "Attempted to access row template not on board")

        return String(letters.map({ Array($0)[column] }))
    }
}


// BALL
// BALM
// CALL
// CALM

class Node<T: Hashable>: CustomStringConvertible {
    var succeeding: [T:Node<T>] = [:]
    var preceding: [T:Node<T>] = [:]
    var value: T

    init(value: T) {
        self.value = value
    }

    func suffix(values: [T]) {
        guard let next = values.first else {
            return
        }

        let succeedingValues = Array(values.dropFirst())
        let succeedingNode = succeeding[next] ?? Node<T>(value: next)
        succeedingNode.suffix(values: succeedingValues)
        succeeding[next] = succeedingNode
    }

    func prefix(values: [T]) {
        guard let prev = values.last else {
            return
        }

        let precedingValues = Array(values.dropLast())
        let precedingNode = preceding[prev] ?? Node<T>(value: prev)
        precedingNode.suffix(values: precedingValues)
        preceding[prev] = precedingNode
    }

    var description: String {
        return "VAL: \(value), preceding: \(preceding.count) succeeding: \(succeeding.count)"
    }
}

class WordMap {
    var nodeMaps: [Int: [Character: Node<Character>]] = [:]

    func load(word: String) {
        let letters = Array(word)
        for offset in 0..<letters.count {
            let letter = letters[offset]
            var nodesForOffset = nodeMaps[offset] ?? [:]
            let node: Node<Character> = nodesForOffset[letter] ?? Node<Character>(value: letter)

            node.prefix(values: Array(word.dropLast(word.count - offset)))
            node.suffix(values: Array(word.dropFirst(offset + 1)))
            print("offset: \(offset), node: \(node)")

            nodesForOffset[letter] = node
            nodeMaps[offset] = nodesForOffset
        }
    }
}

extension String {
    func permute() -> Set<String> {

        let list = Array(self).map { String($0) }

        let minStringLen = 2

        func permute(fromList: [String], toList: [String], minStringLen: Int, set: inout Set<String>) {
            if toList.count >= minStringLen {
                set.insert(toList.joined(separator: ""))
            }
            if !fromList.isEmpty {
                for (index, item) in fromList.enumerated() {
                    var newFrom = fromList
                    newFrom.remove(at: index)
                    permute(fromList: newFrom, toList: toList + [item], minStringLen: minStringLen, set: &set)
                }
            }
        }

        var set = Set<String>()
        permute(fromList: list, toList:[], minStringLen: minStringLen, set: &set)
        return set
    }

    func sortedPermute() -> [String] {
        let list = self.sorted()
        var groups: [String] = []

        guard list.count > 2 else {
            return [String(list)]
        }

        for groupSize in 2..<list.count {
            for start in 0...list.count-groupSize {
                let group = list[start..<start+groupSize]
                groups.append(String(group))
            }
        }

        return groups
    }

    func matches(pattern: String) -> Bool {
        guard let rx = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) else {
            print("FAILD TO CREATE REGEX: \(pattern)")
            return false
        }

        let matx = rx.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))

        if matx.count > 0 {
            print(self)
        }
        return matx.count > 0
    }
}

// Find a match for pattern examples
// Basic: Max score that contains T
// ____________T____________

// Constrained
// 1D Constrained: MAX score that contains T and S one space apart
// __________T_S____________

// Constrained, max length, maxium preceding characters
// _T_S_______________

// Constrined, maximum following characters
// ______________T_S_
//


// Step 1. Can handle a whole row with regex, as long as the word is continuous.
// ___FETCH__T_R__ eg: TORN
//
// Needs to anchor to one or more of the above groups. ie.
// ___FETCH_
// _T
// R__
// ___FETCH__T
// _T_R__
// ___FETCH_T_R__

// Algo, segment one at a time, then two at a time, then 3 at a time, etc.

// Step 2:
// Validate cross section words
// _______________
// _______________
// _______________
// ______F________
// ______E________
// ______T________
// ______CITE_____
// ______H_H______
// ________A______
// ________N______
// ______TAKE_____
// ______ON_______
// _____ART_______
// ______N________
// _______________

// Step 3:
// Add cross section words to score, or reject word.

struct Fragment {
    var templateOffset: Int = 0
    var leadingSpace: Int = 0
    var trailingSpace: Int = 0
    var string: String = ""
    var isEnding: Bool = false
    var isStarting: Bool = false
}

struct AnchoredRegex {
    let patternOffset: Int
    let pattern: String
}

struct MatchResult {
    let hand: String
    let position: Position
    let direction: Direction
    let regex: AnchoredRegex
    let results: [String]

    func toMatchWords() -> [MatchWord] {
        return results.map { MatchWord(position: position, direction: direction, string: $0, hand: hand) }
    }
}

struct MatchWord {
    let position: Position
    let direction: Direction
    let string: String
    let hand: String
}

// A segment is end before the first space _after_ a group of characters.
// If there is no character, there are now segments.
func patternsFor(template: String, withHand: String) -> [AnchoredRegex] {

    guard template.count > 0 else {
        return []
    }

    var fragments: [Fragment] = []
    var splitStarts: [Int] = [0]
    var splits: [String] = []
    var start = 0
    while start < template.count {
        let spaceSplit = template.suffix(template.count - start).prefix(while: { $0 == "_" })
        if spaceSplit.count > 0 {
            splits.append(String(spaceSplit))
            splitStarts.append(template.count - start)
            start += spaceSplit.count
        }
        let letterSplit = template.suffix(template.count - start).prefix(while: { $0 != "_" })
        if letterSplit.count > 0 {
            splits.append(String(letterSplit))
            splitStarts.append(template.count - start)
            start += letterSplit.count
        }
    }

    for idx in 0..<splits.count {
        let prev = idx - 1 < 0 ? nil : splits[idx - 1]
        let curr = splits[idx]
        let next = idx + 1 < splits.count ? splits[idx + 1] : nil

        // Move along, we only care about text
        if curr.contains("_") {
            continue
        }

        print("SPLITS \(splits) \(splitStarts)")

        var frag = Fragment()
        frag.templateOffset = splitStarts[idx]
        frag.isStarting = fragments.count == 0
        frag.string = curr
        frag.leadingSpace = prev?.count ?? 0
        frag.trailingSpace = next?.count ?? 0
        frag.isEnding = next == nil || (idx + 2 == splits.count && next?.contains("_") == true)
//        frag.template = [prev, curr, next].compactMap { $0 }.joined()

        fragments.append(frag)
    }

    // Permute fragments
    // pairs first

    var groupedFragments: [Fragment] = []

    if fragments.count > 2 {
        for groupSize in 2...fragments.count {
            for groupStart in 0...fragments.count-groupSize {
                let fragmentGroup = fragments[groupStart..<groupSize+groupStart]

                guard let first = fragmentGroup.first, let last = fragmentGroup.last else {
                    print("ERROR BUILDING FRAGMENT GROUPS!!")
                    break
                }

                var frag = Fragment()
                frag.templateOffset = first.templateOffset
                frag.isStarting = first.isStarting
                frag.isEnding = last.isEnding
                frag.leadingSpace = first.leadingSpace
                frag.trailingSpace = last.trailingSpace
                let groupString = fragmentGroup.reduce("") { $0 + $1.string + "[%@]{\($1.trailingSpace)}" }
                frag.string = groupString.trimmingCharacters(in: CharacterSet(charactersIn: "[%@]{}0123456789"))
//                frag.template = fragmentGroup.map({ $0.template }).joined()

                groupedFragments.append(frag)
            }
            print("GROUP SIZE: \(groupSize)")
        }
    }

    let allFragments = fragments + groupedFragments

    let regexes = allFragments.map { frag -> AnchoredRegex in
        let leadingSpace = frag.leadingSpace - (frag.isStarting ? 0 : 1)
        let trailingSpace = frag.trailingSpace - (frag.isEnding ? 0 : 1)
        var str = ""
        if leadingSpace > 0{
            str += "[%@]{0,\(leadingSpace)}"
        }
        str += frag.string
        if trailingSpace > 0 {
            str += "[%@]{0,\(trailingSpace)}"
        }
        let inner = str.replacingOccurrences(of: "%@", with: withHand)
        return AnchoredRegex(patternOffset: frag.templateOffset, pattern: "^\(inner)$")
    }

    return regexes.reversed()
}




// cab
// idx 0, count: 3
// letter = c
// node = Node('c')
// prefix dropLast( word.count=3, offset=0, result=3 ) prefix = []
// suffix dropFirst( offset+1=1, result=1 ) suffix = ab

// cab
// idx 1, count: 3
// letter = a
// node = Node('a')
// prefix dropLast( word.count=3, offset=1, result=2 ) prefix = [c]
// suffix dropFirst( offset+1=2, result=2 ) suffix = [b]






