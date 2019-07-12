import UIKit
import UIExtensions
import SnapKit

class RespondButton: UIView, RespondViewDelegate {
    typealias Style = Dictionary<State, UIColor?>

    enum State {
        case disabled, selected, active
    }

    var touchTransparent: Bool { return false }

    private let view = RespondView()
    private let wrapperView = UIView()

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
    public var textColors = Style(){
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
            maker.trailing.lessThanOrEqualToSuperview().offset(-ButtonTheme.margin)
            maker.leading.greaterThanOrEqualToSuperview().offset(ButtonTheme.margin)
        }
        wrapperView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        titleLabel.textAlignment = .center
        titleLabel.font = ButtonTheme.font
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
        self.state = state == .disabled ? .disabled : .selected
        updateUI()
    }

    func touchEnd() {
        self.state = state == .disabled ? .disabled : .active
        updateUI()
    }

    private func updateUI() {
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
                maker.leading.equalTo(imageView.snp.trailing).offset(ButtonTheme.insideMargin)
                maker.top.bottom.equalToSuperview()
                maker.trailing.equalToSuperview()
            }
        } else {
            titleLabel.snp.remakeConstraints { maker in
                maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: ButtonTheme.margin, bottom: 0, right: ButtonTheme.margin))
            }
            imageView.removeFromSuperview()
        }
        layoutIfNeeded()
    }

}
