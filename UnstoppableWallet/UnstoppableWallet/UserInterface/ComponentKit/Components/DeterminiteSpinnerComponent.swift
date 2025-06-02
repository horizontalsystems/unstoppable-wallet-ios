import HUD
import SnapKit
import UIKit

public class DeterminiteSpinnerComponent: UIView {
    private let spinner: HUDProgressView

    init(size: CGFloat) {
        spinner = HUDProgressView(
            progress: 0,
            strokeLineWidth: 2,
            radius: (size - 2) / 2,
            strokeColor: .themeGray,
            donutColor: .themeSteel10,
            duration: 2
        )

        super.init(frame: .zero)

        addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.size.equalTo(size)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(progress: Double) {
        spinner.set(progress: Float(progress))
        spinner.startAnimating()
    }
}
