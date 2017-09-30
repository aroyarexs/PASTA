//
// Created by Aaron Krämer on 21.08.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import Quick
import Nimble
import Metron
@testable import PASTA

class PASTATangibleTests: QuickSpec {
    override func spec() {
        var m1: PASTAMarker!
        var m2: PASTAMarker!
        var m3: PASTAMarker!
        var t: PASTATangible?

        beforeEach {
            m1 = PASTAMarker(center: CGPoint(x: 0, y: 10), radius: 5)
            m2 = PASTAMarker(center: CGPoint.zero, radius: 5)
            m3 = PASTAMarker(center: CGPoint(x: 10, y: 0), radius: 5)
            t = PASTATangible(markers: [m1, m2, m3])
        }
        describe("a Tangible") {
            it("is not nil") {
                expect(t).toNot(beNil())
            }
            it("is active") {
                guard let tangible = t else { return }
                expect(tangible.isActive).to(beFalse())
            }
            it("has center") {
                guard let tangible = t else { return }
                expect(tangible.center).to(equal(CGPoint(x: 5, y: 5)))
            }
            it("has markers") {
                guard let tangible = t else { return }
                expect(tangible.markers.count).to(equal(3))
            }
            it("has radius") {
                guard let tangible = t else { return }
                expect(tangible.radius).to(beCloseTo(14.1421/2.0))
            }
            it("has orientation") {
                guard let tangible = t else { return }
                let angle = CGVector.normalizedUp.angle(between: tangible.initialOrientationVector)
                expect(angle.degrees).to(equal(0))
                expect(tangible.orientationVector).toNot(beNil())
            }
            it("is similar to itself") {
                guard let tangible = t else { return }
                expect(tangible ~ tangible).to(beTrue())
            }
            it("has interior angle") {
                guard let tangible = t else { return }
                let m1UuidString = m1.markerSnapshot.uuidString
                let m2UuidString = m2.markerSnapshot.uuidString
                let m3UuidString = m3.markerSnapshot.uuidString
                expect(tangible.pattern.angle(atMarkerWith: m1UuidString).degrees).to(beCloseTo(45))
                expect(tangible.pattern.angle(atMarkerWith: m2UuidString).degrees).to(beCloseTo(90))
                expect(tangible.pattern.angle(atMarkerWith: m3UuidString).degrees).to(beCloseTo(45))
            }
            it("markers their tangible property is set") {
                expect(m1.tangible).toNot(beNil())
                expect(m2.tangible).toNot(beNil())
                expect(m3.tangible).toNot(beNil())
            }

            context("rotated") {
                it("has orientation") {
                    guard let tangible = t else { return }
                    let vectorBeforeRotation = tangible.orientationVector
                    let angle = Angle(56, unit: .degrees)
                    m1.center = LineSegment(a: tangible.center, b: m1.center).rotatedAroundA(angle).b
                    m2.center = LineSegment(a: tangible.center, b: m2.center).rotatedAroundA(angle).b
                    m3.center = LineSegment(a: tangible.center, b: m3.center).rotatedAroundA(angle).b
                    let up = CGVector.normalizedUp
                    let angle1 = up.angle(between: tangible.initialOrientationVector)
                    expect(angle1.degrees).to(beCloseTo(56))

                    expect(tangible.orientationVector).toNot(beNil())
                    guard let v = tangible.orientationVector, let v2 = vectorBeforeRotation else {
                        fail()
                        return
                    }
                    let angle2 = v.angle(between: v2, absolute: true)
                    expect(angle2.degrees).to(beCloseTo(56))
                }
            }

            context("one is moving") {
                var beforeRadius: CGFloat?
                beforeEach {
                    beforeRadius = t?.radius
                    m1.center = m1.center.applying(.init(translationX: 0, y: -5))
                    m1.tangible?.markerMoved(m1)
                }
                it("center changes") {
                    guard let tangible = t else { return }
                    expect(tangible.center.y) < tangible.previousCenter.y
                }
                it("radius changes") {
                    guard let tangible = t, let befRadius = beforeRadius else { return }
                    expect(tangible.radius) < befRadius
                }
            }

            context("one active marker") {
                beforeEach {
                    m2.isActive = true
                }
                it("has two inactive") {
                    guard let tangible = t else { return }
                    expect(tangible.inactiveMarkers.count) == 2
                }
                it("will replace an inactive marker") {
                    guard let tangible = t else { return }
                    let marker = PASTAMarker(center: CGPoint(x: 2, y: 9), radius: 5)
                    marker.isActive = true
                    let success = tangible.replaceInactiveMarker(with: marker)
                    expect(success) == true
                    expect(tangible.markers.contains(marker)) == true
                    expect(tangible.inactiveMarkers.count) == 1
                }
                it("won't replace inactive marker") {
                    guard let tangible = t else { return }
                    let marker = PASTAMarker(center: CGPoint(x: 4, y: 2.5), radius: 5)
                    marker.isActive = true
                    let success = tangible.replaceInactiveMarker(with: marker)
                    expect(success) == false
                    expect(tangible.markers.contains(marker)) == false
                    expect(tangible.inactiveMarkers.count) == 2
                }

                context("all marker active") {
                    var activePattern: PASTAPattern!
                    beforeEach {
                        m1.isActive = true
                        m3.isActive = true
                        activePattern = t!.pattern
                    }
                    it("has no inactive marker") {
                        guard let tangible = t else { return }
                        expect(tangible.inactiveMarkers.isEmpty) == true
                    }
                    context("m3 is inactive") {
                        var inactivePattern: PASTAPattern!
                        beforeEach {
                            var touches = Set<MockTouch>()
                            touches.insert(MockTouch(location: m3.center, radius: m3.radius))
                            m3.touchesEnded(touches, with: nil)
                            inactivePattern = t!.pattern
                        }
                        it("has an inactive marker") {
                            guard let tangible = t else { return }
                            expect(tangible.inactiveMarkers.count) == 1
                        }
                        it("current and previous pattern are similar") {
                            guard let tangible = t else { return }
                            expect(activePattern.isSimilar(to: tangible.pattern)) == true
                        }
                        it("m3 marker did not moved") {
                            expect(m3.center) == m3.previousCenter
                        }
                        context("m3 active again") {
                            var secondActivePattern: PASTAPattern!
                            beforeEach {
                                var touches = Set<MockTouch>()
                                touches.insert(MockTouch(location: m3.center, radius: m3.radius))
                                m3.touchesBegan(touches, with: nil)
                                secondActivePattern = t!.pattern
                            }
                            it("has no inactive markers") {
                                guard let tangible = t else { return }
                                expect(tangible.inactiveMarkers.isEmpty) == true
                            }
                            it("pattern similar to previous") {
                                guard let tangible = t else { return }
                                expect(tangible.pattern.isSimilar(to: inactivePattern)) == true
                            }
                            it("m3 marker did not moved") {
                                expect(m3.center) == m3.previousCenter
                            }
                            context("m3 inactive again") {
                                beforeEach {
                                    var touches = Set<MockTouch>()
                                    touches.insert(MockTouch(location: m3.center, radius: m3.radius))
                                    m3.touchesEnded(touches, with: nil)
                                }
                                it("has an inactive marker") {
                                    guard let tangible = t else { return }
                                    expect(tangible.inactiveMarkers.count) == 1
                                }
                                it("m3 marker did not moved") {
                                    expect(m3.center) == m3.previousCenter
                                }
                                it("pattern similar to previous") {
                                    guard let tangible = t else { return }
                                    expect(tangible.pattern.isSimilar(to: secondActivePattern)) == true
                                }

                            }
                        }
                    }
                }
            }

            context("received a marker-moved event") {
                var translation: CGPoint!
                var prevTangibleRadius: CGFloat?
                beforeEach {
                    prevTangibleRadius = t?.radius
                    var touches = Set<MockTouch>()
                    let angle = Angle(45, unit: .degrees)
                    let newMarkerPosition = LineSegment(a: m2.center, b: m1.center).rotatedAroundA(angle).b
                    translation = (newMarkerPosition - m1.center).point
                    touches.insert(MockTouch(location: newMarkerPosition, radius: 11))
                    m1.touchesBegan(touches, with: nil)
                }
                it("has one active marker") {
                    guard let tangible = t else { return }
                    expect(tangible.inactiveMarkers.count).to(equal(2))
                }
                it("is active") {
                    guard let tangible = t else { return }
                    expect(tangible.isActive).to(beTrue())
                }
                it("active marker moved") {
                    expect(m1.center.x).to(beCloseTo(m1.previousCenter.x + translation.x))
                    expect(m1.center.y).to(beCloseTo(m1.previousCenter.y + translation.y))
                }
                it("inactive markers moved") {
                    expect(m2.center.x).to(beCloseTo(m2.previousCenter.x + translation.x))
                    expect(m2.center.y).to(beCloseTo(m2.previousCenter.y + translation.y))
                    expect(m3.center.x).to(beCloseTo(m3.previousCenter.x + translation.x))
                    expect(m3.center.y).to(beCloseTo(m3.previousCenter.y + translation.y))
                }
                it("center moved") {
                    guard let tangible = t else { return }
                    expect(tangible.center.x).to(beCloseTo(tangible.previousCenter.x + translation.x))
                    expect(tangible.center.y).to(beCloseTo(tangible.previousCenter.y + translation.y))
                }
                it("frame updates") {
                    guard let tangible = t else { return }
                    expect(tangible.frame.origin).to(equal(tangible.center.applying(
                            .init(translationX: -tangible.radius, y: -tangible.radius))))
                    expect(tangible.frame.width).to(equal(tangible.radius*2))
                }
                it("radius did not changed") {
                    guard let tangible = t, let prevRadius = prevTangibleRadius else { return }
                    expect(tangible.radius).to(beCloseTo(prevRadius))
                }

                context("received marker-moved event from different marker") {
                    var prevTangibleRadius2: CGFloat?
                    beforeEach {
                        prevTangibleRadius2 = t?.radius

                        var touches2 = Set<MockTouch>()
                        let angle = Angle(45, unit: .degrees)
                        let newMarkerPosition2 = LineSegment(a: m1.center, b: m2.center).rotatedAroundA(angle).b
                        touches2.insert(MockTouch(location: newMarkerPosition2, radius: 11))
                        m2.touchesBegan(touches2, with: nil)
                    }
                    it("has two active markers") {
                        guard let tangible = t else { return }
                        expect(tangible.inactiveMarkers.count).to(equal(1))
                    }
                    it("radius did not changed") {
                        guard let tangible = t, let rad = prevTangibleRadius2 else { return }
                        expect(tangible.radius).to(beCloseTo(rad))
                    }
                    it("is active") {
                        guard let tangible = t else { return }
                        expect(tangible.isActive).to(beTrue())
                    }
                    it("center moved") {
                        guard let tangible = t else { return }
                        let prevCenter = Triangle(a: m1.center,
                                b: m2.previousCenter,
                                c: tangible.inactiveMarkers.first!.previousCenter).cicrumcenter
                        expect(prevCenter.x).toNot(beCloseTo(tangible.center.x, within: 0.1))
                        expect(prevCenter.y).toNot(beCloseTo(tangible.center.y, within: 0.1))
                        expect(tangible.previousCenter.x).to(beCloseTo(prevCenter.x))
                        expect(tangible.previousCenter.y).to(beCloseTo(prevCenter.y))
                    }
                    xit("inactive marker moved") {  // FIXME: update
                        let v1 = CGVector(from: m1.center, to: m3.previousCenter)
                        let angle = CGVector(from: m1.center, to: m3.center).angle(between: v1, absolute: true)
                        expect(angle.degrees).to(beCloseTo(45))

                        let rotationAngle = Angle(45, unit: .degrees)
                        let newPos = LineSegment(a: m1.center, b: m3.previousCenter).rotatedAroundA(rotationAngle).b
                        expect(m3.center.x).to(beCloseTo(newPos.x))
                        expect(m3.center.y).to(beCloseTo(newPos.y))
                    }
                    it("other active marker did not moved") {
                        expect(m1.center.x).to(beCloseTo(m1.previousCenter.x + translation.x))
                        expect(m1.center.y).to(beCloseTo(m1.previousCenter.y + translation.y))
                    }
                    it("active marker moved") {
                        let cv = CGVector(from: m1.center, to: m2.center)
                        let ov = CGVector(from: m1.center, to: m2.previousCenter)
                        let angle = cv.angle(between: ov, absolute: true)
                        expect(angle.degrees).to(beCloseTo(45))

                        let rotationAngle = Angle(45, unit: .degrees)
                        let newPos = LineSegment(a: m1.center, b: m2.previousCenter).rotatedAroundA(rotationAngle).b
                        expect(m2.center.x).to(beCloseTo(newPos.x))
                        expect(m2.center.y).to(beCloseTo(newPos.x))
                    }
                }
            }
        }

        describe("a Tangible init with coder") {
            expect(PASTATangible(coder: NSCoder())).to(beNil())
        }

        describe("a mocked Tangible") {
            var t: MockTangibleMarkerMovedCalled?
            beforeEach {
                t = MockTangibleMarkerMovedCalled(markers: [m1, m2, m3])
            }
            it("is not nil") {
                expect(t).toNot(beNil())
            }
            it("calls marker moved") {
                var touches = Set<MockTouch>()
                touches.insert(MockTouch(location: CGPoint(x: 5, y: -5), radius: 11))
                m1.touchesMoved(touches, with: nil)
                guard let tangible = t else { return }
                expect(tangible.called).to(beTrue())
            }
        }
    }
}

class MockTangibleMarkerMovedCalled: PASTATangible {

    var called = false

    override func markerMoved(_ marker: PASTAMarker) {
        called = true
    }
}
