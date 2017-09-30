//
//  PASTATangible.swift
//  PAD
//
//  Created by Aaron Krämer on 07.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

import UIKit
import Metron

/**
 This class represents a Tangible of exact 3 markers.

 Tangible adds itself as subview of `superview` of first marker.

 It overrides `hitTest(_:with:)` and checks all markers by calling their `hitTest(_:with:)` function.
 Check function documentation for further details.

 If you need a Tangible which supports less or more than 3 markers you have to create a subclass.
 */
public class PASTATangible: PASTAMarker {

    public override var useMeanValues: Bool {
        didSet { markers.forEach { $0.useMeanValues = useMeanValues } }
    }
    /// Vector from center to marker 0. Used as initial orientation
    let initialCenterToMarker0Vector: CGVector
    /// The orientation as a vector since this Tangible was detected.
    public var initialOrientationVector: CGVector {
        let centerToMarkerVector = CGVector(from: center, to: markers[0].center)
        let angle = initialCenterToMarker0Vector.angleRadians(between: centerToMarkerVector).radianToDegree
        return CGVector.normalizedUp.rotate(degrees: angle)
    }
    /// The orientation of this Tangible based on the pattern as a normalized vector.
    /// `nil` if pattern has no uniquely identifiable marker.
    public var orientationVector: CGVector? {
        guard let marker = markerWithAngleSimilarToNone() else { return nil }
        return CGVector(from: center, to: marker.center).normalized
    }

    /// Internal array of marker. Mutable.
    var internalMarkers: [PASTAMarker]
    /// Array of `PASTAMarker`. get-only.
    public var markers: [PASTAMarker] {
        return internalMarkers
    }
    /// Returns an array containing all inactive markers.
    public var inactiveMarkers: [PASTAMarker] {
        return markers.filter({ !$0.isActive })
    }
    /// The tangible manager who created this Tangible.
    public weak var tangibleManager: TangibleManager?
    /// Set this to get event updates of this Tangible.
    public weak var eventDelegate: TangibleEvent?

    /// Dictionary containing mean calculator instances for each marker's angle.
    var meanAngles = [PASTAMarker: PASTAMeanCalculator]()   // FIXME: Currently unused

    /// Describes the pattern of this Tangible.
    public internal (set) var pattern: PASTAPattern
    /// The identifier of the similar pattern which is used in the `patternWhitelist` of `PASTAManager`.
    public var patternIdentifier: String? {
        return (tangibleManager?.patternWhitelist.first { pattern.isSimilar(to: $0.value) })?.key
    }

    // MARK: - Functions

    public required init?(markers: [PASTAMarker]) {
        guard markers.count == 3 else { return nil }

        internalMarkers = markers
        pattern = PASTAPattern(marker1: markers[0], marker2: markers[1], marker3: markers[2])

        let circumcenter = CGPoint.circumcenter(
                first: markers[0].center,
                second: markers[1].center,
                third: markers[2].center)
        let radius = CGVector(from: circumcenter, to: markers[0].center).distance
        initialCenterToMarker0Vector = CGVector(from: circumcenter, to: markers[0].center)
        // TODO: decide if tangible can be formed (min, max radius?)
        super.init(center: circumcenter, radius: radius)

        markers.first?.superview?.addSubview(self)

        isActive = false
        markers.forEach {
            $0.tangible = self
            meanAngles[$0] = PASTAMeanCalculator()
            isActive = isActive || $0.isActive
        }
    }

