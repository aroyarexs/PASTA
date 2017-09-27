//
// Created by Aaron Krämer on 05.09.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import CoreGraphics
import Foundation

/// Describes the pattern of a Tangible.
/// Use it to compare two Tangibles.
/// When checking for similarity/equality measurement inaccuracy is taken into account.
/// For the exact error values please have a look at Master's Thesis of Aaron Krämer.
class PASTAPattern {

    /// A list of `MarkerSnapshot`\s.
    private (set) var snapshots = [MarkerSnapshot]()

    /**
     Creates a new ambiguous pattern with 3 markers.
     The pattern is translated such that the circumcenter is at (0,0).
     The order of the marker may change due to easier internal calculations.
     - parameters:
        - marker1: A `PASTAMarker`.
        - marker2: A `PASTAMarker`.
        - marker3: A `PASTAMarker`.
     - returns: A new Tangible pattern.
     */
    init(marker1: PASTAMarker, marker2: PASTAMarker, marker3: PASTAMarker) {
        let circumcenter = CGPoint.circumcenter(first: marker1.center, second: marker2.center, third: marker3.center)

        let markers = [marker1, marker2, marker3]
        markers.forEach {
            // translating tangible to (0,0) for easier comparison with other
            let markerRef = MarkerSnapshot(center: $0.center - circumcenter, radius: $0.radius,
                    uuid: $0.markerSnapshot.uuid)
            snapshots.append(markerRef)
        }

        let v1 = CGVector(from: markers[1].center, to: markers[0].center)
        let v2 = CGVector(from: markers[1].center, to: markers[2].center)
        if v1.angleRadians(between: v2) < 0 { snapshots.reverse() }   // ensures correct angle calculation
    }

    // TODO: new init with MarkerSnapshots

    /**
     Creates a vector pointing from `from` to `to`.
     - parameters:
        - from: The starting point of the vector.
        - to: The end point of the vector.
     - returns: `nil` if at least one of the markers `tag` didn't match any in `markerReference`,
        otherwise a new vector.
     */
    func vector(from: PASTAMarker, to: PASTAMarker) -> CGVector? {
        guard let fromMarker = (snapshots.first { $0.uuidString == from.markerSnapshot.uuidString }),
              let toMarker = (snapshots.first { $0.uuidString == to.markerSnapshot.uuidString }) else { return nil }
        return CGVector(from: fromMarker.center, to: toMarker.center)
    }

    /**
     Calculates the interior angle in radians where `uuidString`\s equal.
     Markers before and after marker are used to form vectors facing from marker to the other two markers.
     Return value ranges from 0 to π.
     ## Reference:
     [http://www.euclideanspace.com](http://www.euclideanspace.com/maths/algebra/vectors/angleBetween/issues/index.htm)
     - parameters:
        - uuidString: The marker which will be used as point of origin.
     - returns: `CGFloat.infinity` if marker couldn't be found, otherwise the angle in radians between 0 - π.
     */
    func angle(atMarkerWith uuidString: String) -> CGFloat {
        let optionalMarker = snapshots.first { $0.uuidString == uuidString }
        let optionalNeighbour1 = snapshots.first { $0.uuidString != uuidString }
        guard let baseMarker = optionalMarker, let neighbour1 = optionalNeighbour1 else { return CGFloat.infinity }
        let optionalNeighbour2 = snapshots.first {
            $0.uuidString != baseMarker.uuidString && $0.uuidString != neighbour1.uuidString
        }
        guard let neighbour2 = optionalNeighbour2 else { return CGFloat.infinity }

        let v1 = CGVector(from: baseMarker.center, to: neighbour1.center)
        let v2 = CGVector(from: baseMarker.center, to: neighbour2.center)

        return v1.angleRadians(between: v2, absolute: true)
    }

