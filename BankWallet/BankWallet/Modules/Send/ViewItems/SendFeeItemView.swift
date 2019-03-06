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

        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor
        feeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.feeTitleTopMargin)
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
        feeSlider.value = 0.5
        feeSlider.minimumTrackTintColor = SendTheme.feeSliderTint
        feeSlider.maximumTrackTintColor = SendTheme.feeSliderBackground
        feeSlider.setThumbImage(UIImage(named: "Fee Slider Thumb Image")?.tinted(with: SendTheme.feeSliderThumbColor), for: .normal)
        feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalTo(feeSliderSlowImageView.snp.trailing).offset(SendTheme.mediumMargin)
            maker.trailing.equalTo(feeSliderFastImageView.snp.leading).offset(-SendTheme.mediumMargin)
            maker.centerY.equalTo(self.feeSliderSlowImageView)
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

    @objc func sliderShift() {
        item?.onFeeMultiplierChange?(Decimal(Double(feeSlider.value)))
    }

}
