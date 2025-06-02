import SnapKit
import ThemeKit
import UIKit

open class SliderButton: UIView {
    public static let margin: CGFloat = 3
    public static let height: CGFloat = margin + .heightButton + margin

    private let fillView = UIView()
    private let label = UILabel()
    private let finalLabel = UILabel()
    private let circleView = UIView()
    private let slideImageView = UIImageView()
    private let finalImageView = UIImageView()

    private var circleConstraint: Constraint? = nil
    private var fillInitialConstraint: Constraint? = nil
    private var fillFinalConstraint: Constraint? = nil

    private var maxPosition: CGFloat?
    private var finished = false

    public var onTap: (() -> Void)?

    public var isEnabled: Bool = true {
        didSet {
            syncState()
        }
    }

    public init() {
        super.init(frame: .zero)

        backgroundColor = .themeSteel20
        cornerRadius = Self.height / 2

        snp.makeConstraints { make in
            make.height.equalTo(Self.height)
        }

        let labelWrapper = UIView()

        addSubview(labelWrapper)
        labelWrapper.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
        }

        labelWrapper.clipsToBounds = true

        labelWrapper.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(CGFloat.margin16)
            make.centerY.equalToSuperview()
        }

        label.textAlignment = .center
        label.font = .headline2

        let finalLabelWrapper = UIView()

        addSubview(finalLabelWrapper)
        finalLabelWrapper.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
        }

        finalLabelWrapper.clipsToBounds = true

        finalLabelWrapper.addSubview(finalLabel)
        finalLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(CGFloat.margin16)
            make.centerY.equalToSuperview()
        }

        finalLabel.textAlignment = .center
        finalLabel.font = .headline2
        finalLabel.textColor = .themeGray

        addSubview(fillView)
        fillView.snp.makeConstraints { make in
            fillInitialConstraint = make.leading.equalToSuperview().constraint
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(finalLabelWrapper.snp.trailing)
        }

        fillView.cornerRadius = Self.height / 2

        addSubview(circleView)
        circleView.snp.makeConstraints { make in
            circleConstraint = make.leading.equalToSuperview().inset(Self.margin).constraint
            make.centerY.equalToSuperview()
            make.size.equalTo(CGFloat.heightButton)
            make.trailing.equalTo(fillView.snp.trailing).inset(Self.margin)
            make.leading.equalTo(labelWrapper.snp.leading).offset(-CGFloat.heightButton / 2)
            fillFinalConstraint = make.leading.equalTo(fillView.snp.leading).offset(Self.margin).constraint
        }

        circleView.cornerRadius = .heightButton / 2
        fillFinalConstraint?.deactivate()

        circleView.addSubview(slideImageView)
        slideImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGFloat.iconSize24)
        }

        circleView.addSubview(finalImageView)
        finalImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGFloat.iconSize24)
        }

        finalImageView.isHidden = true
        finalImageView.transform = CGAffineTransform(scaleX: CGFloat.leastNonzeroMagnitude, y: CGFloat.leastNonzeroMagnitude)

        syncState()

        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onTouch))
        circleView.isUserInteractionEnabled = true
        circleView.addGestureRecognizer(gestureRecognizer)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func syncState() {
        fillView.backgroundColor = isEnabled ? .themeYellowD.withAlphaComponent(0.5) : .themeSteel10
        circleView.backgroundColor = isEnabled ? .themeYellowD : .themeSteel20
        slideImageView.image = slideImageView.image?.withTintColor(isEnabled ? .themeDark : .themeGray50)
        label.textColor = isEnabled ? .themeGray : .themeGray50

        reset()
    }

    private func handleFinish() {
        finished = true

        finalImageView.isHidden = false

        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            options: .curveEaseInOut,
            animations: { [weak self] in
                self?.slideImageView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
                self?.finalImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
                self?.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.slideImageView.isHidden = true
                self?.handleFinish2()
            }
        )
    }

    private func handleFinish2() {
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: .curveEaseInOut,
            animations: { [weak self] in
                self?.fillInitialConstraint?.deactivate()
                self?.fillFinalConstraint?.activate()
                self?.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.onTap?()
            }
        )
    }

    @objc private func onTouch(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard isEnabled, !finished else {
            return
        }

        guard let touchedView = gestureRecognizer.view else {
            return
        }

        if maxPosition == nil {
            maxPosition = frame.width - .heightButton - Self.margin
        }

        guard let maxPosition else {
            return
        }

        let initialPosition = Self.margin

        switch gestureRecognizer.state {
        case .changed:
            let translation = gestureRecognizer.translation(in: touchedView.superview)
            var newPosition = initialPosition + translation.x

            if newPosition < initialPosition {
                newPosition = initialPosition
            } else if newPosition > maxPosition {
                newPosition = maxPosition
            }

            circleConstraint?.update(offset: newPosition)
        case .ended:
            if touchedView.frame.origin.x == maxPosition {
                handleFinish()
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) { [weak self] in
                    self?.circleConstraint?.update(offset: initialPosition)
                    self?.layoutIfNeeded()
                }
            }
        default: ()
        }
    }

    public var title: String? {
        get { label.text }
        set { label.text = newValue }
    }

    public var finalTitle: String? {
        get { finalLabel.text }
        set { finalLabel.text = newValue }
    }

    public var slideImage: UIImage? {
        get { slideImageView.image }
        set {
            slideImageView.image = newValue
            syncState()
        }
    }

    public var finalImage: UIImage? {
        get { finalImageView.image }
        set { finalImageView.image = newValue?.withTintColor(.themeDark) }
    }

    public func reset() {
        finalImageView.transform = CGAffineTransform(scaleX: CGFloat.leastNonzeroMagnitude, y: CGFloat.leastNonzeroMagnitude)
        finalImageView.isHidden = true

        slideImageView.transform = CGAffineTransform(scaleX: 1, y: 1)
        slideImageView.isHidden = false

        fillFinalConstraint?.deactivate()
        fillInitialConstraint?.activate()

        circleConstraint?.update(offset: Self.margin)

        finished = false

        layoutIfNeeded()
    }
}
