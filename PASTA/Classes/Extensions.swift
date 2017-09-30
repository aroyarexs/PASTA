//
// Created by Aaron Krämer on 16.08.17.
// Copyright (c) 2017 Aaron Krämer. All rights reserved.
//

import CoreGraphics
import Metron

extension CGVector {

    /// Since coordinate system zero point is on the top left this vector is pointing from (0,0) to (0,-1).
    static var normalizedUp: CGVector {
        return CGVector(from: .zero, to: CGPoint(x: 0, y: -1))
    }

    /**
     Creates a new vector facing from point `from` to point `to`.
     - parameters:
        - from: A point.
        - to: A point.
     */
    init(from: CGPoint, to: CGPoint) {
        self.init(dx: to.x - from.x, dy: to.y - from.y)
    }

    /// The receiver as normalized vector. `dx` and `dy` divided by `distance`.
    var normalized: CGVector {
        let length = magnitude
        return CGVector(dx: dx/length, dy: dy/length)
    }
    /**
     Calculates the angle in radians between this and `vector`.
     Return value ranges from -π to π.
     A positive value indicates the receiver is ahead of `vector` in a clockwise direction.
     Negative value analog.
     ## Reference:
     [http://www.euclideanspace.com](http://www.euclideanspace.com/maths/algebra/vectors/angleBetween/issues/index.htm)
     - parameters:
        - vector: Another vector.
        - absolute: If `true` the return value will always be a non-negative value.
     - returns: The angle in radians between -π and π (0 to π, if `absolute` is `true`).
     */
    func angleRadians(between vector: CGVector, absolute: Bool = false) -> CGFloat {   // TODO: put radians in name
        var radian = CoreGraphics.atan2(vector.dy, vector.dx) - CoreGraphics.atan2(dy, dx)

        if radian > CGFloat.pi {
            radian -= CGFloat.pi * 2
        } else if radian < -CGFloat.pi {
            radian += CGFloat.pi * 2
        }
        return absolute ? abs(radian) : radian
    }

    /**
     Returns a new vector rotated by `degrees`.
     Rotation is clockwise since coordinate system of iOS is mirrored on x-axis.
     - parameter degrees: The angle the vector should be rotated.
     - returns: A new vector rotated by `degrees`.
     */
    func rotate(degrees: CGFloat) -> CGVector {
        let p = CGPoint(x: dx, y: dy).rotate(around: CGPoint.zero, degrees: degrees)
        return CGVector(dx: p.x, dy: p.y)
    }
}

extension CGPoint {

    /**
     Obtain center of a circle if you know two points on the circle and its radius.
     (There should be two solutions).
     If `radius` is smaller than half the distance between `point1` and `point2`,
     radius is set to half the distance of these points.
     ### Reference
     [mathforum.org](http://mathforum.org/library/drmath/view/53027.html)
     - parameters:
        - point1: A point on the circle line.
        - point2: A point on the circle line.
        - radius: The radius of the circle
     - returns: A tuple of two points representing the center of possible circles.
     */
    static func circleCenters(point1: CGPoint, point2: CGPoint, radius: CGFloat) -> (CGPoint, CGPoint) {
        /// distance between points 1 and 2
        let q = CGVector(from: point1, to: point2).magnitude
        guard q != 0 else { return (point1, point1) }

        /// halfway between points 1 and 2
        let h = CGPoint(x: (point1.x + point2.x) / 2, y: (point1.y + point2.y) / 2)

        let radius = radius < q/2 ? q/2 : radius
        /// distance to move along the mirror line
        let d = sqrt(pow(radius, 2) - pow(q/2, 2))

        /// "normalize" direction which means to make length of the line equal to 1
        let nx = (point2.x - point1.x)/q
        let ny = (point1.y - point2.y)/q

        // One answer will be:
        var c1 = CGPoint.zero
        c1.x = h.x + d * ny
        c1.y = h.y + d * nx

        // The other will be:
        var c2 = CGPoint.zero
        c2.x = h.x - d * ny
        c2.y = h.y - d * nx

        return (c1, c2)
    }

    /**
     Adds `rhs` to `lhs`.
     - parameters:
        - first: A point.
        - second: A point.
     - returns: A new point representing the transition.
     */
    static func + (_ lhs: CGPoint, _ rhs: CGPoint) -> CGPoint {
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        return CGPoint(x: x, y: y)
    }

    /**
     Adds `rhs` to x and y coordinate of `lhs`.
     - parameters:
        - first: A point.
        - second: A float.
     - returns: A new point representing the transition.
     */
    static func + (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
    }

    /**
     Subtracts `rhs` of `lhs`.
     - parameters:
        - first: A point.
        - second: A float.
     - returns: A new point representing the transition.
     */
    static func - (_ lhs: CGPoint, _ rhs: CGFloat) -> CGPoint {
        return lhs + (-rhs)
    }

    /**
    Rotates this point around `origin` by `degrees` clockwise.
    Clockwise because iOS coordinate system is inverted at x-axis.
     ## Reference
     [StackOverflow](https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint#35683523)
     - parameters:
        - origin: Origin of the rotation.
        - degrees: Rotation in degrees.
     - returns: The new position after rotation.
     */
    func rotate(around origin: CGPoint, degrees: CGFloat) -> CGPoint {
        let vector = CGVector(from: origin, to: self)
        let azimuth = CoreGraphics.atan2(vector.dy, vector.dx) // in radians
        let newAzimuth = azimuth + degrees * CGFloat.pi / 180.0 // convert it to radians
        let radius = vector.magnitude
        return origin + CGPoint(x: radius * cos(newAzimuth), y: radius * sin(newAzimuth))
    }

    /**
     Returns the point closest to the receiver.
     If `point1` is closer or as close as `point2` `point1` will be returned, otherwise `point2`.
     - parameters:
        - point1: A point.
        - point2: A point.
     - returns: `point1` if it closer to the receiver, otherwise `point2`.
     */
    func closest(point1: CGPoint, point2: CGPoint) -> CGPoint {
        let v1 = CGVector(from: self, to: point1)
        let v2 = CGVector(from: self, to: point2)
        return v1.magnitude <= v2.magnitude ? point1 : point2
    }
}

extension CGFloat {

    /// Converts value to degree.
    var radianToDegree: CGFloat {
        return self * 180.0 / CGFloat.pi
    }
}
