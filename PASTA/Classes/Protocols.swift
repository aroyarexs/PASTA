//
//  Protocols.swift
//  PAD
//
//  Created by Aaron Krämer on 07.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

/// Used to notify the receiver of any status changes of
public protocol MarkerStatus: AnyObject {

    /**
     Notifies the receiver that a (new) marker did become active.
     - parameters:
        - marker: The marker which becomes active.
     */
    func markerDidBecomeActive(_ marker: PASTAMarker)
    /**
     Notifies the receiver that a marker did become inactive.
     - parameters:
        - marker: The marker which did become inactive.
     */
    func markerDidBecomeInactive(_ marker: PASTAMarker)
}

/// Use this protocol to notify the receiver of any marker changes.
public protocol MarkerEvent: MarkerStatus {

    /**
     Notifies the receiver that a marker moved.
     - parameters:
        - marker: The marker which moved.
     */
    func markerMoved(_ marker: PASTAMarker)
}

/// TODO: documentation
public protocol TangibleStatus: AnyObject {

    /**
     Notifies the receiver that a (new) tangible did become active.
     For example if all markers were inactive but one turned active or if a new Tangible was composed.
     If a similar Tangible was already on the screen the `tag` property of `tangible` will be set to the same value.
     - parameters:
        - tangible: The tangible which becomes active.
     */
    func tangibleDidBecomeActive(_ tangible: PASTATangible)
    /**
     Notifies the receiver that a tangible did become inactive.
     For example all marker did become inactive.
     - parameters:
        - tangible: The tangible which did become inactive.
     */
    func tangibleDidBecomeInactive(_ tangible: PASTATangible)
    /**
     Notifies the receiver that `marker` of `tangible` becomes inactive.
     `tangible` is becoming incomplete but is still active.
     - parameters:
        - tangible: The Tangible which has lost a marker
        - marker: The marker which did become inactive.
     */
    func tangible(_ tangible: PASTATangible, lost marker: PASTAMarker)
    /**
     Notifies the receiver that a previous inactive marker could be recovered using `marker`.
     - parameters:
        - tangible: The Tangible which recovered the marker.
        - marker: The marker which turned active.
     */
    func tangible(_ tangible: PASTATangible, recovered marker: PASTAMarker)
}

/// TODO: documentation
public protocol TangibleEvent: TangibleStatus {

    /**
     Notifies the receiver that a tangible has moved.
     - parameter tangible: The tangible which moved.
     */
    func tangibleMoved(_ tangible: PASTATangible)
}

/// Defines standard functions of a tangible manager.
public protocol TangibleManager: MarkerStatus, TangibleStatus {

    /// Notifies the delegate about all `TangibleEvent` changes.
    /// Set the `eventDelegate` property of `PASTATangible` to this value.
    weak var tangibleDelegate: TangibleEvent? { get set }

    /// A whitelist of patterns.
    /// Every other pattern not similar to at least one of them will be blocked.
    var patternWhitelist: [String: PASTAPattern] { get }

    /// If `true` the set `patternWhitelist` will be ignored.
    /// Use this variable to detect Tangibles and to add the desired patterns then to the `patternWhitelist` set.
    var patternWhitelistDisabled: Bool { get set }

    /// If `false` and a new Tangible will be composed but is similar to another it will be ignored/blocked.
    /// Set to `true` if you want to allow multiple similar Tangibles.
    var similarPatternsAllowed: Bool { get set }

    /// Inserts `pattern` with `identifier` to `patternWhitelist`
    /// if pattern or identifier isn't present in the whitelist.
    /// - parameters:
    ///     - pattern: A Tangible pattern.
    ///     - identifier: A `String` used as identifier of this pattern.
    /// - returns: `true` if `pattern` with `identifier` could be inserted.
    ///     `false` if pattern or identifier already present in whitelist.
    func whitelist(pattern: PASTAPattern, identifier: String) -> Bool

    /**
     Tries to compose a Tangible from the given markers.
     If pattern not whitelisted or similar ones not allowed it will also return `true`
     but creates a blocked Tangible without notifying the delegate.
     - parameter markers: An array of markers.
     - returns: `true` if Tangible can be formed, otherwise ` false`.
     */
    func compose(markers: [PASTAMarker]) -> Bool
    /**
     Tries to complete an incomplete `tangible` with a given `marker`.
     - parameters:
        - marker: An active marker.
     - returns: A Tangible if `marker` is a valid replacement, else `nil`.
     */
    func complete(with marker: PASTAMarker) -> PASTATangible?
}