    /**
     Compares the receiver with `comparator`.
     Checks for similar tangible radii, internal angles, and marker similarity.
     The function is calling `isRadiusSimilar(to:)` and `isAngleSimilar(atMarker: to:)`.
     - parameter comparator: Another pattern.
     - returns: `true` if similar, otherwise `false`.
     */
    func isSimilar(to comparator: PASTAPattern) -> Bool {
        var isSimilar = false
        guard let comparatorFirstMarker = comparator.snapshots.first else { return isSimilar }
        var ownReferences = self.snapshots  // we don't want to override markers, getting copy

        // comparing radii
        let v1 = CGVector(from: .zero, to: comparatorFirstMarker.center)
        isSimilar = isRadiusSimilar(to: v1.distance)
        guard isSimilar else { return false }

        for _ in ownReferences.makeIterator() {
            for (ownRef, comparatorRef) in zip(ownReferences, comparator.snapshots) {
                // checking internal angle
                let comparatorAngle = comparator.angle(atMarkerWith: comparatorRef.uuidString).radianToDegree
                isSimilar = isSimilar && isAngleSimilar(atMarkerWith: ownRef.uuidString, toDegrees: comparatorAngle)
                // checking marker radius
                // FIXME: disabled for better detection, marker size is way to unreliable
//                isRadiusSimilar = isRadiusSimilar && ownRef.isRadiusSimilar(to: comparatorRef)
                guard isSimilar else { break }
            }
            if isSimilar { break }

            // moving first element to the end
            ownReferences.append(ownReferences.first!)
            ownReferences.removeFirst()
        }
        return isSimilar
    }

    /**
     Compares the radii of the receiver and `radius`.
     Takes measurement inaccuracy into account  by applying an error value.
     - parameter radius: A radius as `CGFloat`.
     - returns: `true` if radii similar, otherwise `false`.
     */
    func isRadiusSimilar(to radius: CGFloat) -> Bool {
        return abs(CGVector(from: .zero, to: snapshots[0].center).distance - radius) < 6 // TODO: right value
    }

    /**
     Compares the angle of a marker with given `markerPatternReference` of the receiver with a given `angleInDegree`.
     Takes measurement inaccuracy into account  by applying an error value.
     If marker with `markerPatternReference` not part of this pattern `false` is returned.
     - parameters:
        - uuidString: The `markerPatternReference` of the `PASTAMarker`.
        - angleInDegree: The angle to compare with in degree.
     - returns: `true` if angle similar, otherwise `false`.
     */
    func isAngleSimilar(atMarkerWith uuidString: String, toDegrees: CGFloat) -> Bool {
        return abs(angle(atMarkerWith: uuidString).radianToDegree - toDegrees) < 9    // TODO: right value
    }
}

extension PASTAPattern: Equatable {
    /// Same behaviour as `isSimilar(to:)` function.
    /// - parameters: 
    /// - returns: 
    static func == (lhs: PASTAPattern, rhs: PASTAPattern) -> Bool {
        return lhs.isSimilar(to: rhs)
    }
}

/**
 Contains a snapshot of a `PASTAMarker` at the time this structure was initialized.
 */
struct MarkerSnapshot {
    /// The center of the referenced marker.
    var center: CGPoint
    /// The radius of the referenced marker.
    var radius: CGFloat
    /// A UUID making this snapshot unique.
    let uuid: uuid_t
    /// The `uuid` represented as `String`.
    var uuidString: String {
        return UUID(uuid: uuid).uuidString
    }

    init(center: CGPoint, radius: CGFloat, uuid: uuid_t? = nil) {
        self.center = center
        self.radius = radius
        self.uuid = uuid ?? UUID().uuid
    }

    /**
     Compares the radii of the receiver and `comparator`.
     Takes measurement inaccuracy into account by applying an error value.
     - parameters comparator: Another `MarkerSnapshot` to compare with.
     - returns: `true if radii are similar, otherwise `false`.
     */
    func isRadiusSimilar(to comparator: MarkerSnapshot) -> Bool {
        return abs(self.radius - comparator.radius) < 9 // TODO: right value
    }
}

extension MarkerSnapshot: Hashable {
    /// from https://developer.apple.com/documentation/swift/hashable
    public var hashValue: Int {
        return (center.x.hashValue ^ center.y.hashValue &* 16777619) + Int(radius)
    }

    static func == (lhs: MarkerSnapshot, rhs: MarkerSnapshot) -> Bool {
        return lhs.center == rhs.center && lhs.radius == rhs.radius
    }
}
