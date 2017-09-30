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
