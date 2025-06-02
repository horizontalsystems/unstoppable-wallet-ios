import UIKit

open class ContinuousCornerPath: CornerPath {
    private static let ellipseCoefficient: CGFloat = 1.28195
    private static let coefficients: [CGFloat] = [0.04641, 0.08715, 0.13357, 0.16296, 0.21505, 0.290086, 0.32461, 0.37801, 0.44576, 0.6074, 0.77037]

    override var cornerCoefficient: CGFloat { Self.ellipseCoefficient }

    private func points(corner: UIRectCorner) -> [ControlPoint] {
        let radius = cornerRadius
        let shift: (Bool, Int) -> CGFloat = { (positive: Bool, index: Int) in
            radius * (positive ? 1 : -1) * Self.coefficients[index]
        }

        let xOp = [UIRectCorner.topRight, UIRectCorner.bottomRight].contains(corner)
        let yOp = [UIRectCorner.topLeft, UIRectCorner.topRight].contains(corner)

        let p0 = point(edgeType: .start, corner: corner)
        let p0cp1 = p0.shifted(x: shift(xOp, 8))
        let p0cp2 = p0.shifted(x: shift(xOp, 9), y: shift(yOp, 0))

        let p1 = p0.shifted(x: shift(xOp, 10), y: shift(yOp, 2))
        let p1cp1 = p1.shifted(x: shift(xOp, 3), y: shift(yOp, 1))
        let p1cp2 = p1.shifted(x: shift(xOp, 5), y: shift(yOp, 4))

        let p2 = p1.shifted(x: shift(xOp, 7), y: shift(yOp, 7))
        let p2cp1 = p2.shifted(x: shift(xOp, 1), y: shift(yOp, 3))
        let p2cp2 = p2.shifted(x: shift(xOp, 2), y: shift(yOp, 6))
        let p3 = point(edgeType: .end, corner: corner)

        return [
            ControlPoint(p0.cgPoint, p0cp1.cgPoint, p0cp2.cgPoint),
            ControlPoint(p1.cgPoint, p1cp1.cgPoint, p1cp2.cgPoint),
            ControlPoint(p2.cgPoint, p2cp1.cgPoint, p2cp2.cgPoint),
            ControlPoint(p3.cgPoint, .zero, .zero),
        ]
    }

    override open func corner(corner: UIRectCorner) -> UIBezierPath {
        let path = UIBezierPath()

        let cp = points(corner: corner)

        path.move(to: cp[0].point)
        path.addCurve(to: cp[1].point, controlPoint1: cp[0].cp1, controlPoint2: cp[0].cp2)
        path.addCurve(to: cp[2].point, controlPoint1: cp[1].cp1, controlPoint2: cp[1].cp2)
        path.addCurve(to: cp[3].point, controlPoint1: cp[2].cp1, controlPoint2: cp[2].cp2)

        return path
    }
}
