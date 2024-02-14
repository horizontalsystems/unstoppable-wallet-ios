import ComponentKit
import SnapKit
import ThemeKit
import UIKit

class CoinAnalyticsIssueCell: BaseSelectableThemeCell {
    private let iconView = UIImageView()
    private let blockchainNameLabel = UILabel()
    private let itemsCountLabel = UILabel()

    private let stackView = UIStackView()

    private let highRiskView = IssueView(title: "coin_analytics.analysis.high_risk_items".localized, countColor: .themeLucian)
    private let mediumRiskView = IssueView(title: "coin_analytics.analysis.medium_risk_items".localized, countColor: .themeJacob)
    private let attentionRequiredView = IssueView(title: "coin_analytics.analysis.attention_required".localized, countColor: .themeRemus)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalToSuperview().inset(CGFloat.margin12)
            make.size.equalTo(CGFloat.iconSize32)
        }

        wrapperView.addSubview(blockchainNameLabel)
        blockchainNameLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(CGFloat.margin16)
            make.centerY.equalTo(iconView)
        }

        blockchainNameLabel.font = .body
        blockchainNameLabel.textColor = .themeLeah

        wrapperView.addSubview(itemsCountLabel)
        itemsCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(blockchainNameLabel.snp.trailing).offset(CGFloat.margin16)
            make.centerY.equalTo(iconView)
        }

        itemsCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        itemsCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        itemsCountLabel.font = .subhead1
        itemsCountLabel.textColor = .themeLeah

        let arrowImageView = UIImageView()

        wrapperView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { make in
            make.leading.equalTo(itemsCountLabel.snp.trailing).offset(CGFloat.margin8)
            make.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.centerY.equalTo(iconView)
            make.size.equalTo(CGFloat.iconSize20)
        }

        arrowImageView.image = UIImage(named: "arrow_big_forward_20")?.withTintColor(.themeGray)

        wrapperView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            make.top.equalTo(iconView.snp.bottom).offset(CGFloat.margin12)
        }

        stackView.axis = .vertical

        stackView.addArrangedSubview(highRiskView)
        stackView.addArrangedSubview(mediumRiskView)
        stackView.addArrangedSubview(attentionRequiredView)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: CoinAnalyticsViewModel.IssueBlockchainViewItem) {
        iconView.setImage(withUrlString: viewItem.blockchain.type.imageUrl, placeholder: UIImage(named: "placeholder_rectangle_32"))
        blockchainNameLabel.text = viewItem.blockchain.name
        itemsCountLabel.text = "\(viewItem.allItems.count)"

        highRiskView.isHidden = viewItem.highRiskCount == 0
        highRiskView.bind(count: viewItem.highRiskCount)

        mediumRiskView.isHidden = viewItem.mediumRiskCount == 0
        mediumRiskView.bind(count: viewItem.mediumRiskCount)

        attentionRequiredView.isHidden = viewItem.lowRiskCount == 0
        attentionRequiredView.bind(count: viewItem.lowRiskCount)
    }
}

extension CoinAnalyticsIssueCell {
    static func height(viewItem: CoinAnalyticsViewModel.IssueBlockchainViewItem) -> CGFloat {
        var issuesHeight: CGFloat = 0

        if viewItem.highRiskCount != 0 {
            issuesHeight += 25
        }

        if viewItem.mediumRiskCount != 0 {
            issuesHeight += 25
        }

        if viewItem.lowRiskCount != 0 {
            issuesHeight += 25
        }

        return .heightCell56 + issuesHeight + (issuesHeight == 0 ? 0 : .margin12)
    }
}

extension CoinAnalyticsIssueCell {
    class IssueView: UIView {
        private let countLabel = UILabel()

        init(title: String, countColor: UIColor) {
            super.init(frame: .zero)

            snp.makeConstraints { make in
                make.height.equalTo(25)
            }

            let titleLabel = UILabel()

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.leading.equalToSuperview()
                make.centerY.equalToSuperview()
            }

            titleLabel.font = .subhead2
            titleLabel.textColor = .themeGray
            titleLabel.text = title

            addSubview(countLabel)
            countLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview()
                make.centerY.equalToSuperview()
            }

            countLabel.font = .subhead1
            countLabel.textColor = countColor
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func bind(count: Int) {
            countLabel.text = "\(count)"
        }
    }
}
