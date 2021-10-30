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

    private let sortButton = ThemeButton()

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

        let marketTvlFieldSelector = SelectorButton()

        contentView.addSubview(marketTvlFieldSelector)
        marketTvlFieldSelector.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        marketTvlFieldSelector.set(items: viewModel.marketTvlFields)
        marketTvlFieldSelector.setSelected(index: viewModel.marketTvlFieldIndex)
        marketTvlFieldSelector.onSelect = { [weak self] index in
            self?.viewModel.onSelectMarketTvlField(index: index)
        }

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.trailing.equalTo(marketTvlFieldSelector.snp.leading).offset(-CGFloat.margin8)
            maker.centerY.equalToSuperview()
        }

        sortButton.apply(style: .secondaryIcon)
        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)

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
