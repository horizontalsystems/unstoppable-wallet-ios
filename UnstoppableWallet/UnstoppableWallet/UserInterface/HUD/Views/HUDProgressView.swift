import SnapKit
import UIKit

public class HUDProgressView: UIView, HUDAnimatedViewInterface, HUDTappableViewInterface {
    private static let rotateKey = "rotate"

    private var centerImageView: UIImageView?

    private var _baseLayer: CAShapeLayer?
    private var _indefiniteAnimatedLayer: CAShapeLayer?
    private var pausedAnimating = false

    private var strokeLineWidth: CGFloat
    private var strokeColor: UIColor
    private var donutColor: UIColor?
    private var radius: CGFloat
    private var progress: Float?
    private var duration: TimeInterval

    public var centerPoint: CGFloat { radius + strokeLineWidth / 2 }
    public var clockwise = true
    public var isAnimating = false

    private var valueChanger: SmoothValueChanger?

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
        if progress != nil, let donutColor {
            // add background donut layer
            let path = smootherPath(startAngle: CGFloat.pi * 0, endAngle: CGFloat.pi * 2)

            let ringLayer = CAShapeLayer(layer: layer)
            ringLayer.contentsScale = UIScreen.main.scale
            ringLayer.frame = CGRect(origin: .zero, size: CGSize(width: centerPoint * 2, height: centerPoint * 2))
            ringLayer.fillColor = nil
            ringLayer.strokeColor = donutColor.cgColor
            ringLayer.lineWidth = strokeLineWidth
            ringLayer.path = path.cgPath

            _baseLayer = ringLayer
        }

        let endAngle = CGFloat(1.5 + (2 * (progress ?? 2)))
        let smoothedPath = smootherPath(startAngle: CGFloat.pi * 1.5, endAngle: CGFloat.pi * endAngle)

        let animatedLayer = CAShapeLayer(layer: layer)
        animatedLayer.contentsScale = UIScreen.main.scale
        animatedLayer.frame = CGRect(origin: .zero, size: CGSize(width: centerPoint * 2, height: centerPoint * 2))
        animatedLayer.fillColor = nil
        animatedLayer.strokeColor = strokeColor.cgColor
        animatedLayer.lineWidth = strokeLineWidth
        animatedLayer.lineCap = CAShapeLayerLineCap.round
        animatedLayer.lineJoin = CAShapeLayerLineJoin.bevel
        animatedLayer.path = smoothedPath.cgPath

        if progress == nil {
            addMaskLayer(animatedLayer: animatedLayer)
        }
        if let baseLayer = _baseLayer {
            baseLayer.addSublayer(animatedLayer)
        }

        _indefiniteAnimatedLayer = animatedLayer
        return animatedLayer
    }

    func addMaskLayer(animatedLayer: CAShapeLayer) {
        let maskLayer = CALayer(layer: layer)

        maskLayer.contents = UIImage(named: "angle-mask", in: nil, compatibleWith: nil)?.cgImage
        maskLayer.frame = animatedLayer.bounds
        animatedLayer.mask = maskLayer
    }

    func smootherPath(startAngle: CGFloat, endAngle: CGFloat) -> UIBezierPath {
        let arcCenter = CGPoint(x: centerPoint, y: centerPoint)
        return UIBezierPath(arcCenter: arcCenter, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
    }

    override open func sizeThatFits(_: CGSize) -> CGSize {
        CGSize(width: centerPoint * 2, height: centerPoint * 2)
    }

    public init(progress: Float? = nil, strokeLineWidth: CGFloat, radius: CGFloat, strokeColor: UIColor, donutColor: UIColor? = nil, duration: TimeInterval = 1) {
        self.progress = progress
        self.duration = duration
        self.strokeLineWidth = strokeLineWidth
        self.radius = radius
        self.strokeColor = strokeColor
        self.donutColor = donutColor
        super.init(frame: .zero)

        commonInit()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        backgroundColor = .clear
        clipsToBounds = true

        sizeToFit()
    }

    public func appendInCenter(image: UIImage?) {
        guard centerImageView == nil else {
            centerImageView?.image = image
            return
        }
        let imageView = UIImageView(image: image)
        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }
        centerImageView = imageView
        centerImageView?.alpha = 0
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.centerImageView?.alpha = 1
        }
    }

    public func isTappable() -> Bool {
        centerImageView != nil
    }

    public func set(radius: CGFloat) {
        if self.radius != radius {
            self.radius = radius
            _baseLayer?.removeFromSuperlayer()
            _baseLayer = nil
            _indefiniteAnimatedLayer?.removeFromSuperlayer()
            _indefiniteAnimatedLayer = nil

            layoutAnimatedLayer()
        }
    }

    public func set(strokeThickness: CGFloat) {
        strokeLineWidth = strokeThickness
        _baseLayer?.lineWidth = strokeThickness
        _indefiniteAnimatedLayer?.lineWidth = strokeThickness
    }

    public func set(strokeColor: UIColor) {
        self.strokeColor = strokeColor
        _indefiniteAnimatedLayer?.strokeColor = strokeColor.cgColor
    }

    public func set(valueChanger: SmoothValueChanger?) {
        self.valueChanger = valueChanger
    }

    public func set(progress: Float) {
        guard self.progress != nil else {
            // can't change progress from indefinite to custom value
            return
        }
        let endAngle: CGFloat
        if clockwise {
            endAngle = CGFloat.pi * CGFloat(1.5 + 2 * progress)
        } else {
            endAngle = CGFloat.pi * CGFloat(1.5 - 2 * progress)
        }
        _indefiniteAnimatedLayer?.path = smootherPath(startAngle: CGFloat.pi * 1.5, endAngle: endAngle).cgPath
        self.progress = progress
    }

    public func layoutAnimatedLayer(forced: Bool = false) {
        guard forced || superview != nil else {
            return
        }
        let layer = indefiniteAnimatedLayer
        self.layer.addSublayer(_baseLayer ?? layer)

        let positionCenter = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        if let baseLayer = _baseLayer {
            baseLayer.position = positionCenter
            let sublayerPosition = radius + strokeLineWidth / 2
            layer.position = CGPoint(x: sublayerPosition, y: sublayerPosition)
        } else {
            layer.position = positionCenter
        }
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
        if progress != nil {
            layer.add(animation, forKey: HUDProgressView.rotateKey)
            layer.mask?.removeAnimation(forKey: HUDProgressView.rotateKey)

            layer.removeAnimation(forKey: "progress")
        } else {
            layer.mask?.add(animation, forKey: HUDProgressView.rotateKey)
            layer.removeAnimation(forKey: HUDProgressView.rotateKey)

            let animationGroup = CAAnimationGroup()
            animationGroup.duration = duration
            animationGroup.repeatCount = Float.infinity
            animationGroup.isRemovedOnCompletion = false
            animationGroup.timingFunction = linearCurve
            let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
            strokeStartAnimation.fromValue = 0.015
            strokeStartAnimation.toValue = 0.515

            let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
            strokeEndAnimation.fromValue = 0.485
            strokeEndAnimation.toValue = 0.985

            animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
            layer.add(animationGroup, forKey: "progress")
        }
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
