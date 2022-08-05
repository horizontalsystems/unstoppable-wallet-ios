import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit
import RxSwift
import RxCocoa

class MarketTvlSortHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: MarketTvlSortHeaderViewModel
    private let disposeBag = DisposeBag()

    weak var viewController: UIViewController?

    private let dropdownButton = SecondaryButton()
    private let sortButton = SecondaryCircleButton()
    private let marketTvlFieldButton = SecondaryCircleButton()

    init(viewModel: MarketTvlSortHeaderViewModel, hasTopSeparator: Bool = true) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        if hasTopSeparator {
            let separatorView = UIView()
            contentView.addSubview(separatorView)
            separatorView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalToSuperview()
                maker.height.equalTo(CGFloat.heightOnePixel)
            }

            separatorView.backgroundColor = .themeSteel20
        }

        contentView.addSubview(dropdownButton)
        dropdownButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        dropdownButton.set(style: .transparent)
        dropdownButton.set(image: UIImage(named: "arrow_small_down_20"))
        dropdownButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dropdownButton.addTarget(self, action: #selector(onTapDropdownButton), for: .touchUpInside)

        marketTvlFieldButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        marketTvlFieldButton.addTarget(self, action: #selector(onTapMarketTvlFieldButton), for: .touchUpInside)

        contentView.addSubview(marketTvlFieldButton)
        marketTvlFieldButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(marketTvlFieldButton.snp.leading).offset(-CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.platformFieldDriver) { [weak self] in self?.syncDropdownButton(title: $0) }
        subscribe(disposeBag, viewModel.sortDirectionDriver) { [weak self] in self?.syncSortButton(ascending: $0) }
        subscribe(disposeBag, viewModel.marketTvlFieldDriver) { [weak self] in self?.syncMarketTvlFieldButton(marketTvlField: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapDropdownButton() {
        let alertController = AlertRouter.module(
                title: "coin_page.tvl_rank.filter_by_chain".localized,
                viewItems: viewModel.platformFieldViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectMarketPlatformField(index: index)
        }

        viewController?.present(alertController, animated: true)
    }

    @objc private func onTapSortButton() {
        viewModel.onToggleSortDirection()
    }

    private func syncMarketTvlFieldButton(marketTvlField: MarketModule.MarketTvlField) {
        let imageName: String
        switch marketTvlField {
        case .value: imageName = "usd_20"
        case .diff: imageName = "percent_20"
        }

        marketTvlFieldButton.set(image: UIImage(named: imageName))
    }

    @objc private func onTapMarketTvlFieldButton() {
        viewModel.onToggleMarketTvlField()
    }

    private func syncDropdownButton(title: String) {
        dropdownButton.setTitle(title, for: .normal)
    }

    private func syncSortButton(ascending: Bool) {
        sortButton.set(image: UIImage(named: ascending ? "arrow_medium_2_up_20" : "arrow_medium_2_down_20"))
    }

}
