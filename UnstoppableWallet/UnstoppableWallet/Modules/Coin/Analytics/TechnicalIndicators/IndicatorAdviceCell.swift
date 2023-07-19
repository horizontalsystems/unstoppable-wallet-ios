import UIKit
import SnapKit
import ComponentKit
import ThemeKit
import HUD

class IndicatorAdviceCell: BaseThemeCell {
    static let height: CGFloat = 229

    private let headerWrapperView = UIView()
    private let nameLabel = UILabel()
    private let infoButton = SecondaryCircleButton()

    private var adviceViews = [IndicatorAdviceView]()
    private let spinner = HUDActivityView.create(with: .medium24)

    var onTapInfo: (() -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.backgroundColor = .clear
        backgroundColor = .clear

        wrapperView.addSubview(headerWrapperView)
        headerWrapperView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        headerWrapperView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin12)
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(9)
        }

        nameLabel.font = .subhead1
        nameLabel.textColor = .gray
        nameLabel.text = "coin_analytics.indicators.title".localized

        headerWrapperView.addSubview(infoButton)
        infoButton.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel.snp.trailing).offset(CGFloat.margin12)
            make.top.equalToSuperview().inset(CGFloat.margin12)
            make.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        infoButton.set(image: UIImage(named: "circle_information_20"), style: .transparent)
        infoButton.addTarget(self, action: #selector(onTapInfoButton), for: .touchUpInside)

        var lastView: UIView = headerWrapperView
        for _ in 0..<3 {
            let view = IndicatorAdviceView()
            adviceViews.append(view)

            wrapperView.addSubview(view)
            view.snp.makeConstraints { maker in
                maker.top.equalTo(lastView.snp.bottom).offset(CGFloat.margin24)
                maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            }

            lastView = view
        }

        wrapperView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.set(hidden: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapInfoButton() {
        onTapInfo?()
    }

}

extension IndicatorAdviceCell {

    func set(loading: Bool) {
        adviceViews.forEach { $0.isHidden = loading }
        spinner.isHidden = !loading
        if loading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    func setEmpty(value: String) {
        CoinIndicatorViewItemFactory.sectionNames.enumerated().forEach { index, element in
            guard let view = adviceViews.at(index: index) else {
                return
            }

            view.title = element
            view.setEmpty(title: element, value: value)
        }
    }

    func set(viewItems: [CoinIndicatorViewItemFactory.ViewItem]) {
        viewItems.enumerated().forEach { index, element in
            guard let view = adviceViews.at(index: index) else {
                return
            }

            view.title = element.name
            view.set(advice: element.advice)
        }
    }

}
