import UIKit
import UIExtensions
import SnapKit
import ThemeKit
import ComponentKit

class BalanceButtonsView: UIView {
    public static let height: CGFloat = 70

    private let sendButtonWrapper = UIControl()
    private let sendButton = PrimaryButton()
    private let withdrawButtonWrapper = UIControl()
    private let withdrawButton = PrimaryButton()
    private let receiveButton = PrimaryButton()
    private let receiveCircleButton = PrimaryCircleButton()
    private let depositButtonWrapper = UIControl()
    private let depositButton = PrimaryButton()
    private let addressButton = PrimaryButton()
    private let swapButtonWrapper = UIControl()
    private let swapButton = PrimaryCircleButton()
    private let chartButtonWrapper = UIControl()
    private let chartButton = PrimaryCircleButton()

    private var onTapSend: (() -> ())?
    private var onTapWithdraw: (() -> ())?
    private var onTapReceive: (() -> ())?
    private var onTapDeposit: (() -> ())?
    private var onTapSwap: (() -> ())?
    private var onTapChart: (() -> ())?

    init() {
        super.init(frame: .zero)

        let stackView = UIStackView()

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalToSuperview().offset(CGFloat.margin4)
        }

        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = .margin8

        stackView.addArrangedSubview(sendButtonWrapper)

        sendButtonWrapper.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        sendButton.set(style: .yellow, accessoryType: .icon(image: UIImage(named: "arrow_medium_2_up_right_24")))
        sendButton.setTitle("balance.send".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)

        stackView.addArrangedSubview(withdrawButtonWrapper)

        withdrawButtonWrapper.addSubview(withdrawButton)
        withdrawButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        withdrawButton.set(style: .yellow)
        withdrawButton.setTitle("balance.withdraw".localized, for: .normal)
        withdrawButton.addTarget(self, action: #selector(onWithdraw), for: .touchUpInside)

        stackView.addArrangedSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.width.equalTo(sendButton)
        }

        receiveButton.set(style: .gray, accessoryType: .icon(image: UIImage(named: "arrow_medium_2_down_left_24")))
        receiveButton.setTitle("balance.receive".localized, for: .normal)
        receiveButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        stackView.addArrangedSubview(depositButtonWrapper)

        depositButtonWrapper.addSubview(depositButton)
        depositButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.width.equalTo(withdrawButton)
        }

        depositButton.set(style: .gray)
        depositButton.setTitle("balance.deposit".localized, for: .normal)
        depositButton.addTarget(self, action: #selector(onDeposit), for: .touchUpInside)

        stackView.addArrangedSubview(receiveCircleButton)

        receiveCircleButton.set(style: .gray)
        receiveCircleButton.set(image: UIImage(named: "arrow_medium_3_down_left_24"))
        receiveCircleButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        stackView.addArrangedSubview(addressButton)

        addressButton.set(style: .gray)
        addressButton.setTitle("balance.address".localized, for: .normal)
        addressButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        stackView.addArrangedSubview(swapButtonWrapper)

        swapButtonWrapper.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        swapButton.set(style: .gray)
        swapButton.set(image: UIImage(named: "arrow_swap_2_24"))
        swapButton.addTarget(self, action: #selector(onSwap), for: .touchUpInside)

        stackView.addArrangedSubview(chartButtonWrapper)

        chartButtonWrapper.addSubview(chartButton)
        chartButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        chartButton.set(style: .gray)
        chartButton.set(image: UIImage(named: "chart_2_24"))
        chartButton.addTarget(self, action: #selector(onChart), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(buttons: [WalletModule.Button: ButtonState], sendAction: (() -> ())?, withdrawAction: (() -> ())?, receiveAction: (() -> ())?, depositAction: (() -> ())?, swapAction: (() -> ())?, chartAction: (() -> ())?) {
        sendButton.isEnabled = buttons[.send] == .enabled
        withdrawButton.isEnabled = buttons[.withdraw] == .enabled
        receiveButton.isEnabled = buttons[.receive] == .enabled
        receiveCircleButton.isEnabled = buttons[.receive] == .enabled
        depositButton.isEnabled = buttons[.deposit] == .enabled
        addressButton.isEnabled = buttons[.address] == .enabled
        swapButton.isEnabled = buttons[.swap] == .enabled
        chartButton.isEnabled = buttons[.chart] == .enabled

        sendButtonWrapper.isHidden = (buttons[.send] ?? .hidden) == .hidden
        withdrawButtonWrapper.isHidden = (buttons[.withdraw] ?? .hidden) == .hidden
        receiveButton.isHidden = (buttons[.receive] ?? .hidden) == .hidden || buttons.count > 2
        receiveCircleButton.isHidden = (buttons[.receive] ?? .hidden) == .hidden || buttons.count <= 2
        depositButtonWrapper.isHidden = (buttons[.deposit] ?? .hidden) == .hidden
        addressButton.isHidden = (buttons[.address] ?? .hidden) == .hidden
        swapButtonWrapper.isHidden = (buttons[.swap] ?? .hidden) == .hidden
        chartButtonWrapper.isHidden = (buttons[.chart] ?? .hidden) == .hidden

        onTapSend = sendAction
        onTapWithdraw = withdrawAction
        onTapReceive = receiveAction
        onTapDeposit = depositAction
        onTapSwap = swapAction
        onTapChart = chartAction
    }

    @objc private func onSend() {
        onTapSend?()
    }

    @objc private func onWithdraw() {
        onTapWithdraw?()
    }

    @objc private func onReceive() {
        onTapReceive?()
    }

    @objc private func onDeposit() {
        onTapDeposit?()
    }

    @objc private func onSwap() {
        onTapSwap?()
    }

    @objc private func onChart() {
        onTapChart?()
    }

}
