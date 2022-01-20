import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import SnapKit
import ComponentKit

class NftCollectionsHeaderView: UITableViewHeaderFooterView {
    private let viewModel: NftCollectionsHeaderViewModel
    private let disposeBag = DisposeBag()

    private let label = UILabel()

    init(viewModel: NftCollectionsHeaderViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        label.font = .headline2
        label.textColor = .themeJacob

        let selector = SelectorButton()

        contentView.addSubview(selector)
        selector.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
            maker.height.equalTo(28)
        }

        selector.set(items: viewModel.priceTypeItems)
        selector.setSelected(index: viewModel.priceTypeIndex)
        selector.onSelect = { [weak self] index in
            self?.viewModel.onSelectPriceType(index: index)
        }

        subscribe(disposeBag, viewModel.amountDriver) { [weak self] in self?.sync(amount: $0) }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(amount: String?) {
        label.text = amount
    }

}
