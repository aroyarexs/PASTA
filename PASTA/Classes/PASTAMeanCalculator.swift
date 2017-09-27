//
// Created by Aaron Krämer on 30.08.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import CoreGraphics

class PASTAMeanCalculator {

    private (set) var sum: CGFloat = 0
    private (set) var count: CGFloat = 0
    private (set) var mean: CGFloat = 0

    func add(value: CGFloat) -> CGFloat {
        count += 1
        sum += value
        mean = sum / count
        return mean
    }
}
