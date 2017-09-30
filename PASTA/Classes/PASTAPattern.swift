//
// Created by Aaron Krämer on 05.09.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import CoreGraphics
import Foundation
import Metron

/// Describes the pattern of a Tangible.
/// Use it to compare two Tangibles.
/// When checking for similarity/equality measurement inaccuracy is taken into account.
/// For the exact error values please have a look at Master's Thesis of Aaron Krämer.
public class PASTAPattern {

    /// A list of `MarkerSnapshot`\s.
    private (set) var snapshots = [MarkerSnapshot]()

    /**
     Creates a new pattern with 3 markers.
     Calls `init(snap1:snap2:snap3:)` to initialize a new pattern.
     - parameters:
        - marker1: A `PASTAMarker`.
        - marker2: A `PASTAMarker`.
        - marker3: A `PASTAMarker`.
     - returns: A new Tangible pattern.
     */
    convenience init(marker1: PASTAMarker, marker2: PASTAMarker, marker3: PASTAMarker) {
        self.init(snap1: marker1.markerSnapshot, snap2: marker2.markerSnapshot, snap3: marker3.markerSnapshot)
    }

    /// Creates a new pattern with 3 markers.
    /// The pattern is translated such that the circumcenter is at (0,0).
    /// The order of the marker may change due to easier internal calculations.
    /// - parameters:
    ///    - marker1: A `MarkerSnapshot`.
    ///    - marker2: A `MarkerSnapshot`.
    ///    - marker3: A `MarkerSnapshot`.
    /// - returns: A new Tangible pattern.
    init(snap1: MarkerSnapshot, snap2: MarkerSnapshot, snap3: MarkerSnapshot) {
        let circumcenter = Triangle(a: snap1.center, b: snap2.center, c: snap3.center).cicrumcenter

        let markers = [snap1, snap2, snap3]
        markers.forEach {
            // translating tangible to (0,0) for easier comparison with other
            let markerRef = MarkerSnapshot(center: $0.center - circumcenter.vector, radius: $0.radius,
                    uuid: $0.uuid)
            snapshots.append(markerRef)
        }

        let v1 = CGVector(from: markers[1].center, to: markers[0].center)
        let v2 = CGVector(from: markers[1].center, to: markers[2].center)
        if v1.angle(between: v2) < Angle(0) { snapshots.reverse() }   // ensures correct angle calculation
    }

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
    func angle(atMarkerWith uuidString: String) -> Angle {
        let optionalMarker = snapshots.first { $0.uuidString == uuidString }
        let optionalNeighbour1 = snapshots.first { $0.uuidString != uuidString }
        guard let baseMarker = optionalMarker, let neighbour1 = optionalNeighbour1 else {
            return Angle(CGFloat.infinity)
        }
        let optionalNeighbour2 = snapshots.first {
            $0.uuidString != baseMarker.uuidString && $0.uuidString != neighbour1.uuidString
        }
        guard let neighbour2 = optionalNeighbour2 else { return Angle(CGFloat.infinity) }

        let v1 = CGVector(from: baseMarker.center, to: neighbour1.center)
        let v2 = CGVector(from: baseMarker.center, to: neighbour2.center)

        return v1.angle(between: v2, absolute: true)
    }

    /**
     Compares the receiver with `comparator`.
     Checks for similar tangible radii, internal angles, and marker similarity.
     The function is calling `isRadiusSimilar(to:)` and `isAngleSimilar(atMarker: to:)`.
     - parameter comparator: Another pattern.
     - returns: `true` if similar, otherwise `false`.
     */
    public func isSimilar(to comparator: PASTAPattern) -> Bool {
        var isSimilar = false
        guard let comparatorFirstMarker = comparator.snapshots.first else { return isSimilar }
        var ownReferences = self.snapshots  // we don't want to override markers, getting copy

        // comparing radii
        let v1 = CGVector(from: .zero, to: comparatorFirstMarker.center)
        isSimilar = isRadiusSimilar(to: v1.magnitude)
        guard isSimilar else { return false }

        for _ in ownReferences.makeIterator() {
            for (ownRef, comparatorRef) in zip(ownReferences, comparator.snapshots) {
                // checking internal angle
                let comparatorAngle = comparator.angle(atMarkerWith: comparatorRef.uuidString)
                isSimilar = isSimilar && isAngleSimilar(atMarkerWith: ownRef.uuidString, to: comparatorAngle)
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
    public func isRadiusSimilar(to radius: CGFloat) -> Bool {
        return abs(CGVector(from: .zero, to: snapshots[0].center).magnitude - radius) < 6 // TODO: right value
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
    public func isAngleSimilar(atMarkerWith uuidString: String, to: Angle) -> Bool {
        return abs(angle(atMarkerWith: uuidString).degrees - to.degrees) < 9    // TODO: right value
    }
}

extension PASTAPattern: Equatable {
    /// Same behaviour as `isSimilar(to:)` function.
    /// - parameters: 
    /// - returns: 
    public static func == (lhs: PASTAPattern, rhs: PASTAPattern) -> Bool {
        return lhs.isSimilar(to: rhs)
    }
}

extension PASTAPattern: CustomDebugStringConvertible {
    public var debugDescription: String {
        let triangle = Triangle(a: snapshots[0].center, b: snapshots[1].center, c: snapshots[2].center)
        return "PASTAPattern {\n" +
                "center: \(triangle.cicrumcenter), " +
                "radius: \(triangle.cicrumcenter.distance(to: snapshots[0].center)),\n" +
                "snap1: \(snapshots[0]),\n" +
                "snap2: \(snapshots[1]),\n" +
                "snap3: \(snapshots[2])\n" +
                "}"
    }
}

/**
 Contains a snapshot of a `PASTAMarker` at the time this structure was initialized.
 */
public struct MarkerSnapshot {
    /// The center of the referenced marker.
    public var center: CGPoint
    /// The radius of the referenced marker.
    public var radius: CGFloat
    /// A UUID making this snapshot unique.
    let uuid: uuid_t
    /// The `uuid` represented as `String`.
    public var uuidString: String {
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
    public func isRadiusSimilar(to comparator: MarkerSnapshot) -> Bool {
        return abs(self.radius - comparator.radius) < 9 // TODO: right value
    }
}

extension MarkerSnapshot: Hashable {
    /// from https://developer.apple.com/documentation/swift/hashable
    public var hashValue: Int {
        return (center.x.hashValue ^ center.y.hashValue &* 16777619) + Int(radius)
    }

    public static func == (lhs: MarkerSnapshot, rhs: MarkerSnapshot) -> Bool {
        return lhs.center == rhs.center && lhs.radius == rhs.radius
    }
}

extension MarkerSnapshot: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "MarkerSnapshot {center \(center), radius: \(radius), " +
                "uuidString: \(uuidString.components(separatedBy: "-").first ?? "")...}"
    }
}
