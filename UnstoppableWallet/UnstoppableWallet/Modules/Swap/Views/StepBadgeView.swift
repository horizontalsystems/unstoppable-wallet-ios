import SnapKit
import UIKit

class StepBadgeView: UIView {
    private let label = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        label.textAlignment = .center
        label.font = .captionSB

        clipsToBounds = true
        layer.cornerRadius = .cornerRadius12
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(active: Bool) {
        backgroundColor = active ? .themeBran : .themeSteel20
        label.textColor = active ? .themeClaude : .themeGray
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }
}
