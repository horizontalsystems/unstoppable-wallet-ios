import UIKit
import SnapKit

class TitledHighlightedDescriptionView: HighlightedDescriptionBaseView {
    private let titleIconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton()
    private let backgroundButton = UIButton()

    var onTapClose: (() -> ())?
    var onTapBackground: (() -> ())?

    override public init() {
        super.init()

        addSubview(backgroundButton)
        backgroundButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        backgroundButton.addTarget(self, action: #selector(onBackgroundTap), for: .touchUpInside)

        addSubview(titleIconImageView)
        titleIconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(HighlightedDescriptionBaseView.sidePadding)
            maker.top.equalToSuperview().inset(HighlightedDescriptionBaseView.verticalPadding)
            maker.size.equalTo(CGFloat.iconSize20)
        }

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(titleIconImageView.snp.trailing).offset(HighlightedDescriptionBaseView.verticalPadding)
            maker.centerY.equalTo(titleIconImageView)
        }

        titleLabel.font = .subhead1
        titleLabel.textColor = .themeYellowD

        addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalTo(titleLabel.snp.trailing).offset(HighlightedDescriptionBaseView.verticalPadding)
            maker.trailing.equalToSuperview().inset(HighlightedDescriptionBaseView.sidePadding)
            maker.top.bottom.size.equalTo(titleIconImageView)
        }

        closeButton.addTarget(self, action: #selector(onCloseTap), for: .touchUpInside)
        closeButton.setImage(UIImage(named: "close_1_20")?.withTintColor(.themeJacob), for: .normal)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        closeButton.isHidden = true

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(HighlightedDescriptionBaseView.sidePadding)
            maker.top.equalTo(titleIconImageView.snp.bottom).offset(HighlightedDescriptionBaseView.verticalPadding)
            maker.bottom.equalToSuperview().inset(HighlightedDescriptionBaseView.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = HighlightedDescriptionBaseView.font
        label.textColor = .themeLeah
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onBackgroundTap() {
        onTapBackground?()
    }

    @objc private func onCloseTap() {
        onTapClose?()
    }

    var titleIcon: UIImage? {
        get { titleIconImageView.image }
        set { titleIconImageView.image = newValue }
    }

    var title: String? {
        get { titleLabel.text }
        set { titleLabel.text = newValue }
    }

    var titleColor: UIColor? {
        get { titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

    var closeButtonHidden: Bool {
        get { closeButton.isHidden }
        set { closeButton.isHidden = newValue }
    }
}

extension TitledHighlightedDescriptionView {

    @objc public class func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return verticalPadding + .iconSize20 + textHeight + 2 * verticalPadding
    }

}
