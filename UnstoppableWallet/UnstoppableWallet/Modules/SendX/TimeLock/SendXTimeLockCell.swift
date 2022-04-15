import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

class SendXTimeLockCell: BaseThemeCell {
    private let disposeBag = DisposeBag()
    private let viewModel: SendXTimeLockViewModel

    weak var sourceViewController: UIViewController?

    init(viewModel: SendXTimeLockViewModel) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true

        CellBuilder.build(cell: self, elements: [.text, .secondaryButton])

        bind(index: 0) { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "send.hodler_locktime".localized
        }

        subscribe(disposeBag, viewModel.lockTimeDriver) { [weak self] priority in
            self?.bind(index: 1) { (component: SecondaryButtonComponent) in
                component.button.set(style: .transparent)
                component.button.set(image: UIImage(named: "arrow_small_down_20"))
                component.button.setTitle(priority, for: .normal)
                component.onTap = { [weak self] in
                    self?.onTapLockTimeSelect()
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func onTapLockTimeSelect() {
        let alertController = AlertRouter.module(
                title: "send.hodler_locktime".localized,
                viewItems: viewModel.lockTimeViewItems
        ) { [weak self] index in
            self?.viewModel.onSelect(index)
        }

        sourceViewController?.present(alertController, animated: true)
    }

}
