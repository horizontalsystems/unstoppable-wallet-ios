import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import SnapKit
import ComponentKit
import HUD

class NftHeaderView: UITableViewHeaderFooterView {
    static var height: CGFloat = HeaderAmountView.height + .heightCell48

    private let viewModel: NftHeaderViewModel
    private let disposeBag = DisposeBag()

    private let amountView = HeaderAmountView()

    init(viewModel: NftHeaderViewModel) {
        self.viewModel = viewModel

        super.init(reuseIdentifier: nil)

        backgroundView = UIView()
        backgroundView?.backgroundColor = .themeNavigationBarBackground

        contentView.addSubview(amountView)
        amountView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        amountView.onTapAmount = { [weak self] in
            self?.viewModel.onTapTotalAmount()
        }
        amountView.onTapConvertedAmount = { [weak self] in
            self?.viewModel.onTapConvertedTotalAmount()
        }

        let separatorView = UIView()

        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        let selectorWrapperView = UIView()

        contentView.addSubview(selectorWrapperView)
        selectorWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountView.snp.bottom)
            maker.height.equalTo(CGFloat.heightCell48)
        }

        let titleText = TextComponent()

        selectorWrapperView.addSubview(titleText)
        titleText.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        titleText.font = .subhead1
        titleText.textColor = .themeGray
        titleText.text = "nft_collections.price_mode".localized

        let selector = SelectorButton()

        selectorWrapperView.addSubview(selector)
        selector.snp.makeConstraints { maker in
            maker.leading.equalTo(titleText.snp.trailing).offset(CGFloat.margin16)
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        selector.set(items: viewModel.priceTypeItems)
        selector.setSelected(index: viewModel.priceTypeIndex)
        selector.onSelect = { [weak self] index in
            self?.viewModel.onSelectPriceType(index: index)
        }

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.playHapticSignal) { [weak self] in self?.playHaptic() }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sync(viewItem: NftHeaderViewModel.ViewItem?) {
        guard let viewItem = viewItem else {
            return
        }

        amountView.set(amountText: viewItem.amount, expired: viewItem.amountExpired)
        amountView.set(convertedAmountText: viewItem.convertedValue, expired: viewItem.convertedValueExpired)
    }

    private func playHaptic() {
        HapticGenerator.instance.notification(.feedback(.soft))
    }

}
