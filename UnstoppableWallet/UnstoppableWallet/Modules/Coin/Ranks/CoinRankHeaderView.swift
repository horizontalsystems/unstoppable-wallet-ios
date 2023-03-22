import UIKit
import UIExtensions
import ThemeKit
import SnapKit
import ComponentKit
import RxSwift
import RxCocoa

class CoinRankHeaderView: UITableViewHeaderFooterView {
    static let height: CGFloat = .heightSingleLineCell

    private let viewModel: CoinRankViewModel
    private let disposeBag = DisposeBag()

    private let sortButton = SecondaryCircleButton()

    init(viewModel: CoinRankViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        contentView.addSubview(sortButton)
        sortButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        sortButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sortButton.addTarget(self, action: #selector(onTapSortButton), for: .touchUpInside)

        if let selectorItems = viewModel.selectorItems {
            let selector = SelectorButton()

            contentView.addSubview(selector)
            selector.snp.makeConstraints { maker in
                maker.trailing.equalToSuperview().inset(CGFloat.margin16)
                maker.centerY.equalToSuperview()
                maker.height.equalTo(28)
            }

            selector.set(items: selectorItems)
            selector.setSelected(index: viewModel.selectorIndex)
            selector.onSelect = { [weak self] index in
                self?.viewModel.onSelectSelector(index: index)
            }
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
        sortButton.set(image: UIImage(named: ascending ? "arrow_medium_2_up_20" : "arrow_medium_2_down_20"))
    }

}
