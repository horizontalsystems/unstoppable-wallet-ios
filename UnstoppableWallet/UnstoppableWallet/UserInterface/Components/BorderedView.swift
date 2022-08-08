import UIKit

class BorderedView: UIView {
    private let borderLayer = CAShapeLayer()
    private var _cornerRadius: CGFloat = 0
    private var _borderWidth: CGFloat = 0
    private var _borderColor: UIColor?

    override var cornerRadius: CGFloat {
        get { _cornerRadius }
        set {
            _cornerRadius = newValue
            layer.cornerRadius = newValue
            updateSubLayers()
        }
    }

    override var borderWidth: CGFloat {
        get { _borderWidth }
        set {
            _borderWidth = newValue
            updateSubLayers()
        }
    }

    override var borderColor: UIColor? {
        get { _borderColor }
        set {
            _borderColor = newValue
            updateSubLayers()
        }
    }

    var borderStyle: BorderStyle = .solid {
        didSet {
            updateSubLayers()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        layer.addSublayer(borderLayer)

        borderLayer.contentsScale = UIScreen.main.scale
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSubLayers() {
        borderLayer.frame = layer.bounds
        guard !borderLayer.frame.isEmpty,
              let borderColor = borderColor
        else {
            borderLayer.path = nil
            return
        }

        let offset: CGFloat = borderWidth / 2
        let min = CGPoint(x: 0 + offset, y: 0 + offset)
        let max = CGPoint(x: borderLayer.frame.width - offset, y: borderLayer.frame.height - offset)

        let cornerRadius = cornerRadius - offset
        let borderPath: UIBezierPath

        switch borderStyle {
        case .solid:
            let size = CGSize(width: borderLayer.frame.width - 2 * offset, height: borderLayer.frame.height - 2 * offset)
            borderPath = UIBezierPath(roundedRect: CGRect(origin: min, size: size), cornerRadius: cornerRadius)
        case .corners(let fullLength):
            let length = fullLength - cornerRadius
            borderPath = UIBezierPath()
            // top left
            borderPath.move(to: CGPoint(x: min.x, y: min.y + cornerRadius + length))
            borderPath.addLine(to: CGPoint(x: min.x, y: min.y + cornerRadius))
            borderPath.addArc(withCenter: CGPoint(x: min.x + cornerRadius, y: min.y + cornerRadius), radius: cornerRadius, startAngle: .pi, endAngle: -0.5 * .pi, clockwise: true)
            borderPath.addLine(to: CGPoint(x: min.x + cornerRadius + length, y: min.y))
            // top right
            borderPath.move(to: CGPoint(x: max.x - cornerRadius - length, y: min.y))
            borderPath.addLine(to: CGPoint(x: max.x - cornerRadius, y: min.y))
            borderPath.addArc(withCenter: CGPoint(x: max.x - cornerRadius, y: min.y + cornerRadius), radius: cornerRadius, startAngle: 1.5 * .pi, endAngle: 2 * .pi, clockwise: true)
            borderPath.addLine(to: CGPoint(x: max.x, y: min.y + cornerRadius + length))
            // bottom right
            borderPath.move(to: CGPoint(x: max.x, y: max.y - cornerRadius - length))
            borderPath.addLine(to: CGPoint(x: max.x, y: max.y - cornerRadius))
            borderPath.addArc(withCenter: CGPoint(x: max.x - cornerRadius, y: max.y - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: 0.5 * .pi, clockwise: true)
            borderPath.addLine(to: CGPoint(x: max.x - cornerRadius - length, y: max.y))
            // bottom left
            borderPath.move(to: CGPoint(x: min.x + cornerRadius + length, y: max.y))
            borderPath.addLine(to: CGPoint(x: min.x + cornerRadius, y: max.y))
            borderPath.addArc(withCenter: CGPoint(x: min.x + cornerRadius, y: max.y - cornerRadius), radius: cornerRadius, startAngle: 0.5 * .pi, endAngle: .pi, clockwise: true)
            borderPath.addLine(to: CGPoint(x: min.x, y: max.y - cornerRadius - length))
        }

        borderLayer.path = borderPath.cgPath
        borderLayer.strokeColor = borderColor.cgColor
        borderLayer.lineWidth = borderWidth
        borderLayer.fillColor = nil
    }

    override public func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        updateSubLayers()
    }
}

extension BorderedView {
    enum BorderStyle {
        case solid
        case corners(length: CGFloat)
    }
}
