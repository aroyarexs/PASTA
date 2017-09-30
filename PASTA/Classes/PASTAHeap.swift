//
//  PASTAHeap.swift
//  PAD
//
//  Created by Aaron Krämer on 09.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

/// This class creates an array of marker combinations used to initialize a Tangible.
class PASTAHeap: Sequence, IteratorProtocol {   // TODO: Rename to PASTACombination
    /// An array containing arrays of markers.
    let configurations: [[PASTAMarker]] // TODO: rename combinations
    /// Used in the `IteratorProtocol`.
    private var current = 0

    /**
     Creates new combinations.
     Every combination contains `marker` and has the amount of `markerPerPattern`.
     If `markerPerPattern` is smaller 2 no combinations will be created.
     - parameters:
        - marker: The marker which should be included in every combination.
        - unassigned: An array of unassigned markers. Should not include `marker`.
        - markerPerPattern: The amount of markers in every configuration.
            Default is `3`.
     - returns: A new instance.
     */
    init(marker: PASTAMarker, unassigned: [PASTAMarker], markerPerPattern: Int = 3) {
        guard markerPerPattern >= 2 else {
            self.configurations = []
            return
        }
        var configurations = [[PASTAMarker]]()

        let needed = markerPerPattern - 2
        for (index, uMarker) in unassigned.enumerated() {
            guard needed > 0 else {
                configurations.append([marker, uMarker])
                continue
            }

            for subIndex in (index+1)...unassigned.count {    // get the next needed markers after `uMarker`
                let endIndex = subIndex + needed
                guard endIndex <= unassigned.count else { break }
                let subRange = Range(uncheckedBounds: (subIndex, endIndex))
                var sub = [marker, uMarker]
                sub.append(contentsOf: unassigned[subRange])
                if sub.count == markerPerPattern {
                    configurations.append(sub)
                }
            }
        }
        self.configurations = configurations
    }

    func next() -> [PASTAMarker]? {
        defer { current += 1 }
        return current >= configurations.count ? nil : configurations[current]
    }
}
