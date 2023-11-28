import ComponentKit
import HUD
import ThemeKit
import UIKit

class BalanceCoinIconHolder: UIView {
    private let coinIconImageView = UIImageView()
    private let syncSpinner = HUDProgressView(
        progress: 0,
        strokeLineWidth: 2,
        radius: 19,
        strokeColor: .themeGray,
        duration: 2
    )
    private let failedButton = UIButton()

    private var onTapError: (() -> Void)?

    init() {
        super.init(frame: .zero)

        addSubview(coinIconImageView)
        coinIconImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize32)
        }

        addSubview(syncSpinner)
        syncSpinner.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        addSubview(failedButton)
        failedButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        failedButton.setImage(UIImage(named: "warning_2_24")?.withTintColor(.themeLucian), for: .normal)
        failedButton.addTarget(self, action: #selector(onTapErrorButton), for: .touchUpInside)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("not implemented")
    }

    @objc private func onTapErrorButton() {
        onTapError?()
    }

    func bind(iconUrlString: String?, placeholderIconName: String, spinnerProgress: Int?, indefiniteSearchCircle: Bool, failViewVisible: Bool, onTapError: (() -> Void)?) {
        self.onTapError = onTapError

        coinIconImageView.isHidden = iconUrlString == nil
        if let iconUrlString {
            coinIconImageView.setImage(withUrlString: iconUrlString, placeholder: UIImage(named: placeholderIconName))
        } else {
            coinIconImageView.image = nil
        }

        if let spinnerProgress {
            syncSpinner.set(progress: Float(spinnerProgress) / 100)
            syncSpinner.set(strokeColor: .themeGray)
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else if indefiniteSearchCircle {
            syncSpinner.set(strokeColor: .themeGray50)
            syncSpinner.set(progress: 0.1)
            syncSpinner.isHidden = false
            syncSpinner.startAnimating()
        } else {
            syncSpinner.isHidden = true
            syncSpinner.stopAnimating()
        }

        failedButton.isHidden = !failViewVisible
    }
}
