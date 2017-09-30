//
// Created by Aaron Krämer on 29.08.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import Quick
import Nimble
@testable import PASTA

class PASTAManagerTests: QuickSpec {
    override func spec() {

        describe("a tangible manager") {
            var manager: PASTAManager!
            beforeEach {
                manager = PASTAManager()
            }

            it("has empty sets") {
                expect(manager.complete.isEmpty) == true
                expect(manager.incomplete.isEmpty) == true
            }

            it("can compose a tangible") {
                let m1 = PASTAMarker(center: CGPoint.zero)
                let m2 = PASTAMarker(center: CGPoint(x: 1, y: 0))
                let m3 = PASTAMarker(center: CGPoint(x: 0, y: 1))
                let success = manager.compose(markers: [m1, m2, m3])
                expect(success) == true
            }

            it("has no unassigned marker") {
                expect(manager.unassigned.isEmpty) == true
            }
            context("with a marker becoming active") {
                var marker: PASTAMarker!
                var touches: Set<MockTouch>!
                beforeEach {
                    marker = PASTAMarker(center: CGPoint.zero)
                    marker.markerManager = manager
                    touches = Set<MockTouch>(minimumCapacity: 1)
                    touches.insert(MockTouch(location: CGPoint.zero, radius: 0.0))
                    marker.touchesBegan(touches, with: nil)
                }
                it("is added to set") {
                    expect(manager.unassigned.contains(marker)) == true
                }
                it("calls markerDidBecomeActive") {
                    let mockManager = MockMarkerManager()
                    marker.markerManager = mockManager
                    marker.touchesBegan(touches, with: nil)
                    expect(mockManager.didBecomeActiveIsCalled) == true
                    expect(mockManager.didBecomeInactiveIsCalled) == false
                }
                context("same marker becoming inactive") {
                    it("calls markerDidBecomeInactive") {
                        let mockManager = MockMarkerManager()
                        marker.markerManager = mockManager
                        marker.touchesEnded(touches, with: nil)
                        expect(mockManager.didBecomeActiveIsCalled) == false
                        expect(mockManager.didBecomeInactiveIsCalled) == true
                    }
                    it("is removed from set") {
                        marker.touchesBegan(touches, with: nil)
                        expect(manager.unassigned.contains(marker)) == true
                        marker.touchesEnded(touches, with: nil)
                        expect(manager.unassigned.contains(marker)) == false
                    }
                }
                context("two different marker turning active") {
                    var m1: PASTAMarker!
                    var m2: PASTAMarker!
                    beforeEach {
                        m1 = PASTAMarker(center: CGPoint(x: 10, y: 0))
                        m2 = PASTAMarker(center: CGPoint(x: 0, y: 10))
                        m1.markerManager = manager
                        m2.markerManager = manager
                        var touches1 = Set<MockTouch>(minimumCapacity: 1)
                        var touches2 = Set<MockTouch>(minimumCapacity: 1)
                        touches1.insert(MockTouch(marker: m1))
                        touches2.insert(MockTouch(marker: m2))
                        m1.touchesBegan(touches1, with: nil)
                        m2.touchesBegan(touches2, with: nil)
                    }
                    it("composed tangible") {
                        expect(manager.complete.isEmpty) == true
                    }
                    it("has no unassigned marker") {
                        expect(manager.unassigned.isEmpty) == true
                    }
                }
                context("disabling pattern whitelist") {
                    beforeEach {
                        manager.patternWhitelistDisabled = true
                    }
                    context("two different marker turning active") {
                        var m1: PASTAMarker!
                        var m2: PASTAMarker!
                        beforeEach {
                            m1 = PASTAMarker(center: CGPoint(x: 10, y: 0))
                            m2 = PASTAMarker(center: CGPoint(x: 0, y: 10))
                            m1.markerManager = manager
                            m2.markerManager = manager
                            var touches1 = Set<MockTouch>(minimumCapacity: 1)
                            var touches2 = Set<MockTouch>(minimumCapacity: 1)
                            touches1.insert(MockTouch(marker: m1))
                            touches2.insert(MockTouch(marker: m2))
                            m1.touchesBegan(touches1, with: nil)
                            m2.touchesBegan(touches2, with: nil)
                        }
                        it("composed tangible") {
                            expect(manager.complete.count) == 1
                        }
                        it("has no unassigned marker") {
                            expect(manager.unassigned.isEmpty) == true
                        }
                        context("one marker gets inactive and new marker inside tangible gets active") {
                            var newMarker: PASTAMarker!
                            beforeEach {
                                var touches1 = Set<MockTouch>(minimumCapacity: 1)
                                touches1.insert(MockTouch(marker: m1))
                                m1.touchesEnded(touches1, with: nil)

                                newMarker = PASTAMarker(center: CGPoint(x: 9, y: 1))
                                var touches2 = Set<MockTouch>(minimumCapacity: 1)
                                touches2.insert(MockTouch(marker: newMarker))
                                newMarker.touchesBegan(touches1, with: nil)
                            }
                            it("is not insert to unassigned markers") {
                                expect(manager.unassigned.isEmpty) == true
                            }
                        }
                    }
                }
            }
        }
    }
}

class MockMarkerManager: MarkerStatus {

    var didBecomeActiveIsCalled = false
    var didBecomeInactiveIsCalled = false

    func markerDidBecomeActive(_ marker: PASTAMarker) {
        didBecomeActiveIsCalled = true
    }

    func markerDidBecomeInactive(_ marker: PASTAMarker) {
        didBecomeInactiveIsCalled = true
    }
}
