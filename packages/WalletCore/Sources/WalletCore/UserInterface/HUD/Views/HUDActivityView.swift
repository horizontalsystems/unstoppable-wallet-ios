import SnapKit
import UIKit

public class HUDActivityView: UIView, HUDAnimatedViewInterface, HUDTappableViewInterface, HUDContentViewInterface {
    private static let rotateKey = "rotate"

    private var _indefiniteAnimatedLayer: CAShapeLayer?
    private var pausedAnimating = false

    private var dashHeight: CGFloat
    private var dashStrokeWidth: CGFloat
    private var strokeColor: UIColor
    private var donutColor: UIColor?
    private var radius: CGFloat
    private var duration: TimeInterval

    public var centerPoint: CGFloat { radius }
    public var isAnimating = false

    public var actions: [HUDTimeAction] = []

    public var edgeInsets = UIEdgeInsets.zero {
        didSet {
            layoutAnimatedLayer()
        }
    }

    override open var frame: CGRect {
        didSet {
            if !frame.equalTo(oldValue) {
                layoutAnimatedLayer()
            }
        }
    }

    override open var bounds: CGRect {
        didSet {
            if !bounds.equalTo(oldValue) {
                layoutAnimatedLayer()
            }
        }
    }

    var indefiniteAnimatedLayer: CAShapeLayer {
        if let layer = _indefiniteAnimatedLayer {
            return layer
        }

        let smoothedPath = dashesPath()

        let animatedLayer = CAShapeLayer(layer: layer)
        animatedLayer.contentsScale = UIScreen.main.scale
        animatedLayer.frame = CGRect(origin: CGPoint(x: edgeInsets.left, y: edgeInsets.top), size: CGSize(width: centerPoint * 2, height: centerPoint * 2))
        animatedLayer.fillColor = nil
        animatedLayer.strokeColor = strokeColor.cgColor
        animatedLayer.lineWidth = dashStrokeWidth
        animatedLayer.lineCap = CAShapeLayerLineCap.round
        animatedLayer.lineJoin = CAShapeLayerLineJoin.bevel
        animatedLayer.path = smoothedPath.cgPath

        addMaskLayer(animatedLayer: animatedLayer)

        _indefiniteAnimatedLayer = animatedLayer
        return animatedLayer
    }

    func addMaskLayer(animatedLayer: CAShapeLayer) {
        let maskLayer = CALayer(layer: layer)

        maskLayer.contents = UIImage(named: "angle-mask-blur", in: nil, compatibleWith: nil)?.cgImage
        maskLayer.frame = animatedLayer.bounds
        animatedLayer.mask = maskLayer
    }

    func dashesPath() -> UIBezierPath {
        let path = UIBezierPath()
        let startWidth = radius - dashHeight + dashStrokeWidth / 2
        let endWidth = radius - dashStrokeWidth / 2
        for i in 0 ..< 8 {
            let angle = CGFloat(i) * 2 * CGFloat.pi / 8

            path.move(to: CGPoint(x: centerPoint + startWidth * cos(angle), y: centerPoint - startWidth * sin(angle)))
            path.addLine(to: CGPoint(x: centerPoint + endWidth * cos(angle), y: centerPoint - endWidth * sin(angle)))
        }
        return path
    }

    override open func sizeThatFits(_: CGSize) -> CGSize {
        CGSize(width: centerPoint * 2, height: centerPoint * 2)
    }

    public init(dashHeight: CGFloat, dashStrokeWidth: CGFloat, radius: CGFloat, strokeColor: UIColor, donutColor: UIColor? = nil, duration: TimeInterval = 1) {
        self.duration = duration
        self.dashHeight = dashHeight
        self.dashStrokeWidth = dashStrokeWidth
        self.radius = radius
        self.strokeColor = strokeColor
        self.donutColor = donutColor
        super.init(frame: .zero)

        backgroundColor = .clear
        clipsToBounds = true

        sizeToFit()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func isTappable() -> Bool {
        false
    }

    public func set(radius: CGFloat) {
        if self.radius != radius {
            self.radius = radius
            _indefiniteAnimatedLayer?.removeFromSuperlayer()
            _indefiniteAnimatedLayer = nil

            layoutAnimatedLayer()
        }
    }

    public func set(dashStrokeWidth: CGFloat) {
        self.dashStrokeWidth = dashStrokeWidth
        _indefiniteAnimatedLayer?.lineWidth = dashStrokeWidth
    }

    public func set(strokeColor: UIColor) {
        self.strokeColor = strokeColor
        _indefiniteAnimatedLayer?.strokeColor = strokeColor.cgColor
    }

    public func set(valueChanger _: SmoothValueChanger?) {}

    public func set(progress _: Float) {}

    public func layoutAnimatedLayer(forced: Bool = false) {
        guard forced || superview != nil else {
            return
        }
        let layer = indefiniteAnimatedLayer
        self.layer.addSublayer(layer)

        let positionCenter = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        layer.position = positionCenter
    }

    public func pause(layer: CALayer?) {
        let pausedTime = CFTimeInterval(layer?.convertTime(CACurrentMediaTime(), from: nil) ?? 0)
        layer?.speed = 0
        layer?.timeOffset = pausedTime
    }

    public func resume(layer: CALayer) {
        pausedAnimating = false

        let pausedTime = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }

    public func startAnimating() {
        guard !isAnimating, let layer = _indefiniteAnimatedLayer else {
            return
        }
        guard !pausedAnimating else {
            resume(layer: layer)
            return
        }

        let linearCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0
        animation.toValue = CGFloat.pi * 2
        animation.duration = duration
        animation.timingFunction = linearCurve
        animation.isRemovedOnCompletion = false
        animation.repeatCount = Float.infinity
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.autoreverses = false

        isAnimating = true

        layer.mask?.add(animation, forKey: HUDActivityView.rotateKey)
        layer.removeAnimation(forKey: HUDActivityView.rotateKey)
    }

    public func stopAnimating() {
        guard isAnimating else {
            return
        }

        isAnimating = false
        guard let layer = _indefiniteAnimatedLayer else {
            pausedAnimating = false
            return
        }

        if !pausedAnimating {
            pausedAnimating = true
            pause(layer: layer)
        }
    }

    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        if newSuperview == nil {
            _indefiniteAnimatedLayer?.removeFromSuperlayer()
            _indefiniteAnimatedLayer = nil
        } else {
            layoutAnimatedLayer(forced: true)
        }
    }

    deinit {
//        print("deinit progress view \(self)")
    }
}
