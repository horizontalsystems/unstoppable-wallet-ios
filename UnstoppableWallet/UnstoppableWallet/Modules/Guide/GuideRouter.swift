import UIKit

class GuideRouter {
    weak var viewController: UIViewController?
}

extension GuideRouter: IGuideRouter {

    func showGuide(url: URL) {
        let module = GuideRouter.module(guideUrl: url)
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func showFontSize(selected: Int, onSelect: @escaping (Int) -> ()) {
        let fontSizes = [10, 14, 17, 22, 28]

        let alertController = AlertRouter.module(
                title: "Font Size",
                viewItems: fontSizes.map { fontSize in
                    AlertViewItem(text: "\(fontSize)", selected: fontSize == selected)
                }
        ) { index in
            onSelect(fontSizes[index])
        }

        viewController?.present(alertController, animated: true)
    }

}

extension GuideRouter {

    static func module(guideUrl: URL) -> UIViewController {
        let parser = GuideParser()
        let router = GuideRouter()
        let interactor = GuideInteractor(guidesManager: App.shared.guidesManager)
        let presenter = GuidePresenter(guideUrl: guideUrl, parser: parser, router: router, interactor: interactor)
        let view = GuideViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
