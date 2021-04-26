import UIKit
import UIExtensions
import SnapKit
import ThemeKit
import ComponentKit

open class BalanceButtonsView: UIView {
    public static let height: CGFloat = 58

    private let receiveButton = ThemeButton()
    private let sendButton = ThemeButton()
    private let swapButton = ThemeButton()

    private var onTapReceive: (() -> ())?
    private var onTapSend: (() -> ())?
    private var onTapSwap: (() -> ())?

    public init(receiveStyle: ThemeButtonStyle, sendStyle: ThemeButtonStyle, swapStyle: ThemeButtonStyle) {
        super.init(frame: .zero)

        addSubview(receiveButton)
        receiveButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        receiveButton.apply(style: receiveStyle)
        receiveButton.addTarget(self, action: #selector(onReceive), for: .touchUpInside)

        let sendButtonWrapper = UIControl()     // disable touch events through cell to tableView
        addSubview(sendButtonWrapper)

        sendButtonWrapper.snp.makeConstraints { maker in
            maker.leading.equalTo(receiveButton.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalTo(receiveButton.snp.top)
            maker.width.equalTo(receiveButton.snp.width)
            maker.height.equalTo(CGFloat.heightButton)
        }

        sendButtonWrapper.addSubview(sendButton)
        sendButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        sendButton.apply(style: sendStyle)
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)

        let swapButtonWrapper = UIControl()     // disable touch events through cell to tableView
        addSubview(swapButtonWrapper)

        swapButtonWrapper.snp.makeConstraints { maker in
            maker.leading.equalTo(sendButtonWrapper.snp.trailing).offset(CGFloat.margin2x)
            maker.top.equalTo(receiveButton.snp.top)
            maker.size.equalTo(CGFloat.heightButton)
        }

        swapButtonWrapper.addSubview(swapButton)
        swapButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        swapButton.apply(style: swapStyle)
        swapButton.setImageTintColor(.black, for: .normal)
        swapButton.setImageTintColor(.themeGray50, for: .disabled)
        swapButton.setImage(UIImage(named: "arrow_swap_2_24"), for: .normal)
        swapButton.addTarget(self, action: #selector(onSwap), for: .touchUpInside)
    }

    private func updateSwap(hidden: Bool) {
        guard let swapWrapper = swapButton.superview,
              let sendWrapper = sendButton.superview
                else {
            return
        }

        swapWrapper.snp.remakeConstraints { maker in
            if hidden {
                maker.leading.equalTo(sendWrapper.snp.trailing)
                maker.width.equalTo(0)
            } else {
                maker.leading.equalTo(sendWrapper.snp.trailing).offset(CGFloat.margin2x)
                maker.top.equalTo(receiveButton.snp.top)
                maker.trailing.equalToSuperview()
                maker.width.equalTo(CGFloat.heightButton)
            }
            maker.top.equalTo(receiveButton.snp.top)
            maker.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightButton)
        }
        UIView.performWithoutAnimation {
            layoutIfNeeded()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    public func bind(receiveTitle: String, sendTitle: String) {
        receiveButton.setTitle(receiveTitle, for: .normal)
        sendButton.setTitle(sendTitle, for: .normal)
    }

    public func bind(receiveButtonState: ButtonState, sendButtonState: ButtonState, swapButtonState: ButtonState, receiveAction: @escaping () -> (), sendAction: @escaping () -> (), swapAction: @escaping () -> ()) {
        receiveButton.isEnabled = receiveButtonState == .enabled
        sendButton.isEnabled = sendButtonState == .enabled
        swapButton.isEnabled = swapButtonState == .enabled
        updateSwap(hidden: swapButtonState == .hidden)

        onTapReceive = receiveAction
        onTapSend = sendAction
        onTapSwap = swapAction
    }

    @objc private func onReceive() {
        onTapReceive?()
    }

    @objc private func onSend() {
        onTapSend?()
    }

    @objc private func onSwap() {
        onTapSwap?()
    }

}
