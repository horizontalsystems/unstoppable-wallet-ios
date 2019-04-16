import UIKit
import UIExtensions
import ActionSheet
import SnapKit
import AudioToolbox

class SendFeeItemView: BaseActionItemView {
    private let feeLabel = UILabel()
    private let convertedFeeLabel = UILabel()
    private let errorLabel = UILabel()
    private let feeSlider = FeeSlider()

    private var previousValue: Int?

    override var item: SendFeeItem? { return _item as? SendFeeItem }

    override func initView() {
        super.initView()

        addSubview(feeLabel)
        addSubview(errorLabel)
        addSubview(convertedFeeLabel)
        addSubview(feeSlider)

        if let item = item {
            feeSlider.isHidden = !item.isFeeAdjustable
        }
        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor
        let feeTitleTopMargin = (item?.isFeeAdjustable ?? false) ? SendTheme.feeTitleTopMargin : SendTheme.constantFeeTitleTopMargin
        feeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(feeTitleTopMargin)
        }

        convertedFeeLabel.font = SendTheme.feeFont
        convertedFeeLabel.textColor = SendTheme.feeColor
        convertedFeeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        convertedFeeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.leading.equalTo(feeLabel.snp.trailing).offset(SendTheme.margin)
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.bottom.equalToSuperview().offset(-SendTheme.smallMargin)
        }

        feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
        feeSlider.addTarget(self, action: #selector(onFinishSliding), for: [.touchUpOutside, .touchUpInside])
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.feeSliderLeftMargin)
            maker.top.equalTo(self.feeLabel.snp.bottom).offset(SendTheme.feeSliderTopMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.feeSliderRightMargin)
            maker.height.equalTo(SendTheme.feeSliderHeight)
        }

        sliderShift(disableSend: true)

        item?.bindFee = { [weak self] in
            self?.feeLabel.text = $0.map { "send.fee".localized + ": \($0)" }
        }
        item?.bindConvertedFee = { [weak self] in
            self?.convertedFeeLabel.text = $0
        }
        item?.bindError = { [weak self] in
            self?.errorLabel.text = $0

            self?.feeSlider.isHidden = $0 != nil
        }
    }

    @objc func sliderShift(disableSend: Bool = false) {
        let a = Int(feeSlider.value * 10)
        let b = Int(feeSlider.value) * 10

        let value = Int(floor(feeSlider.value))
        if previousValue != value, !disableSend, a == b {
            item?.onFeePriorityChange?(value)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()

            previousValue = value
        }
    }

    @objc func onFinishSliding() {
        UIView.animate(withDuration: 0.2, animations: {
            self.feeSlider.setValue(Float(Int(round(self.feeSlider.value))), animated: true)
        }, completion: { _ in
            self.sliderShift()
        })
    }

}
