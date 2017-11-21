//
// Created by Aaron Krämer on 30.08.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import CoreGraphics

/// TODO: documentation
class PASTAMeanCalculator { // TODO: rename to MeanCalculator

    /// TODO: documentation
    private (set) var sum: CGFloat = 0
    /// TODO: documentation
    private (set) var count: CGFloat = 0
    /// TODO: documentation
    private (set) var mean: CGFloat = 0

    /// TODO: documentation
    func add(value: CGFloat) -> CGFloat {
        count += 1
        sum += value
        mean = sum / count
        return mean
    }
}

/// Counts the frequency of each value which is added.
class Counter {

    /// A dictionary storing the frequencies for each added value.
    private var frequencies = [CGFloat: Int]()
    /// The value which occurs most frequent.
    private (set) var mostFrequent: CGFloat
    /// The frequency of the `mostFrequent` value.
    private var frequency: Int {
        return frequencies[mostFrequent]!
    }

    /// Initializes the counter with a value.
    /// - parameter value: A `CGFloat`.
    init(value: CGFloat) {
        mostFrequent = value
        _ = add(value: value)
    }

    /// If `value` not present in dictionary it is added with frequency 1, otherwise count is increased by 1.
    /// - parameter value: A `CGFloat`.
    /// - returns: The most frequent value.
    func add(value: CGFloat) -> CGFloat {
        if let count = frequencies[value] {
            frequencies[value] = count + 1
        } else {
            frequencies[value] = 1
        }

        if frequency < frequencies[value]! {
            mostFrequent = value
        }
        return mostFrequent
    }
}