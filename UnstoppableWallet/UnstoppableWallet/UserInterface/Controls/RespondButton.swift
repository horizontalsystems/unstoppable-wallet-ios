import UIKit
import UIExtensions
import SnapKit

class RespondButton: UIView, RespondViewDelegate {
    typealias Style = Dictionary<State, UIColor?>

    enum State {
        case disabled, selected, active
    }

    var touchTransparent: Bool { false }
    var changeBackground: Bool = true

    private let view = RespondView()
    public let wrapperView = UIView()

    public let titleLabel = UILabel()
    public let imageView = UIImageView()

    public var image: UIImage? {
        didSet {
            updateContent()
        }
    }

    var state = State.active {
        didSet {
            updateUI()
        }
    }

    public var backgrounds = Style() {
        didSet {
            updateUI()
        }
    }
    public var textColors = Style() {
        didSet {
            updateUI()
        }
    }

    public var onTap: (() -> ())?

    init(onTap: (() -> ())? = nil) {
        super.init(frame: .zero)
        backgroundColor = .clear

        view.delegate = self
        self.onTap = onTap
        view.handleTouch = {
            if self.state != .disabled {
                self.onTap?()
            }
        }
        addSubview(view)
        view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.trailing.lessThanOrEqualToSuperview().offset(-CGFloat.margin4x)
            maker.leading.greaterThanOrEqualToSuperview().offset(CGFloat.margin4x)
        }
        wrapperView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        imageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.textAlignment = .center
        titleLabel.font = .headline2
        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    public func set(backgroundColor: UIColor, for state: State) {
        backgrounds[state] = backgroundColor
        updateUI()
    }

    public func set(textColor: UIColor, for state: State) {
        backgrounds[state] = backgroundColor
    }

    func touchBegan() {
        if changeBackground {
            self.state = state == .disabled ? .disabled : .selected
        }
        updateUI()
    }

    func touchEnd() {
        if changeBackground {
            self.state = state == .disabled ? .disabled : .active
        }
        updateUI()
    }

    public func updateUI() {
        titleLabel.textColor = textColors[state] ?? .black
        view.backgroundColor = backgrounds[state] ?? .clear
    }

    private func updateContent() {
        imageView.image = image
        if image != nil {
            wrapperView.addSubview(imageView)
            imageView.snp.makeConstraints { maker in
                maker.leading.equalToSuperview()
                maker.centerY.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { maker in
                maker.leading.equalTo(imageView.snp.trailing).offset(6)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalToSuperview()
            }
        } else {
            titleLabel.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview()
            }
            imageView.removeFromSuperview()
        }
        layoutIfNeeded()
    }

}
