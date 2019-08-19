import UIKit

class ChartBezierPath {

    static public func path(for points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: points[0])

        for i in 1..<points.count {
            path.addLine(to: points[i])
        }

        return path
    }

}
