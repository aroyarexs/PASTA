//
//  PASTAMarkerTest.swift
//  PAD
//
//  Created by Aaron Krämer on 15.08.17.
//  Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import Quick
import Nimble
@testable import PASTA

class PASTAMarkerTest: QuickSpec {
    override func spec() {
        describe("a PASTA marker") {
            var activeMarker: PASTAMarker!
            beforeEach {
                activeMarker = PASTAMarker(center: CGPoint(x: 3.5, y: 3.5), radius: 2.5)
            }

            describe("before received a touch") {
                it("has radius") {
                    expect(activeMarker.radius).to(equal(2.5))
                }
                it("has center") {
                    expect(activeMarker.center).to(equal(CGPoint(x: 3.5, y: 3.5)))
                }
                it("has tangible") {
                    expect(activeMarker.tangible).to(beNil())
                }
                it("has marker manager") {
                    expect(activeMarker.markerManager).to(beNil())
                }
                it("matches pattern") {
                    expect(activeMarker ~ activeMarker).to(beTrue())
                }
                it("is active") {
                    expect(activeMarker.isActive).to(beFalse())
                }
                it("previous center equals center") {
                    expect(activeMarker.previousCenter).to(equal(activeMarker.center))
                }
                it("is similar to another marker") {
                    let marker = PASTAMarker(center: CGPoint(x: 11, y: 11))
                    expect(activeMarker ~ marker).to(beTrue())

                    let marker2 = PASTAMarker(center: CGPoint(x: 3.5, y: 12))
                    expect(activeMarker ~ marker2).to(beTrue())

                    let marker3 = PASTAMarker(center: CGPoint(x: 3.5, y: 12), radius: 12)
                    expect(activeMarker ~ marker3).to(beFalse())

                    let marker4 = PASTAMarker(center: activeMarker.center, radius: activeMarker.radius + 9)
                    expect(activeMarker ~ marker4) == false
                }
            }
            describe("receiving a touch") {
                var touchSet = Set<MockTouch>(minimumCapacity: 1)
                touchSet.insert(MockTouch(location: CGPoint(x: 13, y: 35), radius: 22))

                beforeEach {
                    activeMarker.touchesBegan(touchSet, with: nil)
                }

                it("center moved") {
                    expect(activeMarker.center).to(equal(CGPoint(x: 13, y: 35)))
                }
                it("is active") {
                    expect(activeMarker.isActive).to(beTrue())
                }
                it("radius changed") {
                    expect(activeMarker.radius).to(equal(22))
                }
                it("frame of view changes") {
                    expect(activeMarker.frame).to(equal(CGRect(center: CGPoint(x: 13, y: 35), edges: 44)))
                }
            }
            describe("setting values manually") {
                var lastCenter: CGPoint!
                beforeEach {
                    lastCenter = activeMarker.center
                    activeMarker.center = CGPoint(x: 13, y: 12)
                }
                it("previous center changes") {
                    expect(activeMarker.previousCenter).to(equal(lastCenter))
                }
                it("frame changes") {
                    let lastFrame = activeMarker.frame
                    activeMarker.radius = 15
                    expect(activeMarker.frame.size.width).toNot(beCloseTo(lastFrame.size.width))
                    expect(activeMarker.frame.size.height).toNot(beCloseTo(lastFrame.size.height))
                    expect(activeMarker.frame.origin.x).toNot(beCloseTo(lastFrame.origin.x))
                    expect(activeMarker.frame.origin.y).toNot(beCloseTo(lastFrame.origin.y))
                }
            }
        }
    }
}

class MockTouch: UITouch {

    let location: CGPoint
    let radius: CGFloat

    init(location: CGPoint, radius: CGFloat) {
        self.location = location
        self.radius = radius
    }

    init(marker: PASTAMarker) {
        location = marker.center
        radius = marker.radius
    }

    override func preciseLocation(in view: UIView?) -> CGPoint {
        return location
    }

    override var majorRadius: CGFloat {
        return radius
    }
}