    /**
     Always returns `nil`.
     Use `init?(markers:)` instead.
     */
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(markers: [])
    }

    /**
     Tries to replace the provided `newMarker` with an inactive marker.
     `newMarker` will have `previousCenter` and `tag` set to the values of the replaced inactive marker.
     - parameter newMarker: The marker which should replace an inactive.
     - returns: `true` if `newMarker` has replaced an inactive, otherwise `false`.
     */
    func replaceInactiveMarker(with newMarker: PASTAMarker) -> Bool {
        let activeMarkers = markers.filter { $0.isActive }
        var replaceableMarker: PASTAMarker?

        if activeMarkers.count == 1 {
            let activeMarker = activeMarkers.first!
            let activeToNew = CGVector(from: activeMarker.center, to: newMarker.center)
            var offsetToBeat = CGFloat.infinity
            inactiveMarkers.forEach { inactiveMarker in // find inactive marker to replace or none
                guard let activeToInactiveInPattern = pattern.vector(from: activeMarker, to: inactiveMarker),
                      let inactiveInPattern = (pattern.snapshots.first {
                          $0.uuidString == inactiveMarker.markerSnapshot.uuidString
                      })
                        else { return }
                let offset = abs(activeToNew.distance - activeToInactiveInPattern.distance)
                // new marker has to lay inside radius of inactive marker
                if offset < offsetToBeat && offset <= inactiveInPattern.radius {  // checking offset
                    replaceableMarker = inactiveMarker
                    offsetToBeat = offset
                }
            }
        } else if activeMarkers.count == 2 {
            let firstMarker = activeMarkers.first!
            let lastMarker = activeMarkers.last!
            let inactiveMarker = inactiveMarkers.first!

            let firstToNew = CGVector(from: firstMarker.center, to: newMarker.center)
            let lastToNew = CGVector(from: lastMarker.center, to: newMarker.center)
            let angleAtNew = firstToNew.angleRadians(between: lastToNew, absolute: true).radianToDegree

            if pattern.isAngleSimilar(atMarkerWith: inactiveMarker.markerSnapshot.uuidString, toDegrees: angleAtNew) {
                replaceableMarker = inactiveMarker
            }
        }
        if let replaceableMarker = replaceableMarker, let index = internalMarkers.index(of: replaceableMarker) {
            internalMarkers.remove(at: index)
            internalMarkers.insert(newMarker, at: index)
            replaceableMarker.removeFromSuperview()

            newMarker.previousCenter = replaceableMarker.center
            newMarker.markerSnapshot = replaceableMarker.markerSnapshot

            markerDidBecomeActive(newMarker)
            newMarker.tangible = self
        }
        return replaceableMarker != nil
    }

    /// Searches for the marker which angle is distinguishable from the other two.
    /// - returns: A marker or `nil`.
    func markerWithAngleSimilarToNone() -> PASTAMarker? {
        for marker in internalMarkers {
            let angle = pattern.angle(atMarkerWith: marker.markerSnapshot.uuidString).radianToDegree
            var notSimilar = true
            markers.forEach { comparator in
                guard marker != comparator else { return }
                let comparatorId = comparator.markerSnapshot.uuidString
                notSimilar = notSimilar && pattern.isAngleSimilar(atMarkerWith: comparatorId, toDegrees: angle) == false
            }
            if notSimilar { return marker }
        }
        return nil
    }

    // TODO: Is there another way to uniquely select a marker?

    // MARK: - Static Functions

    /**
     Checks if `left` is similar `right`.
     - parameters:
        - left: Left hand side.
        - right: Right hand side.
     - returns: `true` be similar, else `false`.
     */
    public static func ~ (_ left: PASTATangible, _ right: PASTATangible) -> Bool {
        return left.pattern.isSimilar(to: right.pattern)
    }

    // MARK: - Hit Test Override

    /**
     Checks all markers by calling their `hitTest(_:with:)` function.
     If none found it returns itself if `event ` is `nil`, otherwise it returns `nil`.
     - parameters:
        - point: Point tot test.
        - event: Optional.
     - returns: A marker or `nil`.
     */
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else { return nil }
        let marker = inactiveMarkers.first { $0.hitTest(point, with: event) != nil }
        return marker ?? event == nil ? self : nil
        // TODO: may need to consider gestures https://developer.apple.com/documentation/uikit/uievent/1613832-touches
        // TODO: if no marker return self -> override touches... functions to let the touch run into void
        // does gestures then still work?
    }

    // TODO: do I need to override pointInside() because Tangible is detected as circle
    // add radius of biggest marker to radius of tangible and check if inside circle
}

