import HUD
import SnapKit
import UIKit

public class SpinnerComponent: UIView {
    private let spinner: HUDActivityView

    init(style: ActivityIndicatorStyle) {
        spinner = HUDActivityView.create(with: style)

        super.init(frame: .zero)

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        spinner.startAnimating()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
