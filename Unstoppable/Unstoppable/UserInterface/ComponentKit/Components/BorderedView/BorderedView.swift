import UIKit

public class BorderedView: UIView {
    private let borderLayer = CAShapeLayer()

    private var _cornerRadius: CGFloat = 0
    private var _borderWidth: CGFloat = 0
    private var _borderColor: UIColor?

    override public var cornerRadius: CGFloat {
        get { _cornerRadius }
        set {
            _cornerRadius = newValue
            layer.cornerRadius = newValue
            updateSubLayers()
        }
    }

    override public var borderWidth: CGFloat {
        get { _borderWidth }
        set {
            _borderWidth = newValue
            updateSubLayers()
        }
    }

    override public var borderColor: UIColor? {
        get { _borderColor }
        set {
            _borderColor = newValue
            updateSubLayers()
        }
    }

    public var borderStyle: BorderStyle = .solid {
        didSet {
            updateSubLayers()
        }
    }

    public var borders: UIRectEdge = .all {
        didSet {
            updateSubLayers()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.addSublayer(borderLayer)

        cornerCurve = .continuous
        borderLayer.contentsScale = UIScreen.main.scale
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func styledLinePath(border: UIRectEdge, cornerPath _: CornerPath, start: CGPoint, end: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        switch borderStyle {
        case .solid:
            path.move(to: start)
            path.addLine(to: end)
        case let .corners(length):
            switch border {
            case .top, .bottom:
                let leftBorderX = min(max(length, start.x), end.x)
                let rightBorderX = max(min(bounds.width - length, end.x), start.x)
                if leftBorderX != 0 {
                    path.move(to: start)
                    path.addLine(to: CGPoint(x: leftBorderX, y: start.y))
                }
                if rightBorderX != end.x {
                    path.move(to: CGPoint(x: rightBorderX, y: end.y))
                    path.addLine(to: end)
                }
            case .right, .left:
                let topBorderY = min(max(length, start.y), end.y)
                let bottomBorderY = max(min(bounds.height - length, end.y), start.y)
                if topBorderY != 0 {
                    path.move(to: start)
                    path.addLine(to: CGPoint(x: start.x, y: topBorderY))
                }
                if bottomBorderY != end.y {
                    path.move(to: CGPoint(x: end.x, y: bottomBorderY))
                    path.addLine(to: end)
                }
            default: ()
            }
        }
        return path
    }

    private func linePath(border: UIRectEdge, cornerPath: CornerPath) -> UIBezierPath {
        let hasLeft = borders.contains(.left)
        let hasRight = borders.contains(.right)
        let hasTop = borders.contains(.top)
        let hasBottom = borders.contains(.bottom)
        switch border {
        case .top:
            let start = cornerPath.point(edgeType: hasLeft ? .end : nil, corner: .topLeft, xOffset: hasLeft).cgPoint
            let end = cornerPath.point(edgeType: hasRight ? .start : nil, corner: .topRight, xOffset: hasRight).cgPoint
            return styledLinePath(border: border, cornerPath: cornerPath, start: start, end: end)
        case .bottom:
            let start = cornerPath.point(edgeType: hasLeft ? .start : nil, corner: .bottomLeft, xOffset: hasLeft).cgPoint
            let end = cornerPath.point(edgeType: hasRight ? .end : nil, corner: .bottomRight, xOffset: hasRight).cgPoint
            return styledLinePath(border: border, cornerPath: cornerPath, start: start, end: end)
        case .left:
            let start = cornerPath.point(edgeType: hasTop ? .start : nil, corner: .topLeft, yOffset: hasTop).cgPoint
            let end = cornerPath.point(edgeType: hasBottom ? .end : nil, corner: .bottomLeft, yOffset: hasBottom).cgPoint
            return styledLinePath(border: border, cornerPath: cornerPath, start: start, end: end)
        case .right:
            let start = cornerPath.point(edgeType: hasTop ? .end : nil, corner: .topRight, yOffset: hasTop).cgPoint
            let end = cornerPath.point(edgeType: hasBottom ? .start : nil, corner: .bottomRight, yOffset: hasBottom).cgPoint
            return styledLinePath(border: border, cornerPath: cornerPath, start: start, end: end)
        default: return UIBezierPath()
        }
    }

    private func updateSubLayers() {
        borderLayer.frame = layer.bounds
        guard !borderLayer.frame.isEmpty,
              let borderColor
        else {
            borderLayer.path = nil
            return
        }

        let cornerPath: CornerPath
        switch layer.cornerCurve {
        case .circular: cornerPath = CornerPath(lineWidth: borderWidth, rect: bounds, cornerRadius: cornerRadius)
        default: cornerPath = ContinuousCornerPath(lineWidth: borderWidth, rect: bounds, cornerRadius: cornerRadius)
        }

        let path = UIBezierPath()
        for edge in borders.toArray {
            path.append(linePath(border: edge, cornerPath: cornerPath))
        }
        for corner in borders.corners {
            path.append(cornerPath.corner(corner: corner))
        }

        borderLayer.path = path.cgPath
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.fillColor = nil
        borderLayer.lineWidth = borderWidth

        borderLayer.removeAllAnimations()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateSubLayers()
    }
}

public extension BorderedView {
    enum BorderStyle {
        case solid
        case corners(length: CGFloat)
    }
}
