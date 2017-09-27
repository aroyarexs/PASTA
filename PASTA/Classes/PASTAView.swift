//
//  PASTAView.swift
//  PAD
//
//  Created by Aaron Krämer on 07.08.17.
//  Copyright © 2017 Aaron Krämer. All rights reserved.
//

import UIKit

/**
 `PASTAView` represents the root of the SDK.
 Set yourself as `delegate` to receive status and event updates of every Tangible detected on this view.

 This class overrides the `hitTest(_:with:)` function.
 It initializes a `PASTAMarker` if none of the subviews contains the point send with `hitTest(_:with:)`,
 adds it as subview, and returns the marker as a result of `hitTest(_:with:)`.

 To change the used `TangibleManager` set the `tangibleManager` property of `markerManager`.
 Don't forget to set `tangibleDelegate` of your new `TangibleManager`.
 Otherwise you won't receive Tangible events.
 */
class PASTAView: UIView {

    weak var delegate: TangibleEvent? {
        didSet {
            manager.tangibleDelegate = delegate
        }
    }
    /// The manager used by this view.
    var manager: TangibleManager = PASTAManager()

    // hitTest() gets called 2 times
    // http://stackoverflow.com/questions/4304113/uiviews-hittestwithevent-called-three-times#4536765
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
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
