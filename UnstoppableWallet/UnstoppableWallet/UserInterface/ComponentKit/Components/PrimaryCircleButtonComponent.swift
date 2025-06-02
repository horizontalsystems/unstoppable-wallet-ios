import SnapKit
import UIKit

public class PrimaryCircleButtonComponent: UIView {
    public let button = PrimaryCircleButton()
    private let dummyButton = UIButton()

    public var onTap: (() -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(dummyButton)
        addSubview(button)

        dummyButton.snp.makeConstraints { maker in
            maker.edges.equalTo(button)
        }

        button.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        button.addTarget(self, action: #selector(_onTap), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func _onTap() {
        onTap?()
    }
}
