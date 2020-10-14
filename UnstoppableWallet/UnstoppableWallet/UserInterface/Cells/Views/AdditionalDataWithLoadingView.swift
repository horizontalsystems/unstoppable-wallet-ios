import UIKit
import HUD

class AdditionalDataWithLoadingView: UIView {
    private static let spinnerRadius: CGFloat = 8
    private static let spinnerLineWidth: CGFloat = 2

    private let additionalDataView = AdditionalDataView()

    private let processSpinner = HUDProgressView(
            strokeLineWidth: AdditionalDataWithLoadingView.spinnerLineWidth,
            radius: AdditionalDataWithLoadingView.spinnerRadius,
            strokeColor: .themeOz
    )


    override init(frame: CGRect) {
        super.init(frame: frame)

        snp.makeConstraints { maker in
            maker.height.equalTo(AdditionalDataView.height)
        }

        backgroundColor = .clear

        addSubview(additionalDataView)
        additionalDataView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
        }

        addSubview(processSpinner)
        processSpinner.snp.makeConstraints { maker in
            maker.centerY.equalTo(additionalDataView.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.width.height.equalTo(AdditionalDataWithLoadingView.spinnerRadius * 2 + AdditionalDataWithLoadingView.spinnerLineWidth)
        }

        processSpinner.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func spinner(show: Bool) {
        processSpinner.isHidden = !show
        if show {
            processSpinner.startAnimating()
        } else {
            processSpinner.stopAnimating()
        }
    }

    func bind(title: String?, value: String?) {
        additionalDataView.bind(title: title, value: value)
        additionalDataView.setValue(hidden: false)

        spinner(show: false)
    }

    func setValue(color: UIColor) {
        additionalDataView.setValue(color: color)
    }

    func set(loading: Bool) {
        additionalDataView.setValue(hidden: loading)

        spinner(show: loading)
    }

    func set(hidden: Bool) {
        snp.updateConstraints { maker in
            maker.height.equalTo(hidden ? 0 : AdditionalDataView.height)
        }
        additionalDataView.isHidden = hidden
        processSpinner.isHidden = hidden
    }

}
