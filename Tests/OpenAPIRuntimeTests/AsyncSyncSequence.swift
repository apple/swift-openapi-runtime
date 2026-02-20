//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Async Algorithms open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Sequence {
  /// An asynchronous sequence containing the same elements as this sequence,
  /// but on which operations, such as `map` and `filter`, are
  /// implemented asynchronously.
  var async: AsyncSyncSequence<Self> {
    AsyncSyncSequence(self)
  }
}

/// An asynchronous sequence composed from a synchronous sequence.
///
/// Asynchronous lazy sequences can be used to interface existing or pre-calculated
/// data to interoperate with other asynchronous sequences and algorithms based on
/// asynchronous sequences.
///
/// This functions similarly to `LazySequence` by accessing elements sequentially
/// in the iterator's `next()` method.
struct AsyncSyncSequence<Base: Sequence>: AsyncSequence {
  typealias Element = Base.Element

  struct Iterator: AsyncIteratorProtocol {
    var iterator: Base.Iterator?

    init(_ iterator: Base.Iterator) {
      self.iterator = iterator
    }

    mutating func next() async -> Base.Element? {
      guard !Task.isCancelled, let value = iterator?.next() else {
        iterator = nil
        return nil
      }
      return value
    }
  }

  let base: Base

  init(_ base: Base) {
    self.base = base
  }

  func makeAsyncIterator() -> Iterator {
    Iterator(base.makeIterator())
  }
}

extension AsyncSyncSequence: Sendable where Base: Sendable {}

@available(*, unavailable)
extension AsyncSyncSequence.Iterator: Sendable {}
