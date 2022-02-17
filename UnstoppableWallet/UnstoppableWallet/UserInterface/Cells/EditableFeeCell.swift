import UIKit
import RxSwift
import RxCocoa
import ComponentKit
import ThemeKit

class EditableFeeCell: BaseSelectableThemeCell {
    private let disposeBag = DisposeBag()

    init(viewModel: EvmFeeViewModel) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        clipsToBounds = true
        set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        CellBuilder.build(cell: self, elements: [.text, .text, .margin8, .image20, .spinner20])

        bind(index: 0) { (component: TextComponent) in
            component.set(style: .d1)
            component.text = "send.fee".localized
        }

        bind(index: 2) { (component: ImageComponent) in
            component.imageView.image =  UIImage(named: "edit2_20")?.withRenderingMode(.alwaysTemplate)
        }

        subscribe(disposeBag, viewModel.valueDriver) { [weak self] value in
            self?.bind(index: 1) { (component: TextComponent) in
                if let value = value {
                    component.isHidden = false
                    component.set(style: value.type.style)
                    component.text = value.text
                } else {
                    component.isHidden = true
                }
            }
        }

        subscribe(disposeBag, viewModel.editButtonVisibleDriver) { [weak self] visible in
            self?.bind(index: 2) { (component: ImageComponent) in
                component.isHidden = !visible
            }
        }

        subscribe(disposeBag, viewModel.editButtonHighlightedDriver) { [weak self] highlighted in
            self?.bind(index: 2) { (component: ImageComponent) in
                component.imageView.tintColor = highlighted ? .themeJacob : .themeGray
            }
        }

        subscribe(disposeBag, viewModel.spinnerVisibleDriver) { [weak self] visible in
            self?.bind(index: 3) { (component: SpinnerComponent) in
                component.isHidden = !visible
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
