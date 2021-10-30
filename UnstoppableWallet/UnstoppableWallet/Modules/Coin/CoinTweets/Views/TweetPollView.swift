import UIKit
import ThemeKit

class TweetPollView: UIView {
    private let stackView = UIStackView()

    init() {
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(stackView)
        stackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = .margin8
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(options: [(position: Int, label: String, votes: Int)]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let totalVotes: Int = options.reduce(0) { acc, option in acc + option.votes }
        let mostVotesOption = options.sorted(by: { option1, option2 in option1.votes < option2.votes }).last
        let totalWidth = superview?.size.width ?? 1

        for option in options {
            let percentage = totalVotes > 0 ? option.votes * 100 / totalVotes : 0
            let width = percentage * Int(totalWidth) / 100

            let wrapperView = UIView()
            stackView.addArrangedSubview(wrapperView)
            wrapperView.snp.makeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.height.equalTo(28)
            }

            wrapperView.backgroundColor = .themeSteel10
            wrapperView.cornerRadius = 4

            let votesView = UIView()
            wrapperView.addSubview(votesView)
            votesView.snp.makeConstraints { maker in
                maker.leading.top.bottom.equalToSuperview()
                maker.height.equalTo(28)
                maker.width.equalTo(width)
            }

            if let mostVotesOption = mostVotesOption, mostVotesOption.position == option.position {
                votesView.backgroundColor = .themeIssykBlue
            } else {
                votesView.backgroundColor = .themeSteel20
            }
            votesView.cornerRadius = 4

            let label = UILabel()
            wrapperView.addSubview(label)
            label.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().inset(CGFloat.margin12)
                maker.centerY.equalToSuperview()
            }

            label.text = option.label
            label.font = .captionSB
            label.textColor = .themeLeah
            
            let percentageLabel = UILabel()
            wrapperView.addSubview(percentageLabel)
            percentageLabel.snp.makeConstraints { maker in
                maker.trailing.equalToSuperview().inset(CGFloat.margin12)
                maker.centerY.equalToSuperview()
            }
            
            percentageLabel.text = "\(percentage)%"
            percentageLabel.font = .captionSB
            percentageLabel.textColor = .themeLeah
        }
    }

    static func height(options: [(position: Int, label: String, votes: Int)], containerWidth: CGFloat) -> CGFloat {
        CGFloat((28 + 8) * options.count - 8)
    }

}
