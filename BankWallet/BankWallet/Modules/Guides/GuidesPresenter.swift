class GuidesPresenter {
    weak var view: IGuidesView?

    private let router: IGuidesRouter
    private let interactor: IGuidesInteractor

    private let viewItems: [GuideViewItem] = [
        GuideViewItem(
                title: "How to Store Bitcoins",
                large: true,
                url: "https://horizontalsystems.io/",
                coinCode: nil,
                imageUrl: "https://ag-spots-2015.o.auroraobjects.eu/2015/10/13/other/2880-1800-crop-bmw-m5-f10-2011-c992313102015171001_1.jpg"
        ),
        GuideViewItem(
                title: "Libra in Simple Terms",
                large: true,
                url: "https://unstoppable.money/",
                coinCode: "LOOM",
                imageUrl: nil
        ),
        GuideViewItem(
                title: "Thether is Simple Terms",
                large: false,
                url: "https://www.google.com/",
                coinCode: "USDT",
                imageUrl: nil
        ),
        GuideViewItem(
                title: "Crypto Terms for Beginners",
                large: false,
                url: "https://www.facebook.com/",
                coinCode: nil,
                imageUrl: "https://pbs.twimg.com/media/DQzb48iV4AA_2Tu.jpg"
        ),
    ]

    init(router: IGuidesRouter, interactor: IGuidesInteractor) {
        self.router = router
        self.interactor = interactor
    }

}

extension GuidesPresenter: IGuidesViewDelegate {

    func onLoad() {
        view?.set(viewItems: viewItems)
    }

    func onTapGuide(index: Int) {
        let viewItem = viewItems[index]
        router.showGuide(url: viewItem.url)
    }

}

extension GuidesPresenter: IGuidesInteractorDelegate {
}
