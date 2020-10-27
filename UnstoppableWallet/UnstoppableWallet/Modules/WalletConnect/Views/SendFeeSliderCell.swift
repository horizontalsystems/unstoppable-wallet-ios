import UIKit
import SnapKit
import UIExtensions
import HUD
import RxSwift
import RxCocoa

struct SendFeeSliderViewItem {
    let initialValue: Int
    let range: ClosedRange<Int>
    let unit: String
}

protocol ISendFeeSliderViewModel {
    func changeCustomPriority(value: Int)
}

class SendFeeSliderCell: UITableViewCell {
    private let viewModel: ISendFeeSliderViewModel

    private let feeSliderWrapper = FeeSliderWrapper()
    private let feeRateView = FeeSliderValueView()

    private let disposeBag = DisposeBag()

    init(viewModel: ISendFeeSliderViewModel, viewItem: SendFeeSliderViewItem) {
        self.viewModel = viewModel

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        feeSliderWrapper.onTracking = { [weak self] value, position in
            self?.onTracking(value, position: position)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.finishTracking(value: value)
        }

        feeSliderWrapper.set(value: viewItem.initialValue, range: viewItem.range)
        feeRateView.set(descriptionText: viewItem.unit)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func hudConfig(position: CGPoint) -> HUDConfig {
        var feeConfig = HUDConfig()

        feeConfig.appearStyle = .alphaAppear
        feeConfig.style = .banner(.top)
        feeConfig.absoluteInsetsValue = true
        feeConfig.userInteractionEnabled = true
        feeConfig.hapticType = .none
        feeConfig.blurEffectStyle = nil
        feeConfig.blurEffectIntensity = nil
        feeConfig.borderColor = .themeSteel20
        feeConfig.borderWidth = .heightOnePixel
        feeConfig.exactSize = true
        feeConfig.preferredSize = CGSize(width: 74, height: 48)
        feeConfig.cornerRadius = CGFloat.cornerRadius2x
        feeConfig.handleKeyboard = .none
        feeConfig.inAnimationDuration = 0
        feeConfig.outAnimationDuration = 0

        feeConfig.hudInset = convert(CGPoint(x: position.x - center.x, y: -feeConfig.preferredSize.height - CGFloat.margin2x), to: nil)
        return feeConfig
    }

    private func onTracking(_ value: Int, position: CGPoint) {
        HUD.instance.config = hudConfig(position: position)

        feeRateView.set(value: "\(value)")
        HUD.instance.showHUD(feeRateView)
    }

    private func finishTracking(value: Int) {
        HUD.instance.hide()

        viewModel.changeCustomPriority(value: value)
    }

}
