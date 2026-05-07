import SnapKit
import UIKit

public class StackComponent: UIView {
    let stackView = UIStackView()

    init(centered: Bool) {
        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            if centered {
                maker.leading.trailing.equalToSuperview()
                maker.centerY.equalToSuperview()
            } else {
                maker.edges.equalToSuperview()
            }
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
