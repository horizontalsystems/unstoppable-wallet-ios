import SnapKit
import UIExtensions
import UIKit

public protocol HUDAnimatedViewInterface {
    var isAnimating: Bool { get }
    func startAnimating()
    func stopAnimating()

    func set(valueChanger: SmoothValueChanger?)
    func set(progress: Float)
}

public protocol HUDContentViewInterface: AnyObject {
    var actions: [HUDTimeAction] { get set }
}

public protocol HUDTappableViewInterface: AnyObject {
    func isTappable() -> Bool
}

public extension HUDTappableViewInterface {
    func isTappable() -> Bool {
        true
    }
}

public protocol HUDContainerInterface: AnyObject {
    var isVisible: Bool { get }

    func outScreenOffset(for offset: CGPoint, style: HUDBannerStyle?) -> CGPoint
    func show(animated: Bool, appearStyle: HUDAppearStyle, offset: CGPoint, completion: (() -> Void)?)
    func hide(animated: Bool, appearStyle: HUDAppearStyle, offset: CGPoint, completion: (() -> Void)?)
}

open class HUDContainerView: CustomIntensityVisualEffectView, HUDContainerInterface {
    private let model: HUDContainerModel

    private var _content: UIView?
    public var onTapContainer: (() -> Void)?
    public var isVisible: Bool { !isHidden }

    public init(withModel model: HUDContainerModel) {
        self.model = model

        var effect: UIBlurEffect?
        if let style = model.blurEffectStyle {
            effect = UIBlurEffect(style: style)
        }
        super.init(effect: effect, intensity: model.blurEffectIntensity ?? 1)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        model = HUDConfig()

        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = model.backgroundColor
        layer.cornerRadius = model.cornerRadius
        clipsToBounds = true

        layer.borderWidth = model.borderWidth
        layer.borderColor = model.borderColor.cgColor
//
//        layer.shadowRadius = model.shadowRadius
//        layer.shadowColor = UIColor.black.cgColor
//        layer.shadowOpacity = 0.3
    }

    public func setContent(content: HUDContentViewInterface, preferredSize: CGSize, maxSize: CGSize, exact: Bool) {
        guard let newContent = content as? UIView else {
            return
        }
        _content?.removeFromSuperview()
        _content = newContent

        contentView.addSubview(newContent)

        newContent.snp.remakeConstraints { maker in
            maker.edges.equalToSuperview()
            if exact {
                maker.size.equalTo(preferredSize)
            } else {
                maker.size.greaterThanOrEqualTo(preferredSize)
                maker.size.lessThanOrEqualTo(maxSize)
            }
        }
        layoutIfNeeded()
    }

    public func outScreenOffset(for offset: CGPoint, style: HUDBannerStyle?) -> CGPoint {
        var outScreenOffset: CGPoint = offset
        if let style {
            switch style {
            case .top:
                outScreenOffset.y = center.y - outScreenOffset.y - bounds.height
                outScreenOffset.x = center.x
            case .left:
                outScreenOffset.x = center.x - outScreenOffset.x - bounds.width
                outScreenOffset.y = center.y
            case .bottom:
                outScreenOffset.y = center.y - outScreenOffset.y + bounds.height
                outScreenOffset.x = center.x
            case .right:
                outScreenOffset.x = center.x - outScreenOffset.x + bounds.width
                outScreenOffset.y = center.y
            }
        }
        return outScreenOffset
    }

    public func show(animated: Bool, appearStyle: HUDAppearStyle, offset: CGPoint, completion: (() -> Void)?) {
        guard isHidden else {
            completion?()
            return
        }
        let animateBlock: () -> Void
        switch appearStyle {
        case .alphaAppear:
            alpha = 0
            transform = CGAffineTransform(scaleX: model.startAdjustSize, y: model.startAdjustSize)
            animateBlock = {
                self.alpha = 1
                self.transform = CGAffineTransform.identity
            }
        case .moveOut:
            alpha = 1
            let viewCenter = center

            center = CGPoint(x: offset.x, y: offset.y)
            transform = CGAffineTransform(scaleX: model.startAdjustSize, y: model.startAdjustSize)
            animateBlock = {
                self.center = viewCenter
                self.transform = CGAffineTransform.identity
            }
        case let .sizeAppear(style):
            alpha = 1
            switch style {
            case .horizontal: transform = CGAffineTransform(scaleX: 0, y: model.startAdjustSize)
            case .vertical: transform = CGAffineTransform(scaleX: model.startAdjustSize, y: 0)
            case .both: transform = CGAffineTransform(scaleX: 0, y: 0)
            }
            animateBlock = { self.transform = CGAffineTransform.identity }
        }
        isHidden = false
        if animated {
            UIView.animate(withDuration: model.inAnimationDuration, delay: 0, options: model.animationCurve, animations: {
                animateBlock()
            }, completion: { _ in
                completion?()
            })
        } else {
            animateBlock()
            completion?()
        }
    }

    public func hide(animated: Bool, appearStyle: HUDAppearStyle, offset: CGPoint, completion: (() -> Void)?) {
        guard !isHidden else {
            completion?()
            return
        }
        let animateBlock: () -> Void
        switch appearStyle {
        case .alphaAppear:
            animateBlock = {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: self.model.finishAdjustSize, y: self.model.finishAdjustSize)
            }
        case .moveOut:
            animateBlock = {
                self.center = CGPoint(x: offset.x, y: offset.y)
                self.transform = CGAffineTransform(scaleX: self.model.finishAdjustSize, y: self.model.finishAdjustSize)
            }
        case let .sizeAppear(style):
            let viewTransform: CGAffineTransform
            switch style {
            case .horizontal: viewTransform = CGAffineTransform(scaleX: .ulpOfOne, y: model.finishAdjustSize)
            case .vertical: viewTransform = CGAffineTransform(scaleX: model.finishAdjustSize, y: .ulpOfOne)
            case .both: viewTransform = CGAffineTransform(scaleX: .ulpOfOne, y: .ulpOfOne)
            }
            animateBlock = {
                self.alpha = 0.3
                self.transform = viewTransform
            }
        }
        if animated {
            UIView.animate(withDuration: model.outAnimationDuration, delay: 0, options: model.animationCurve, animations: {
                animateBlock()
            }, completion: { [weak self] _ in
                self?.transform = CGAffineTransform.identity
                self?.isHidden = true
                completion?()
            })
        } else {
            animateBlock()
            isHidden = true
            completion?()
        }
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if let content = _content as? HUDTappableViewInterface, content.isTappable() {
            onTapContainer?()
        }
    }

    deinit {
//        print("deinit containerView \(self)")
    }
}
