//
// Created by Aaron Krämer on 23.08.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import Quick
import Nimble
@testable import PASTA

class PASTAViewTests: QuickSpec {
    override func spec() {

        describe("a PASTA view") {
            let view = PASTAView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

            context("hit by a point") {
                let subviewCountBeforeHitTest = view.subviews.count
                let point = CGPoint(x: 10, y: 10)
                let hitTestView = view.hitTest(point, with: nil)
                it("returns a view") {
                    expect(hitTestView).toNot(beNil())
                }
                it("has additional subview") {
                    expect(view.subviews.count).to(equal(subviewCountBeforeHitTest+1))
                }
                guard let marker = hitTestView as? PASTAMarker else {
                    it("is a marker") {
                        expect(hitTestView?.isKind(of: PASTAMarker.classForKeyedUnarchiver())).to(beTruthy())
                    }
                    return
                }
                context("a second time at same position") {
                    marker.radius = 10
                    let resultView = view.hitTest(point, with: nil)
                    it("also returns a view") {
                        expect(resultView).toNot(beNil())
                        expect(resultView?.isKind(of: PASTAMarker.classForKeyedUnarchiver())).to(beTruthy())
                    }
                    it("equals previous view") {
                        expect(resultView == marker).to(beTrue())
                    }
                    it("has no additional subview") {
                        expect(view.subviews.count).to(equal(subviewCountBeforeHitTest+1))
                    }
                }
            }
        }
    }
}