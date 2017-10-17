//
//  PASTAManager.swift
//  PAD
//
//  Created by Aaron Krämer on 09.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

import CoreGraphics

/// Collects markers and provides functions to compose/complete Tangibles.
class PASTAManager: TangibleManager {

    // MARK: - Marker Manager Properties

    /// A set of markers which are not assigned to any Tangible.
    var unassigned = Set<PASTAMarker>()

    // MARK: - Tangible Manager Properties

    /// Holds all tangibles with active markers only.
    private (set) var complete = Set<PASTATangible>()
    /// Contains all tangibles which have at least one active and one inactive marker.
    private (set) var incomplete = Set<PASTATangible>()
    /// A set of tangibles which are either not allowed or similar to existing ones (`similarPatternsAllowed == true`).
    private (set) var blocked = Set<PASTATangible>()

    /// Compares all currently active Tangible patterns on the screen against `pattern`.
    /// - parameter pattern: A Tangible pattern.
    /// - returns: `true` if `pattern` is similar to any currently active pattern, otherwise `false`.
    func isSimilar(pattern: PASTAPattern) -> Bool {
        return complete.union(incomplete).contains { $0.pattern.isSimilar(to: pattern) }
    }

    /// `true` if `patternWhitelistDisabled == true` or `pattern` is contained in `patternWhitelist`.
    /// - parameter pattern: A Tangible pattern.
    /// - returns: `true` if `patternWhitelistDisabled == true` or `pattern` is contained in `patternWhitelist`.
    func isPatternAllowed(pattern: PASTAPattern) -> Bool {
        return patternWhitelistDisabled || patternWhitelist.contains { $0.value.isSimilar(to: pattern) }
    }

    /// Concatenated `isSimilar(pattern:)` and `isPatternAllowed(pattern:)` with boolean AND.
    /// - parameter pattern: A tangible pattern.
    /// - returns: `true` if both functions return `true`, otherwise `false`.
    func willAcceptPattern(pattern: PASTAPattern) -> Bool {
        return isPatternAllowed(pattern: pattern) && isSimilar(pattern: pattern)
    }

    /// Tries to composes a new Tangible.
    /// `self` is assigned to `tangibleManager` property and `tangibleDelegate` is assigned to `eventDelegate`.
    /// - parameter markers: An array of marker.
    /// - returns: `nil` of Tangible could not be composed, otherwise a new Tangible.
    private func createTangible(markers: [PASTAMarker]) -> PASTATangible? {
        let tangible = PASTATangible(markers: markers)
        tangible?.tangibleManager = self
        tangible?.eventDelegate = tangibleDelegate
        return tangible
    }

    /// Tries to creates a new Tangible and insert it into `blocked` set.
    /// - parameter markers: An array of markers.
    /// - returns: `true` if Tangible could be formed, otherwise `false`.
    private func insertBlockedTangible(markers: [PASTAMarker]) -> Bool {
        guard let tangible = PASTATangible(markers: markers) else { return false }
        tangible.tangibleManager = self
        blocked.insert(tangible)
        return true
    }

    // MARK: - TangibleManager

    weak var tangibleDelegate: TangibleEvent?
    private (set) var patternWhitelist: [String: PASTAPattern] = [:]
    var patternWhitelistDisabled: Bool = false
    var similarPatternsAllowed: Bool = false

    func whitelist(pattern: PASTAPattern, identifier: String) -> Bool {
        let patternOrIdentifierAlreadyUsed = patternWhitelist.contains {
            pattern.isSimilar(to: $0.value) || $0.key == identifier
        }
        guard patternOrIdentifierAlreadyUsed == false else { return false }
        patternWhitelist[identifier] = pattern
        return true
    }

    func compose(markers: [PASTAMarker]) -> Bool {
        guard markers.count == 3 else { return false }
        let pattern = PASTAPattern(marker1: markers[0], marker2: markers[1], marker3: markers[2])
        guard willAcceptPattern(pattern: pattern) else { return insertBlockedTangible(markers: markers) }

        guard let tangible = createTangible(markers: markers) else { return false }

        if tangible.inactiveMarkers.isEmpty { complete.insert(tangible) } else { incomplete.insert(tangible) }

        tangibleDelegate?.tangibleDidBecomeActive(tangible)

        return true
    }

    func complete(with marker: PASTAMarker) -> PASTATangible? {
        return incomplete.first { $0.replaceInactiveMarker(with: marker) }
    }

    // MARK: - TangibleStatus

    func tangibleDidBecomeInactive(_ tangible: PASTATangible) {
        complete.remove(tangible)
        incomplete.remove(tangible)
        blocked.remove(tangible)
    }

    func tangibleDidBecomeActive(_ tangible: PASTATangible) {
        if tangible.inactiveMarkers.isEmpty { complete.insert(tangible) } else { incomplete.insert(tangible) }
    }

    func tangible(_ tangible: PASTATangible, lost marker: PASTAMarker) {
        guard blocked.contains(tangible) == false else { return }
        incomplete.insert(tangible)
        complete.remove(tangible)
    }

    func tangible(_ tangible: PASTATangible, recovered marker: PASTAMarker) {
        guard blocked.contains(tangible) == false else { return }
        if tangible.inactiveMarkers.isEmpty {
            complete.insert(tangible)
            incomplete.remove(tangible)
        }
    }
}

extension PASTAManager: MarkerStatus {

    func markerDidBecomeActive(_ marker: PASTAMarker) {
        // incomplete available?
        if (complete(with: marker)) != nil {
            marker.markerManager = nil
            return
        }

        /// block marker which are not used by `incomplete` or `blocked` tangibles but are inside tangible
        let pointInsideIncomplete = incomplete.union(blocked).contains { tangible in
            let convertedCenter = marker.superview?.convert(marker.center, to: tangible) ??
                    CGPoint(x: CGFloat.infinity, y:CGFloat.infinity)
            return tangible.point(inside: convertedCenter, with: nil)
        }
        guard pointInsideIncomplete == false else { return }

        // can a new tangible be composed?
        if unassigned.count >= 2 {
            let configs = PASTAHeap(marker: marker, unassigned: Array(unassigned))
            for config in configs {
                if compose(markers: config) {
                    config.forEach {
                        unassigned.remove($0)
                        $0.markerManager = nil
                    }
                    return
                }
            }
        }
        // could not complete or compose
        unassigned.insert(marker)
    }

    func markerDidBecomeInactive(_ marker: PASTAMarker) {
        unassigned.remove(marker)
        marker.removeFromSuperview()
    }
}
