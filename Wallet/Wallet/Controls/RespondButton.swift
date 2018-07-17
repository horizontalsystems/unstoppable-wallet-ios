import UIKit
import GrouviExtensions
import SnapKit

class RespondButton: UIView, RespondViewDelegate {
    typealias Style = Dictionary<State, UIColor?>

    enum State {
        case disabled, selected, active
    }

    var touchTransparent: Bool { return false }

    private let view = RespondView()
    public let titleLabel = UILabel()

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

    public var onTap: (() -> ())? {
        didSet {
            view.handleTouch = onTap
        }
    }

    init(onTap: (() -> ())? = nil) {
        super.init(frame: .zero)
        backgroundColor = .clear

        view.delegate = self
        self.onTap = onTap
        view.handleTouch = onTap
        addSubview(view)
        view.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        titleLabel.textAlignment = .center
        titleLabel.font = ButtonTheme.font
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: ButtonTheme.margin, left: ButtonTheme.margin, bottom: ButtonTheme.margin, right: ButtonTheme.margin))
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
        view.backgroundColor = backgrounds[state] ?? .white
    }

}
