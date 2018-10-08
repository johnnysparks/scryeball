import Foundation

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

class RegexGameAI {

    var board = Board()

    func play() -> Board? {
        let startSlow = Date()
        let hand = String(board.currentPlayerHand())

        print("STARTING TURN... \(hand)")
        let matches = bestWords()
        print(board.letters)

        guard let bestMatch = matches.first else {
            print("No matches found in \(Date().timeIntervalSince(startSlow))sec.")  //\(matches) matches.")
            return nil
        }

        let moves = bestMatch.toMoves()
        let next = board.copy().boardAfter(moves: moves)
        var oldHand = board.player1Hand
        for char in bestMatch.usedChars {
            if let idx = oldHand.lastIndex(of: char) {
                oldHand.remove(at: idx)
            }
        }

        while oldHand.count < Board.handSize && !next.tileBag.isEmpty {
            if let tile = next.tileBag.popLast() {
                oldHand.append(tile)
            }
        }

        next.player1Hand = oldHand
        print("ENDING in \(Date().timeIntervalSince(startSlow))sec, found: ")  //\(matches) matches.")

        return next
    }

    func bestWords() -> [MoveResult] {
        let matches = findMatches().map({ $0.toMatchWords() }).flatMap({ $0 })
        let results = matches.map({ board.scoreFor(turn: $0) }).flatMap({ $0 })
        let validResults: [MoveResult?] = results.map({
            let next = board.copy().boardAfter(moves: $0.toMoves())
            let score = next.secondaryScore(turn: $0)
            return score != nil ? MoveResult(points: $0.points + score!, word: $0.word, usedChars: $0.usedChars, position: $0.position, direction: $0.direction) : nil
        })
        return validResults.compactMap({ $0 }).sorted(by: { $0.points > $1.points })
    }

    func findMatches() -> [MatchResult] {
        let hand = String(board.currentPlayerHand())

        var allResults: [MatchResult] = []

        for rowCol in 0..<Board.size {
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
        let availableWords = Wordlist.main.all.filter({ $0.containsOnlyCharacters(of: validChars) })
        let results = patternsFor(template: template, withHand: hand).map { (regex) -> MatchResult in
            print("\(direction == .down ? "C: " : "R: ") \(template)")
            let matches = availableWords.filter({ $0.matches(pattern: regex.pattern) })
            return MatchResult(hand: hand, position: position, direction: direction, regex: regex, results: matches)
        }
        return results
    }
}


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
