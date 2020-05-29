import UIKit

class GuidesInteractor {
    weak var delegate: IGuidesInteractorDelegate?

    init() {
    }

    private func header1(string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: UIFont.title2,
            .foregroundColor: UIColor.themeOz
        ])
    }

    private func header2(string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: UIFont.title3,
            .foregroundColor: UIColor.themeJacob
        ])
    }

    private func header3(string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: UIFont.headline2,
            .foregroundColor: UIColor.themeJacob
        ])
    }

    private func text(string: String) -> NSAttributedString {
        NSAttributedString(string: string, attributes: [
            .font: UIFont.body,
            .foregroundColor: UIColor.themeOz
        ])
    }

}

extension GuidesInteractor: IGuidesInteractor {

    var guides: [Guide] {
        [
            Guide(title: "How to Store Bitcoins", imageUrl: "https://media.gettyimages.com/photos/-picture-id540996432", blocks: [
                .h1(attributedString: header1(string: "Bitcoin In Simple Terms")),
                .h3(attributedString: header3(string: "About")),
                .text(attributedString: text(string: "This action will change your receive address format for Bitcoin in Unstoppable app. After that, the app will resync itself with Bitcoin blockchain.")),
                .text(attributedString: text(string: "Previous Bitcoin transactions and balance will no longer be visible. Changing it back to previous setting will bring everything back after the wallet resyncs itself.")),
                .text(attributedString: text(string: "We recommend not to change it if not sure what it's about.")),
                .h2(attributedString: header2(string: "Bitcoin Forks and Other Important Cryptocurrencies")),
                .text(attributedString: text(string: "While learning about Bitcoin, crypto newcomers quickly discover a large number of alternative cryptocurrencies already in existence. Many of them portray themselves as a better alternative to Bitcoin.")),
                .text(attributedString: text(string: "Moreover, some of these cryptocurrencies have the word \"Bitcoin\" in their names. It only adds to the confusion.")),
                .text(attributedString: text(string: "You can subdivide the various tokens in the following three ways:")),
                .image(url: "https://media.gettyimages.com/photos/530d-car-head-lights-picture-id157735154", altText: "Fig. 5. Examples of Bitcoin forks."),
                .h3(attributedString: header3(string: "Bitcoin")),
                .text(attributedString: text(string: "The original Bitcoin created by Nakamoto has the ticker symbol BTC. It's generally referred to as Bitcoin. You might also see it called Bitcoin Core.")),
                .h3(attributedString: header3(string: "Altcoins")),
                .text(attributedString: text(string: "Altcoins refers to all other cryptocurrencies that exist. Although there are thousands in circulation, only a few have managed to attract an audience and gain significant market share. The altcoins which have not attracted any audience are generally regarded as coins with no value proposition and are labeled as \"shitcoins\".")),
            ]),
            Guide(title: "Libra in Simple Terms", imageUrl: "https://media.gettyimages.com/photos/530d-car-head-lights-picture-id157735154", blocks: []),
            Guide(title: "Crypto Terms for Beginners", imageUrl: "http://media.gettyimages.com/photos/modern-key-to-the-bmw-in-a-hand-picture-id890886864", blocks: []),
            Guide(title: "Thether is Simple Terms", imageUrl: "http://media.gettyimages.com/photos/car-steel-wheels-of-a-new-bmw-coupe-picture-id516914879", blocks: []),
        ]
    }

}
