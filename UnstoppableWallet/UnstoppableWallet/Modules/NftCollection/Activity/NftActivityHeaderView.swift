import UIKit
import SnapKit
import RxSwift
import UIExtensions
import ThemeKit
import ComponentKit

class NftActivityHeaderView: UIView {
    private let viewModel: NftActivityViewModel
    private let disposeBag = DisposeBag()

    weak var viewController: UIViewController?

    private let eventTypeButton = SecondaryButton()
    private let contractButton = SecondaryButton()

    init(viewModel: NftActivityViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)

        backgroundColor = .themeNavigationBarBackground

        addSubview(eventTypeButton)
        eventTypeButton.snp.makeConstraints { maker in
            maker.leading.centerY.equalToSuperview()
        }

        eventTypeButton.set(style: .transparent, image: UIImage(named: "arrow_small_down_20"))
        eventTypeButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        eventTypeButton.addTarget(self, action: #selector(onTapEventType), for: .touchUpInside)

        addSubview(contractButton)
        contractButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.centerY.equalToSuperview()
        }

        contractButton.set(style: .default, image: UIImage(named: "arrow_small_down_20"))
        contractButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contractButton.addTarget(self, action: #selector(onTapContract), for: .touchUpInside)

        subscribe(disposeBag, viewModel.eventTypeDriver) { [weak self] eventType in
            self?.eventTypeButton.setTitle(eventType, for: .normal)
        }
        subscribe(disposeBag, viewModel.contractDriver) { [weak self] contract in
            self?.contractButton.isHidden = contract == nil
            self?.contractButton.setTitle(contract, for: .normal)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapEventType() {
        let alertController = AlertRouter.module(
                title: "nft.activity.event_types".localized,
                viewItems: viewModel.eventTypeViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectEventType(index: index)
        }

        viewController?.present(alertController, animated: true)
    }

    @objc private func onTapContract() {
        let viewController = SelectorModule.bottomSingleSelectorViewController(
                image: .local(image: UIImage(named: "paper_contract_24")?.withTintColor(.themeJacob)),
                title: "nft.activity.contracts".localized,
                viewItems: viewModel.contractViewItems,
                onSelect: { [weak self] index in
                    self?.viewModel.onSelectContract(index: index)
                }
        )

        self.viewController?.present(viewController, animated: true)
    }

}
