import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

struct FeeSliderViewItem {
    let initialValue: Int
    let range: ClosedRange<Int>
}

protocol IDynamicHeightCellDelegate: AnyObject {
    func onChangeHeight()
}

class FeeSliderCell: BaseThemeCell {
    private let feeSliderWrapper = FeeSliderWrapper()

    private let disposeBag = DisposeBag()

    var onFinishTracking: ((Int) -> ())?

    init(sliderDriver: Driver<FeeSliderViewItem?>) {
        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = true

        wrapperView.addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.onFinishTracking?(value)
        }

        subscribe(disposeBag, sliderDriver) { [weak self] viewItem in
                    if let viewItem = viewItem {
                        self?.feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range, description: "gwei")
                        self?.feeSliderWrapper.isHidden = false
                    } else {
                        self?.feeSliderWrapper.isHidden = true
                    }
                }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
