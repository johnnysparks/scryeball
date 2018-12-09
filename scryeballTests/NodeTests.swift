//
//  scryeballTests.swift
//  scryeballTests
//
//  Created by Johnny Sparks  on 11/11/18.
//  Copyright © 2018 Johnny Sparks . All rights reserved.
//

import XCTest
@testable import scryeball

class NodeTests: XCTestCase {

    func testInitialization() {
        let node = Node(value: Character("A"), parent: nil)
        XCTAssert(node.value == Character("A"))
        XCTAssertNil(node.parent)
        XCTAssert(node.children.isEmpty)
    }

    func testSuffix(){
        let a = Character("A")
        let l = Character("L")
        let s = Character("S")
        let node = Node(value: a, parent: nil)
        node.suffix(values: Array("LSO"))
        let lNode = node.children[l]
        let sNode = lNode?.children[s]

        XCTAssertEqual(node.children.count, 1)

        XCTAssertEqual(lNode?.value, l)
        XCTAssert(lNode?.parent === node)
        XCTAssertEqual(sNode?.value, s)
        XCTAssert(sNode?.parent === lNode)
    }

    func testSuffixes(){
        let node = Node(value: Character("A"), parent: nil)
        node.suffix(values: Array("LSO"))

        let strings = node.suffixes().map({ String($0) })
        XCTAssertEqual(strings.count, 1)
        XCTAssertEqual(strings.first, "ALSO")
    }

    func testMultipleSuffixes(){
        let node = Node(value: Character("A"), parent: nil)
        node.suffix(values: Array("LSO"))
        node.suffix(values: Array("LWAYS"))

        let strings = node.suffixes().map({ String($0) })
        XCTAssertEqual(strings.count, 2)
        XCTAssert(strings.contains("ALSO"))
        XCTAssert(strings.contains("ALWAYS"))
    }

    func testPrefix(){
        let node = Node(value: Character("A"), parent: nil)
        node.suffix(values: Array("LWAYS"))

        var next: Node<Character>? = node
        while (next?.children.count ?? 0) > 0 {
            next = next?.children.values.first
        }

        XCTAssertEqual(next?.value, Character("S"))
        let prefix = next?.prefix() ?? []
        XCTAssertEqual(String(prefix), "ALWAY")
    }
}
