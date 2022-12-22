import Foundation
import UIKit
import RxSwift
import SnapKit
import ThemeKit
import ComponentKit

class SwapInputCell: UITableViewCell {
    static let cellHeight: CGFloat = 180

    private let disposeBag = DisposeBag()

    private let cardView = CardView(insets: .zero)

    private let fromInputCard: SwapInputCardView

    private let leftSeparatorView = UIView()
    private let rightSeparatorView = UIView()
    private let switchButton = SecondaryCircleButton()

    private let toInputCard: SwapInputCardView

    var onSwitch: (() -> ())?

    weak var presentDelegate: IPresentDelegate? {
        didSet {
            fromInputCard.presentDelegate = presentDelegate
            toInputCard.presentDelegate = presentDelegate
        }
    }

    init(fromViewModel: SwapCoinCardViewModel, fromAmountInputViewModel: AmountInputViewModel, toViewModel: SwapCoinCardViewModel, toAmountInputViewModel: AmountInputViewModel) {
        fromInputCard = SwapInputCardView(viewModel: fromViewModel, amountInputViewModel: fromAmountInputViewModel, isTopView: true)
        toInputCard = SwapInputCardView(viewModel: toViewModel, amountInputViewModel: toAmountInputViewModel, isTopView: false)

        super.init(style: .default, reuseIdentifier: nil)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.bottom.equalToSuperview()
        }

        cardView.addSubview(fromInputCard)
        fromInputCard.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(SwapInputCardView.lineHeight)
        }

        cardView.addSubview(switchButton)
        switchButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        switchButton.set(image: UIImage(named: "arrow_medium_2_down_24"), style: .default)
        switchButton.addTarget(self, action: #selector(onTapSwitch), for: .touchUpInside)

        cardView.addSubview(leftSeparatorView)
        leftSeparatorView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.trailing.equalTo(switchButton.snp.leading)
            maker.bottom.equalTo(fromInputCard.snp.bottom).offset(0.5)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        cardView.addSubview(rightSeparatorView)
        rightSeparatorView.snp.makeConstraints { maker in
            maker.leading.equalTo(switchButton.snp.trailing)
            maker.trailing.equalToSuperview()
            maker.bottom.equalTo(fromInputCard.snp.bottom).offset(0.5)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        leftSeparatorView.backgroundColor = .themeSteel20
        rightSeparatorView.backgroundColor = .themeSteel20

        cardView.addSubview(toInputCard)
        toInputCard.snp.makeConstraints { maker in
            maker.top.equalTo(leftSeparatorView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(SwapInputCardView.lineHeight)
        }

        cardView.bringSubviewToFront(switchButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        fromInputCard.becomeFirstResponder()
    }

    @objc private func onTapSwitch() {
        onSwitch?()
    }

}

extension SwapInputCell {

}
