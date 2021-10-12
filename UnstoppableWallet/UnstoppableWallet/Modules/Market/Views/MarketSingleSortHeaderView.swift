import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit
import RxSwift
import RxCocoa

class MarketSingleSortHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: MarketSingleSortHeaderViewModel
    private let disposeBag = DisposeBag()

    private let sortButton = ThemeButton()

    init(viewModel: MarketSingleSortHeaderViewModel, hasTopSeparator: Bool = true) {
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

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        sortButton.apply(style: .secondaryIcon)
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)

        let marketFieldSelector = SelectorButton()

        contentView.addSubview(marketFieldSelector)
        marketFieldSelector.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        marketFieldSelector.set(items: viewModel.marketFields)
        marketFieldSelector.setSelected(index: viewModel.marketFieldIndex)
        marketFieldSelector.onSelect = { [weak self] index in
            self?.viewModel.onSelectMarketField(index: index)
        }

        subscribe(disposeBag, viewModel.sortDirectionDriver) { [weak self] in self?.syncSortButton(ascending: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapSortButton() {
        viewModel.onToggleSortDirection()
    }

    private func syncSortButton(ascending: Bool) {
        sortButton.setImage(UIImage(named: ascending ? "arrow_medium_2_up_20" : "arrow_medium_2_down_20"), for: .normal)
    }

}
