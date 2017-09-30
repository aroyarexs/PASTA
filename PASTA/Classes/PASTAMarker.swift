//
//  PASTAMarker.swift
//  PAD
//
//  Created by Aaron Krämer on 07.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

import UIKit
import Metron

/// similarity operator
infix operator ~
/**
 This class overrides `touchesBegan(_:with:)`, `touchesMoved(_:with:)`, and `touchesEnded(_:with:)` of `UIView`.
 After created by `PASTAView` the object receives touch events and
 notifies `MarkerManager` and `PASTATangible` of changes.
 */
public class PASTAMarker: UIView {

    /// Automatically sets `previousCenter` before setting new `center` value.
    public override var center: CGPoint {
        willSet {
            previousCenter = center
            markerSnapshot.center = center
        }
    }
    /// Defines whether mean values for e.g. radius should be calculated and used.
    public var useMeanValues = true
    /**
     The radius of this marker.
     After did set this property `frame` of view is updated.
     */
    public var radius: CGFloat {
        didSet {
            if useMeanValues { self.radius = meanRadius.add(value: radius) }
            self.frame = CGRect(center: center, edges: radius * 2)
            markerSnapshot.radius = radius
        }
    }
    /// A mean calculator for the radius.
    let meanRadius = PASTAMeanCalculator()
    /// Indicates whether this marker is still receives updates or not.
    public var isActive: Bool = false
    /// The previous center location of the view.
    public var previousCenter: CGPoint

    /// The Tangible this marker belongs to.
    public weak var tangible: MarkerEvent?
    /// The marker manager this marker should register with.
    public weak var markerManager: MarkerStatus?

    /// Describes this marker as a pattern.
    public internal (set) var markerSnapshot: MarkerSnapshot

    // MARK: -

    /**
     Checks if `lhs` is similar `rhs`.
     - parameters:
        - lhs: Left hand side.
        - rhs: Right hand side.
     - returns: `true` if be similar, else `false`.
     */
    public static func ~ (_ lhs: PASTAMarker, _ rhs: PASTAMarker) -> Bool {
        return lhs.markerSnapshot.isRadiusSimilar(to: rhs.markerSnapshot)
    }

    /**
     The view's center will be set to `center`.
     Width and height will be set to `radius`.
     The active status is set to `false`.
     - parameters:
        - center: A point specifying the center of the view.
        - radius: A float specifying size of the view.
     */
    init(center: CGPoint, radius: CGFloat = 0.0) {
        self.radius = radius
        self.previousCenter = center
        markerSnapshot = MarkerSnapshot(center: center, radius: radius)
        super.init(frame: CGRect(center: center, edges: radius * 2))
//        backgroundColor = UIColor.gray  // uncomment to have a visualization of all detected markers
    }

    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(center: CGPoint.zero)
    }

    /**
     Updates `radius` and `center` with the values from the touch.
     - parameters:
        - touch: A `UITouch` object.
     */
    func update(touch: UITouch) {
        previousCenter = center
        self.radius = touch.majorRadius
        self.frame = CGRect(center: touch.preciseLocation(in: superview), edges: radius * 2)
    }

    // MARK: - UIResponder Overrides

    /// Calling `update(touch:)` with first touch, updating active state and notifying `tangible` and `markerManager`.
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        update(touch: touch)

        isActive = true
        tangible?.markerDidBecomeActive(self)
        markerManager?.markerDidBecomeActive(self)
    }

    /// Calling `update(touch:)` with first touch, updating active state and notifying `tangible` and `markerManager`.
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        update(touch: touch)

        if !useMeanValues && radius < 20 {    // the view needs a size to receive a new touch
            radius = 20
        }

        isActive = false
        tangible?.markerDidBecomeInactive(self)
        markerManager?.markerDidBecomeInactive(self)
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    /// Calling `update(touch:)` with first touch and `tangible.markerMoved(_:)`.
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        update(touch: touch)

        tangible?.markerMoved(self)
    }
}