extension PASTATangible: MarkerEvent {  // MARK: - MarkerEvent

    public func markerMoved(_ marker: PASTAMarker) {
        // updating inactive markers
        if inactiveMarkers.count == 2 {
            let translate = marker.center - marker.previousCenter
            inactiveMarkers.forEach { $0.center = $0.center + translate }
            center = CGPoint.circumcenter(first: markers[0].center, second: markers[1].center, third: markers[2].center)
        } else if inactiveMarkers.count == 1, let inactiveMarker = inactiveMarkers.first,
                  let theOtherActiveMarker = (markers.first { $0 != inactiveMarker && $0 != marker }) {

            let possibleCenters = CGPoint.circleCenters(
                    point1: marker.center,
                    point2: theOtherActiveMarker.center,
                    radius: radius)
            center = center.closest(point1: possibleCenters.0, point2: possibleCenters.1)

            // calculating new position for inactive marker
            let unguardedOriginalActiveVector = pattern.vector(from: theOtherActiveMarker, to: marker)
            guard let originalActiveVector = unguardedOriginalActiveVector else { return }
            let currentActiveVector = CGVector(from: theOtherActiveMarker.center, to: marker.center)
            let angle = originalActiveVector.angleRadians(between: currentActiveVector).radianToDegree

            guard let originalInactiveVector = pattern.vector(from: marker, to: inactiveMarker) else { return }
            let originalInactiveVectorRotated = originalInactiveVector.rotate(degrees: angle)

            let markerVector = CGVector(from: .zero, to: marker.center)
            let tempInactiveCenter = (markerVector + originalInactiveVectorRotated).point
            // find point on circle closest to `tempInactiveCenter`
            // https://stackoverflow.com/questions/300871/best-way-to-find-a-point-on-a-circle-closest-to-a-given-point
            // V = (Point - Center)
            let centerToTempInactive = CGVector(from: center, to: tempInactiveCenter)
            // Answer = Center + V / |V| * Radius
            inactiveMarker.center = center + (centerToTempInactive.normalized * radius).point
        } else {
            center = CGPoint.circumcenter(first: markers[0].center, second: markers[1].center, third: markers[2].center)
        }
        radius = CGVector(from: center, to: marker.center).distance

        if center != previousCenter {
            eventDelegate?.tangibleMoved(self)
            tangible?.markerMoved(self)
        }
    }

    public func markerDidBecomeActive(_ marker: PASTAMarker) {
        markerMoved(marker)
        if isActive == false && markers.count != inactiveMarkers.count {    // was inactive and now one active marker
            isActive = true
            marker.superview?.addSubview(self)
            tangibleManager?.tangibleDidBecomeActive(self)
            eventDelegate?.tangibleDidBecomeActive(self)
            // tangible used as marker
            tangible?.markerDidBecomeActive(self)
            markerManager?.markerDidBecomeActive(self)
        }

        tangibleManager?.tangible(self, recovered: marker)
        eventDelegate?.tangible(self, recovered: marker)
    }

    public func markerDidBecomeInactive(_ marker: PASTAMarker) {
        if inactiveMarkers.count == 1 {
            pattern = PASTAPattern(marker1: markers[0], marker2: markers[1], marker3: markers[2])
        }

        tangibleManager?.tangible(self, lost: marker)
        eventDelegate?.tangible(self, lost: marker)

        if markers.count == inactiveMarkers.count { // all marker inactive -> tangible inactive
            isActive = false
            removeFromSuperview()
            markers.forEach { $0.removeFromSuperview() }
            tangibleManager?.tangibleDidBecomeInactive(self)
            eventDelegate?.tangibleDidBecomeInactive(self)
            // tangible used as marker
            markerManager?.markerDidBecomeInactive(self)
            tangible?.markerDidBecomeInactive(self)
        }
    }
}
