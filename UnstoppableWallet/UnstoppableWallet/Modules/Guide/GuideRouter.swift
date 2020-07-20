import UIKit

class GuideRouter {
    weak var viewController: UIViewController?
}

extension GuideRouter: IGuideRouter {

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

    static func module(guide: Guide) -> UIViewController? {
        let parser = GuideParser()
        let router = GuideRouter()
        let interactor = GuideInteractor(appConfigProvider: App.shared.appConfigProvider, guidesManager: App.shared.guidesManager)

        guard let presenter = GuidePresenter(guide: guide, parser: parser, router: router, interactor: interactor) else {
            return nil
        }

        let view = GuideViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}
