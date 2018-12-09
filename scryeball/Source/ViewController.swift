//
//  ViewController.swift
//  scryeball
//
//  Created by Johnny Sparks  on 9/16/18.
//  Copyright © 2018 Johnny Sparks . All rights reserved.
//

import UIKit

extension UIView {
    func boarderize() {
        layer.borderColor = UIColor.yellow.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 1
    }
}

class HandView: UIView {
    var size = 6
    var tileLabels: [UILabel] = []
    var margin: CGFloat = 2.0
    var hand: String = "" {
        didSet {
            setNeedsLayout()
            populate(hand: hand)
        }
    }

    func populate(hand: String) {
        let chars = Array(hand)
        for idx in 0..<chars.count {
            let char = chars[idx]
            let label = tileLabels[idx]
            label.text = String(char)
            label.backgroundColor = UIColor.yellow.withAlphaComponent(0.25)
            label.textColor = .white
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        for _ in 0..<size {
            let label = UILabel()
            label.textAlignment = .center
            label.boarderize()
            addSubview(label)
            tileLabels.append(label)
        }
    }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()

        let tileSize = CGSize(width: bounds.width / CGFloat(size), height: bounds.width / CGFloat(size))

        tileLabels.enumerated().forEach { idx, label in
            let origin = CGPoint(x: CGFloat(idx) * tileSize.width, y: 0)
            label.frame = CGRect(origin: origin, size: tileSize).insetBy(dx: margin, dy: margin)
        }
    }
}

class ScoreCardView: UIView {
    let label = UILabel()
}

class ViewController: UIViewController {

    let ai = RegexGameAI()
    let boardView = BoardView()
    let p1HandView = HandView()
    let p2HandView = HandView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        let board = Board()

        boardView.boarderize()
        boardView.frame = CGRect(x: 0, y: 20, width: view.bounds.width, height: view.bounds.width)
        view.addSubview(boardView)

        [p1HandView, p2HandView].forEach {
            view.addSubview($0)
        }

        p1HandView.frame = CGRect(x: 0, y: boardView.frame.maxY + 20, width: view.bounds.width / 2, height: 50.0)
        p2HandView.frame = CGRect(x: view.bounds.width / 2, y: boardView.frame.maxY + 20, width: view.bounds.width / 2, height: 50.0)

        func randMove() -> Move? {
            guard let letter = board.pickupTile() else {
                return nil
            }
            let pos = Position(x: Int.random(0..<Board.size), y: Int.random(0..<Board.size))
            return Move(position: pos, letter: letter)
        }


        let tile = board.tileBag.popLast()!
        let move = Move(position: Position(x: 7, y: 7), letter: tile)
        board.make(move: move)
        boardView.board = board



        board.initializeHands()
        ai.board = board

        self.boardView.board = board
        self.p1HandView.hand = String(board.player1Hand)
        self.p2HandView.hand = String(board.player2Hand)

//        run()

        let finder = NodeWordFinder()
        finder.setup()
    }

    func run() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let next = self.ai.play() {
                self.boardView.board = next
                self.p1HandView.hand = String(next.player1Hand)
                self.p2HandView.hand = String(next.player2Hand)
                self.ai.board = next

                if !next.tileBag.isEmpty {
                    self.run()
                }
            }
        }
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


class Wordlist {

    static var main = Wordlist(file: "") //wordlist")
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

    func copy() -> Board {
        let board = Board()
        board.letters = self.letters
        board.player1Hand = self.player1Hand
        board.player2Hand = self.player2Hand
        board.tileBag = self.tileBag
        return board
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

        guard Wordlist.main.all.contains(word) else {
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

            if let _ = res.1 {
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


