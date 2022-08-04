import UIKit
import UIExtensions
import SnapKit
import ThemeKit
import ComponentKit

class BalanceButtonsView: UIView {
    public static let height: CGFloat = 72

    private let sendButton = PrimaryButton()
    private let receiveButton = PrimaryButton()
    private let receiveCircleButton = PrimaryCircleButton()
    private let swapButtonWrapper = UIControl()
    private let swapButton = PrimaryCircleButton()
    private let chartButton = PrimaryCircleButton()

    private var onTapReceive: (() -> ())?
    private var onTapSend: (() -> ())?
    private var onTapSwap: (() -> ())?
    private var onTapChart: (() -> ())?

    init() {
        super.init(frame: .zero)

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalToSuperview().offset(10)
        }

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = .margin8

        let sendButtonWrapper = UIControl()
        stackView.addArrangedSubview(sendButtonWrapper)

        sendButtonWrapper.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        sendButton.set(style: .yellow)
        sendButton.setTitle("balance.send".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)

        stackView.addArrangedSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.width.equalTo(sendButton)
        }

        receiveButton.set(style: .gray)
        receiveButton.setTitle("balance.deposit".localized, for: .normal)
        receiveButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        stackView.addArrangedSubview(receiveCircleButton)

        receiveCircleButton.set(style: .gray)
        receiveCircleButton.set(image: UIImage(named: "arrow_medium_3_down_left_24"))
        receiveCircleButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        stackView.addArrangedSubview(swapButtonWrapper)

        swapButtonWrapper.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        swapButton.set(style: .gray)
        swapButton.set(image: UIImage(named: "arrow_swap_2_24"))
        swapButton.addTarget(self, action: #selector(onSwap), for: .touchUpInside)

        let chartButtonWrapper = UIControl()

        stackView.addArrangedSubview(chartButtonWrapper)

        chartButtonWrapper.addSubview(chartButton)
        chartButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        chartButton.set(style: .gray)
        chartButton.set(image: UIImage(named: "chart_2_24"))
        chartButton.addTarget(self, action: #selector(onChart), for: .touchUpInside)

        updateButtons(swapHidden: true)
    }

    private func updateButtons(swapHidden: Bool) {
        receiveButton.isHidden = !swapHidden
        receiveCircleButton.isHidden = swapHidden
        swapButtonWrapper.isHidden = swapHidden
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: BalanceButtonsViewItem, sendAction: @escaping () -> (), receiveAction: @escaping () -> (), swapAction: @escaping () -> (), chartAction: @escaping () -> ()) {
        sendButton.isEnabled = viewItem.sendButtonState == .enabled
        receiveButton.isEnabled = viewItem.receiveButtonState == .enabled
        swapButton.isEnabled = viewItem.swapButtonState == .enabled
        chartButton.isEnabled = viewItem.chartButtonState == .enabled

        updateButtons(swapHidden: viewItem.swapButtonState == .hidden)

        onTapSend = sendAction
        onTapReceive = receiveAction
        onTapSwap = swapAction
        onTapChart = chartAction
    }

    @objc private func onSend() {
        onTapSend?()
    }

    @objc private func onReceive() {
        onTapReceive?()
    }

    @objc private func onSwap() {
        onTapSwap?()
    }

    @objc private func onChart() {
        onTapChart?()
    }

}
