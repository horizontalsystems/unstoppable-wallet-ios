import UIKit
import UIExtensions
import SnapKit
import ThemeKit
import ComponentKit

class BalanceButtonsView: UIView {
    public static let height: CGFloat = 72

    private let sendButtonWrapper = UIControl()
    private let sendButton = ThemeButton()

    private let receiveButton = ThemeButton()

    private let swapButtonWrapper = UIControl()
    private let swapButton = ThemeButton()

    private let chartButton = ThemeButton()

    private var onTapReceive: (() -> ())?
    private var onTapSend: (() -> ())?
    private var onTapSwap: (() -> ())?
    private var onTapChart: (() -> ())?

    init() {
        super.init(frame: .zero)

        addSubview(sendButtonWrapper)
        sendButtonWrapper.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin12)
            maker.top.equalToSuperview().offset(10)
            maker.height.equalTo(CGFloat.heightButton)
        }

        sendButtonWrapper.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        sendButton.apply(style: .primaryYellow)
        sendButton.setTitle("balance.send".localized, for: .normal)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)

        addSubview(receiveButton)
        receiveButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        addSubview(swapButtonWrapper)

        swapButtonWrapper.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        swapButton.apply(style: .primaryIconGray)
        swapButton.setImage(UIImage(named: "arrow_swap_2_24"), for: .normal)
        swapButton.addTarget(self, action: #selector(onSwap), for: .touchUpInside)

        let chartButtonWrapper = UIControl()     // disable touch events through cell to tableView

        addSubview(chartButtonWrapper)
        chartButtonWrapper.snp.makeConstraints { maker in
            maker.leading.equalTo(swapButtonWrapper.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalTo(sendButtonWrapper.snp.top)
            maker.trailing.equalToSuperview().inset(CGFloat.margin12)
            maker.size.equalTo(CGFloat.heightButton)
        }

        chartButtonWrapper.addSubview(chartButton)
        chartButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        chartButton.apply(style: .primaryIconGray)
        chartButton.setImage(UIImage(named: "chart_2_24"), for: .normal)
        chartButton.addTarget(self, action: #selector(onChart), for: .touchUpInside)

        updateButtons(swapHidden: true)
    }

    private func updateButtons(swapHidden: Bool) {
        if swapHidden {
            receiveButton.apply(style: .primaryGray)
            receiveButton.setTitle("balance.deposit".localized, for: .normal)
            receiveButton.setImage(nil, for: .normal)
        } else {
            receiveButton.apply(style: .primaryIconGray)
            receiveButton.setTitle(nil, for: .normal)
            receiveButton.setImage(UIImage(named: "arrow_medium_3_down_left_24"), for: .normal)
        }

        receiveButton.snp.remakeConstraints { maker in
            maker.leading.equalTo(sendButtonWrapper.snp.trailing).offset(CGFloat.margin8)
            maker.top.equalTo(sendButtonWrapper.snp.top)
            if swapHidden {
                maker.width.equalTo(sendButtonWrapper)
                maker.height.equalTo(CGFloat.heightButton)
            } else {
                maker.size.equalTo(CGFloat.heightButton)
            }
        }

        swapButtonWrapper.snp.remakeConstraints { maker in
            if swapHidden {
                maker.leading.equalTo(receiveButton.snp.trailing)
                maker.width.equalTo(0)
                maker.height.equalTo(CGFloat.heightButton)
            } else {
                maker.leading.equalTo(receiveButton.snp.trailing).offset(CGFloat.margin2x)
                maker.size.equalTo(CGFloat.heightButton)
            }
            maker.top.equalTo(sendButtonWrapper.snp.top)
        }
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
