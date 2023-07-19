import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class ManageBarButtonView: UIView {
    private let button = UIButton()
    private let badgeView = UIView()

    var onTap: (() -> ())?

    init() {
        super.init(frame: .zero)

        addSubview(badgeView)
        badgeView.snp.makeConstraints { maker in
            maker.trailing.top.equalToSuperview().inset(-CGFloat.margin4)
            maker.size.equalTo(CGFloat.margin8)
        }

        badgeView.backgroundColor = .themeLucian
        badgeView.cornerRadius = .cornerRadius4
        badgeView.isHidden = true

        addSubview(button)
        button.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        button.setImage(UIImage(named: "manage_2_24")?.withTintColor(.themeJacob), for: .normal)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTap?()
    }

}

extension ManageBarButtonView {

    var isBadgeHidden: Bool {
        get {
            badgeView.isHidden
        }
        set {
            badgeView.isHidden = newValue
        }
    }

}
