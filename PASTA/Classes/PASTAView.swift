//
//  PASTAView.swift
//  PAD
//
//  Created by Aaron Krämer on 07.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

import UIKit

/// `PASTAView` represents the base of the SDK.
/// It creates new `PASTAMarker` by overriding the `hitTest(_:with:)` of `UIView` and
/// informs the delegate about Tangible status and event changes.
public class PASTAView: UIView {

    /// Sets the `tangibleDelegate` of `manager`.
    /// The object will receive status and event updates of every Tangible detected on this view.
    public weak var delegate: TangibleEvent? {
        didSet {
            manager.tangibleDelegate = delegate
        }
    }
    /// The manager used by this view.
    /// If you assign a new manager do not forget to assign an object to `delegate`.
    /// Otherwise you will not receive updates.
    public var manager: TangibleManager = PASTAManager()

    // hitTest() gets called 2 times
    // http://stackoverflow.com/questions/4304113/uiviews-hittestwithevent-called-three-times#4536765

    /// Initializes a `PASTAMarker` if none of the subviews contains `point`,
    /// adds the marker as subview, and returns the marker.
    /// Will never return `self`.
    /// Returns `nil` if `point` is outside the view.
    /// - returns: `nil` if `point` outside, a subview if one is hit, otherwise a new `PASTAMarker`.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else { return nil }
        if let resultView = super.hitTest(point, with: event), resultView != self {
            return resultView
        } else {
            let marker = PASTAMarker(center: point)
            marker.markerManager = manager

            addSubview(marker)

            return marker
        }
    }
}
