//
//  scryeballTests.swift
//  scryeballTests
//
//  Created by Johnny Sparks  on 11/11/18.
//  Copyright © 2018 Johnny Sparks . All rights reserved.
//

import Foundation
import XCTest
@testable import scryeball

let testWords = ["A", "ABOUT", "AFTER", "ALTER", "AGAIN", "AIR", "ALL", "ALTERED", "ALSO", "AMERICA", "AN", "AND", "ANIMAL", "ANOTHER", "ANSWER", "ANY", "ARE", "AROUND"].sorted()
let words2ndLetterN = ["AN", "AND", "ANIMAL", "ANOTHER", "ANSWER", "ANY"].sorted()
let words3rdLetterO = ["ABOUT", "ANOTHER", "AROUND"].sorted()
let words3rdLetterOLastD = ["AROUND"]

let messyIn = ["PANPSYCHISM", "SANPRO", "PANPIPE", "MANPOWERS", "PANPSYCHISTIC", "PANPHARMACONS", "SCHWANPANS", "BEANPOLES", "BEANPOLE", "PANPHARMACON", "WOOMANPOWERS", "PANPSYCHIST", "SCHWANPAN", "VANPOOL", "VANPOOLING", "SWANPAN", "PANPSYCHISTS", "SWANPANS", "WOMANPOWER", "RANPIKES", "PANPIPES", "VANPOOLS", "SANPANS", "PANPSYCHISMS", "MANPOWER", "VANPOOLINGS", "MANPACK", "MANPACKS", "SANPROS", "ROANPIPE", "ROANPIPES", "RANPIKE", "SANPAN"].sorted()

// 4: A, 5: N, 6: P
let messyOut = ["SCHWANPANS", "SCHWANPAN", "WOOMANPOWER", "WOOMANPOWERS"].sorted()

class NodeWordFinderTests: XCTestCase {

    func testLoadWords() {
        let finder = NodeWordFinder()
        finder.load(words: testWords)
        let words = finder.words()
        XCTAssertEqual(words.count, testWords.count)
        XCTAssert(testWords.elementsEqual(words.sorted()))
    }

    func skip_testLoadWordsPerformace() {
        self.measure {
            let finder = NodeWordFinder()
            finder.load(words: Wordlist.test.all)
        }
    }

    func testFindWords() {
        let char = CharacterOffset("A", at: 0)
        let finder = NodeWordFinder()
        finder.load(words: testWords)
        let words = finder.findWords(for: char).sorted()
        XCTAssert(testWords.elementsEqual(words),
                  "\nEXPECTED:\n \(words)\n\nTO BE:\n\(testWords)")
    }

    func testFindWordsMultipleOffsets() {
        let a0char = CharacterOffset("A", at: 0)
        let n1char = CharacterOffset("N", at: 1)
        let finder = NodeWordFinder()
        finder.load(words: testWords)
        let words = finder.findWords(for: [a0char, n1char]).sorted()
        XCTAssert(words2ndLetterN.elementsEqual(words),
                  "\nEXPECTED:\n \(words)\n\nTO BE:\n\(words2ndLetterN)")
    }

    func testRemovesShortWords() {
        let n2Char = CharacterOffset("O", at: 2)
        let finder = NodeWordFinder()
        finder.load(words: testWords)
        let words = finder.findWords(for: [n2Char]).sorted()
        XCTAssert(words3rdLetterO.elementsEqual(words),
                  "\nEXPECTED:\n \(words)\n\nTO BE:\n\(words3rdLetterO)")
    }

    func testRemovesShortWordsLastLetterD() {
        let n2Char = CharacterOffset("O", at: 2)
        let n5Char = CharacterOffset("D", at: 5)
        let finder = NodeWordFinder()
        finder.load(words: testWords)
        let words = finder.findWords(for: [n2Char, n5Char]).sorted()
        XCTAssert(words3rdLetterOLastD.elementsEqual(words),
                  "\nEXPECTED:\n \(words)\n\nTO BE:\n\(words3rdLetterOLastD)")
    }

    func testMessySet() {
        let n4char = CharacterOffset("A", at: 4)
        let n5char = CharacterOffset("N", at: 5)
        let n6char = CharacterOffset("P", at: 6)

        let finder = NodeWordFinder()
        finder.load(words: messyIn)
        let words = finder.findWords(for: [n4char, n5char, n6char]).sorted()
        XCTAssert(messyOut.elementsEqual(words),
                  "\nEXPECTED:\n \(words)\n\nTO BE:\n\(messyOut)")
    }

    func skip_testFindPerformance() {
        let n3char = CharacterOffset("A", at: 4)
        let n5char = CharacterOffset("N", at: 5)
        let n6char = CharacterOffset("P", at: 6)

        let finder = NodeWordFinder()
        finder.load(words: Wordlist.main.long)

        self.measure {
            let words = finder.findWords(for: [n3char, n5char, n6char])
            print(words)
        }
    }
}
