import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit

class TappableSlider: UISlider {
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }
}

class SendFeeItemView: BaseActionItemView {
    private let feeLabel = UILabel()
    private let convertedFeeLabel = UILabel()
    private let errorLabel = UILabel()
    private let feeSlider = TappableSlider()
    private let feeSliderSlowImageView = UIImageView(image: UIImage(named: "Fee Slider Slow"))
    private let feeSliderFastImageView = UIImageView(image: UIImage(named: "Fee Slider Fast"))


    override var item: SendFeeItem? { return _item as? SendFeeItem }

    override func initView() {
        super.initView()

        addSubview(feeLabel)
        addSubview(errorLabel)
        addSubview(convertedFeeLabel)
        addSubview(feeSlider)
        addSubview(feeSliderSlowImageView)
        addSubview(feeSliderFastImageView)

        if let item = item {
            feeSlider.isHidden = !item.isFeeAdjustable
            feeSliderSlowImageView.isHidden = !item.isFeeAdjustable
            feeSliderFastImageView.isHidden = !item.isFeeAdjustable
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

        feeSliderSlowImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(self.feeLabel.snp.bottom).offset(SendTheme.feeSliderTopMargin)
        }
        feeSliderFastImageView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.centerY.equalTo(self.feeSliderSlowImageView)
        }
        feeSlider.maximumValue = 4
        feeSlider.minimumValue = 0
        feeSlider.value = 2
        feeSlider.minimumTrackTintColor = SendTheme.feeSliderTint
        feeSlider.maximumTrackTintColor = SendTheme.feeSliderBackground
        feeSlider.setThumbImage(UIImage(named: "Fee Slider Thumb Image")?.tinted(with: SendTheme.feeSliderThumbColor), for: .normal)
        feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
        feeSlider.addTarget(self, action: #selector(onFinishSliding), for: [.touchUpOutside, .touchUpInside])
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalTo(feeSliderSlowImageView.snp.trailing).offset(SendTheme.mediumMargin)
            maker.trailing.equalTo(feeSliderFastImageView.snp.leading).offset(-SendTheme.mediumMargin)
            maker.centerY.equalTo(self.feeSliderSlowImageView)
        }

        for i in 0..<3 {
            let stepView = UIView()
            stepView.backgroundColor = SendTheme.feeSliderTint
            feeSlider.addSubview(stepView)
            stepView.isUserInteractionEnabled = false
            stepView.snp.makeConstraints { maker in
                maker.centerY.equalTo(self.feeSlider)
                maker.height.equalTo(SendTheme.stepViewHeight)
                maker.width.equalTo(SendTheme.stepViewWidth)
                let multiplier: CGFloat = CGFloat(i + 1) * 0.25
                maker.leading.equalTo(self.feeSlider.snp.trailing).multipliedBy(multiplier)
            }
        }

        item?.bindFee = { [weak self] in
            self?.feeLabel.text = $0.map { "send.fee".localized + ": \($0)" }
        }
        item?.bindConvertedFee = { [weak self] in
            self?.convertedFeeLabel.text = $0
        }
        item?.bindError = { [weak self] in
            self?.errorLabel.text = $0
        }
    }

    var valueSent: Int?
    @objc func sliderShift() {
        let valueToSend = Int(round(feeSlider.value))
        if valueSent != valueToSend {
            item?.onFeeMultiplierChange?(valueToSend)
            valueSent = valueToSend
        }
    }

    @objc func onFinishSliding() {
        UIView.animate(withDuration: 0.2, animations: {
            self.feeSlider.setValue(Float(Int(round(self.feeSlider.value))), animated: true)
        })
    }

}
