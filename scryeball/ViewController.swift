//
//  ViewController.swift
//  scryeball
//
//  Created by Johnny Sparks  on 9/16/18.
//  Copyright © 2018 Johnny Sparks . All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let list = [
            "BALL",
            "BALM",
            "CALL",
            "CALM",
            "CLAM",
            "FALL",
        ]


        let start = Date()

        let words = Wordlist.main
        let loaded = Date()

        print("Loaded: \(words.count) words in \(loaded.timeIntervalSince(start)) sec")



        print("SEGMENTS:")
        patternsFor(template: "_M____N", withHand: "BLNAEFCMN").forEach { (regex) in

            let extractedPattern = Date()   

            print("REGEX: \(regex) - From load: \(extractedPattern.timeIntervalSince(loaded))")

            print(words.filter { $0.matches(pattern: regex) })

            let matchesFound = Date()

            print("found matches in \(matchesFound.timeIntervalSince(extractedPattern)) sec")
        }
    }
}



struct Wordlist {
    static var main: [String] = { return load(listname: "wordlist") }()
    static var test: [String] = { return load(listname: "testlist") }()

    private static func load(listname: String) -> [String] {

        guard let wordslist = Bundle.main.path(forResource: listname, ofType: "txt") else {
            print("Error: Unable to find file \(listname).txt in main bundle.")
            return []
        }

        guard let wordString = try? String(contentsOfFile: wordslist) else {
            print("Error: Unable to read file \(listname).txt in main bundle.")
            return []
        }

        return wordString.split(separator: "\n").map { String($0) }
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
}

enum Direction {
    case up
    case right
    case down
    case left
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

// Rules
// - Turn must connect to other letters, or on the first turn, touch the middle square.
// - All connected letters must form valid words
// - Multipliers only apply to _added_ pieces
// - Each word must be valid

protocol Scoreable {
    func isValid(word: String) -> Bool
}

protocol Boardlike {
    func letter(at: Position) -> Character?
    func multiplier(at: Position) -> Multiplier
    func existingMoves() -> [Move]
    func turnsAnchoredOff(move: Move, with: String) -> [Turn]
    func unverifiedTurnsFor(letters: String, startingAt: Position, direction: Direction) -> [Turn]
    func unverifiedWordsFor(turn: Turn) -> [String]
    func scoreFor(turn: Turn) -> Score
}

typealias TileConifg = (count: Int, points: Int)

class Board {
    static let size = 15

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
}

extension Board {

    func isOnBoard(position: Position) -> Bool {
        return position.x >= 0 && position.x < Board.size && position.y >= 0 && position.y < Board.size
    }

    func letter(at pos: Position) -> Character {
        return Array(letters[pos.x])[pos.y]
    }

    func multiplier(at pos: Position) -> Multiplier {
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

    func turnsAnchoredOff(move: Move, with: String) -> [Turn] {
        // unimplemnted
        return []
    }

    func unverifiedTurnsFor(letters: String, startingAt: Position, direction: Direction) -> [Turn] {
        // unimplemnted
        return []
    }

    func unverifiedWordsFor(turn: Turn) -> [String] {
        // unimplemnted
        return []
    }

    func scoreFor(turn: Turn) -> Score {
        // unimplemnted
        return 0
    }

    func templateFor(row: UInt) -> String {
        assert(row < Board.size, "Attempted to access row template not on board")

        return letters[Int(row)]
    }

    func templateFor(column: UInt) -> String {
        assert(Int(column) < Board.size, "Attempted to access row template not on board")

        return String(letters.map({ Array($0)[Int(column)] }))
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

    func match(patternWord: String, with letters: String) -> Bool {
        let matchNodes = patternWord.enumerated().compactMap { $1 == "_" ? nil : nodeMaps[$0]?[$1] }
        return false
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
    var leadingSpace: Int = 0
    var trailingSpace: Int = 0
    var string: String = ""
    var isEnding: Bool = false
    var isStarting: Bool = false
}


// A segment is end before the first space _after_ a group of characters.
// If there is no character, there are now segments.
func patternsFor(template: String, withHand: String) -> [String] {

    guard template.count > 0 else {
        return []
    }

    var fragments: [Fragment] = []
    var splits: [String] = []
    var start = 0
    while start < template.count {
        let spaceSplit = template.suffix(template.count - start).prefix(while: { $0 == "_" })
        if spaceSplit.count > 0 {
            splits.append(String(spaceSplit))
            start += spaceSplit.count
        }
        let letterSplit = template.suffix(template.count - start).prefix(while: { $0 != "_" })
        if letterSplit.count > 0 {
            splits.append(String(letterSplit))
            start += letterSplit.count
        }
    }


//    var frag = Fragment()
//    frag.isStarting = true
//    frag.isEnding = false
//    frag.leadingSpace = splits[0].count
//    frag.string = splits[1]
//    frag.trailingSpace = splits[2].count

    // prev
    // curr
    // next

    for idx in 0..<splits.count {
        let prev = idx - 1 < 0 ? nil : splits[idx - 1]
        let curr = splits[idx]
        let next = idx + 1 < splits.count ? splits[idx + 1] : nil

        // Move along, we only care about text
        if curr.contains("_") {
            continue
        }

        var frag = Fragment()
        frag.isStarting = fragments.count == 0
        frag.string = curr
        frag.leadingSpace = prev?.count ?? 0
        frag.trailingSpace = next?.count ?? 0
        frag.isEnding = next == nil || (idx + 2 == splits.count && next?.contains("_") == true)

        fragments.append(frag)
    }

    // Permute fragments
    // pairs first

    var groupedFragments: [Fragment] = []
    for groupSize in 2...fragments.count {
        for groupStart in 0...fragments.count-groupSize {
            let fragmentGroup = fragments[groupStart..<groupSize+groupStart]

            var frag = Fragment()
            frag.isStarting = fragmentGroup.first?.isStarting == true
            frag.isEnding = fragmentGroup.last?.isEnding == true
            frag.leadingSpace = fragmentGroup.first?.leadingSpace ?? 0
            frag.trailingSpace = fragmentGroup.last?.trailingSpace ?? 0
            let groupString = fragmentGroup.reduce("") { $0 + $1.string + "[%@]{\($1.trailingSpace)}" }
            frag.string = groupString.trimmingCharacters(in: CharacterSet(charactersIn: "[%@]{}0123456789"))

            groupedFragments.append(frag)
        }
        print("GROUP SIZE: \(groupSize)")
    }
    print(splits)

    let allFragments = fragments + groupedFragments

    let regexes = allFragments.map { frag -> String in
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
        return "^\(inner)$"
    }

//    print(regexes)

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






