import UIKit
import GrouviExtensions
import GrouviActionSheet
import SnapKit
import AudioToolbox

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
    private var stepViews = [UIView]()

    private var previousValue: Int?

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
        feeSlider.maximumTrackTintColor = SendTheme.stepViewInactiveColor
        feeSlider.setThumbImage(UIImage(named: "Fee Slider Thumb Image")?.tinted(with: SendTheme.feeSliderThumbColor), for: .normal)
        feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
        feeSlider.addTarget(self, action: #selector(onFinishSliding), for: [.touchUpOutside, .touchUpInside])
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalTo(feeSliderSlowImageView.snp.trailing).offset(SendTheme.mediumMargin)
            maker.trailing.equalTo(feeSliderFastImageView.snp.leading).offset(-SendTheme.mediumMargin)
            maker.centerY.equalTo(self.feeSliderSlowImageView)
        }

        for i in 0..<5 {
            let stepView = UIView()
            feeSlider.addSubview(stepView)
            stepView.isUserInteractionEnabled = false
            stepView.layer.cornerRadius = SendTheme.stepViewSideSize / 2
            stepView.snp.makeConstraints { maker in
                maker.centerY.equalTo(self.feeSlider).offset(1 / UIScreen.main.scale)
                maker.size.equalTo(SendTheme.stepViewSideSize)
                if i == 0 {
                    maker.leading.equalTo(self.feeSlider)
                } else if i == 4 {
                    maker.trailing.equalTo(self.feeSlider)
                } else {
                    let multiplier: CGFloat = CGFloat(i) * 0.25
                    maker.leading.equalTo(self.feeSlider.snp.trailing).multipliedBy(multiplier)
                }
            }
            stepViews.append(stepView)
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

            if $0 == nil {
                self?.feeSlider.isHidden = false
                self?.feeSliderSlowImageView.isHidden = false
                self?.feeSliderFastImageView.isHidden = false
            } else {
                self?.feeSlider.isHidden = true
                self?.feeSliderSlowImageView.isHidden = true
                self?.feeSliderFastImageView.isHidden = true
            }
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

        for (index, view) in stepViews.enumerated() {
            if index <= value {
                view.backgroundColor = SendTheme.feeSliderTint
            } else {
                view.backgroundColor = SendTheme.stepViewInactiveColor
            }
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
