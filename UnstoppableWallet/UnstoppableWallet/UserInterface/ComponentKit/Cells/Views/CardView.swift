import SnapKit
import UIKit

open class CardView: UIView {
    private let roundedBackground = UIView()
    private let clippingView = UIView()
    public let contentView = UIView()

    public init(insets: UIEdgeInsets) {
        super.init(frame: .zero)

        addSubview(roundedBackground)
        roundedBackground.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        roundedBackground.backgroundColor = .themeLawrence
        roundedBackground.layer.cornerRadius = .cornerRadius16
        roundedBackground.layer.cornerCurve = .continuous

        addSubview(clippingView)
        clippingView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        clippingView.backgroundColor = .clear
        clippingView.clipsToBounds = true
        clippingView.layer.cornerRadius = .cornerRadius16
        clippingView.layer.cornerCurve = .continuous

        clippingView.addSubview(contentView)
        contentView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(insets)
        }

        contentView.backgroundColor = .clear

        updateUI()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateUI()
    }

    private func updateUI() {
        roundedBackground.layer.shadowColor = UIColor.themeAndy.cgColor
    }
}
