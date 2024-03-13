import ComponentKit
import UIKit

class TechnicalIndicatorCell: BaseThemeCell {
    static let detailsFont = UIFont.body
    private let titleLabel = UILabel()
    private let titleInfoButton = SecondaryCircleButton()
    private let adviceLabel = UILabel()
    private let detailsLabel = UILabel()
    private let disclaimerLabel = UILabel()
    private let sliderView = TechnicalIndicatorSliderView()
    private let button = PrimaryButton()

    var onTapDetails: (() -> Void)?
    var onTapInfo: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview().offset(CGFloat.margin16)
        }

        titleLabel.font = .subhead1
        titleLabel.textColor = .themeGray
        titleLabel.text = "coin_analytics.indicators.title".localized

        wrapperView.addSubview(titleInfoButton)
        titleInfoButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(CGFloat.margin16)
            make.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview().offset(CGFloat.margin12)
        }

        titleInfoButton.set(image: UIImage(named: "circle_information_20"), style: .transparent)
        titleInfoButton.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)

        wrapperView.addSubview(adviceLabel)
        adviceLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin12)
        }

        adviceLabel.font = .headline1
        adviceLabel.textColor = .themeBran

        wrapperView.addSubview(sliderView)
        sliderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(adviceLabel.snp.bottom).offset(CGFloat.margin12)
        }

        wrapperView.addSubview(detailsLabel)
        detailsLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(sliderView.snp.bottom).offset(CGFloat.margin12)
            make.height.equalTo(CGFloat.zero)
        }

        detailsLabel.font = Self.detailsFont
        detailsLabel.textColor = .themeLeah
        detailsLabel.numberOfLines = 0

        wrapperView.addSubview(disclaimerLabel)
        disclaimerLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(detailsLabel.snp.bottom) // need to change offset when shows details
        }

        disclaimerLabel.font = .caption
        disclaimerLabel.textColor = .themeGray
        disclaimerLabel.numberOfLines = 0
        disclaimerLabel.text = "coin_analytics.indicators.disclaimer".localized

        wrapperView.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(disclaimerLabel.snp.bottom).offset(12)
        }

        button.set(style: .transparent)
        button.addTarget(self, action: #selector(onTapButton), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapButton() {
        onTapDetails?()
    }

    @objc private func onTapInfoButton() {
        onTapInfo?()
    }

    func bind(viewItem: CoinAnalyticsViewModel.TechnicalAdviceViewItem) {
        adviceLabel.text = viewItem.title
        sliderView.bind(index: viewItem.sliderIndex)
        detailsLabel.text = viewItem.details

        let detailsHeight = viewItem.details.height(forContainerWidth: detailsLabel.width, font: Self.detailsFont)
        detailsLabel.snp.updateConstraints { make in
            make.height.equalTo(viewItem.detailsShowed ? detailsHeight : CGFloat.zero)
        }

        disclaimerLabel.snp.updateConstraints { make in
            make.top.equalTo(detailsLabel.snp.bottom).offset(viewItem.detailsShowed ? CGFloat.margin12 : .zero)
        }

        button.setTitle(viewItem.detailsShowed ? "coin_analytics.indicators.hide_details".localized : "coin_analytics.indicators.show_details".localized, for: .normal)
    }
}

extension TechnicalIndicatorCell {
    static func height(width: CGFloat, backgroundStyle: BackgroundStyle = .lawrence, viewItem: CoinAnalyticsViewModel.TechnicalAdviceViewItem) -> CGFloat {
        let width = width - 2 * .margin16 - BaseThemeCell.margin(backgroundStyle: backgroundStyle).width

        let top = .margin16 +
            UIFont.subhead1.lineHeight +
            .margin12 +
            UIFont.headline1.lineHeight +
            .margin12 +
            TechnicalIndicatorSliderView.height +
            .margin12
        var details: CGFloat = 0
        if viewItem.detailsShowed {
            details += viewItem.details.height(forContainerWidth: width, font: Self.detailsFont)
            details += .margin12
        }

        let bottom = "coin_analytics.indicators.disclaimer".localized.height(forContainerWidth: width, font: .caption) +
            .margin12 +
            .heightButton

        return top + details + bottom
    }
}
