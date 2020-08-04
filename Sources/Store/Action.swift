//
//  Action.swift
//
//
//  Created by Scott Gorden on 8/2/20.
//

import Foundation

public protocol Action { }

extension Action {
    public func then(_ action: Action) -> some Action {
        ActionSequence(self, action)
    }

    var normalized: [Action] {
        (self as? ActionSequence)?.flattened ?? [self]
    }
}

extension Sequence where Element == Action {
    var normalized: [Action] {
        flattened
    }

    fileprivate var flattened: [Action] {
        reduce(into: [Action]()) { $0.append(contentsOf: $1.normalized) }
    }
}

struct ActionSequence: Action, Sequence {
    private let actions: [Action]

    init(_ a: Action, _ b: Action) {
        self.actions = a.normalized + b.normalized
    }

    func makeIterator() -> Array<Action>.Iterator {
        actions.makeIterator()
    }
}
