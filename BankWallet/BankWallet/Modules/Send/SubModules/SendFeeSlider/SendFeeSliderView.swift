import UIKit

class SendFeeSliderView: UIView {
    private let delegate: ISendFeeSliderViewDelegate

    private let feeSlider = FeeSlider()
    private var previousValue: Int?

    init(delegate: ISendFeeSliderViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feeSliderHeight)
        }

        backgroundColor = .clear

        addSubview(feeSlider)

        feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
        feeSlider.addTarget(self, action: #selector(onFinishSliding), for: [.touchUpOutside, .touchUpInside])
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.feeSliderLeftMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.feeSliderRightMargin)
            maker.top.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @objc private func sliderShift() {
        let a = Int(feeSlider.value * 10)
        let b = Int(feeSlider.value) * 10

        let value = Int(floor(feeSlider.value))
        if previousValue != value, a == b {
            delegate.onFeePriorityChange(value: value)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()

            previousValue = value
        }
    }

    @objc private func onFinishSliding() {
        UIView.animate(withDuration: 0.2, animations: {
            self.feeSlider.setValue(Float(Int(round(self.feeSlider.value))), animated: true)
        }, completion: { _ in
            self.sliderShift()
        })
    }

}

extension SendFeeSliderView: ISendFeeSliderView {
}
