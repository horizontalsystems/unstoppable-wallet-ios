import UIKit
import SnapKit
import ThemeKit

class WelcomeScreenViewController: UIViewController {
    private let bottomInset: CGFloat = 118

    private let scrollView = UIScrollView()
    private let circleImageView = UIImageView(image: UIImage(named: "Intro - Circle"))
    private var imageViews = [UIImageView]()
    private let pageControl: BarPageControl

    private let nextButton = ThemeButton()
    private let startButton = ThemeButton()

    private var pageIndex = 0

    private let slides = [
        Slide(title: nil, description: "intro.brand.description".localized, image: "Intro - Logo"),
        Slide(title: "intro.independence.title".localized, description: "intro.independence.description".localized, image: "Intro - Independence"),
        Slide(title: "intro.privacy.title".localized, description: "intro.privacy.description".localized, image: "Intro - Privacy"),
        Slide(title: "intro.knowledge.title".localized, description: "intro.knowledge.description".localized, image: "Intro - Knowledge")
    ]

    init() {
        pageControl = BarPageControl(barCount: slides.count)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeDarker

        let wrapperView = UIView()

        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(bottomInset)
        }

        let imageWrapperView = UIView()

        wrapperView.addSubview(imageWrapperView)
        imageWrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalToSuperview().multipliedBy(2.0 / 3.0)
        }

        imageWrapperView.addSubview(circleImageView)
        circleImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.size.equalTo(imageWrapperView.snp.height).multipliedBy(4.0 / 5.0)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: view.width * CGFloat(slides.count), height: view.height)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        for (index, slide) in slides.enumerated() {
            let slideView = IntroPageView(title: slide.title, description: slide.description, bottomInset: bottomInset)
            scrollView.addSubview(slideView)
            slideView.frame = CGRect(x: view.width * CGFloat(index), y: 0, width: view.width, height: view.height)

            let imageView = UIImageView(image: UIImage(named: slide.image))

            imageWrapperView.addSubview(imageView)
            imageView.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.centerY.equalToSuperview()
                maker.size.equalTo(imageWrapperView.snp.height).multipliedBy(4.0 / 5.0)
            }

            imageView.alpha = 0
            imageViews.append(imageView)
        }

        scrollViewDidScroll(scrollView)

        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
        }

        pageControl.currentPage = 0

        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(pageControl.snp.bottom).offset(CGFloat.margin32)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin32)
        }

        nextButton.apply(style: .primaryGray)
        nextButton.setTitle("intro.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        view.addSubview(startButton)
        startButton.snp.makeConstraints { maker in
            maker.edges.equalTo(nextButton)
        }

        startButton.isHidden = true
        startButton.apply(style: .primaryYellow)
        startButton.setTitle("intro.start".localized, for: .normal)
        startButton.addTarget(self, action: #selector(onTapStart), for: .touchUpInside)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @objc private func onTapNext() {
        if pageControl.currentPage < pageControl.numberOfPages - 1 {
            scrollView.setContentOffset(CGPoint(x: scrollView.width * CGFloat(pageControl.currentPage + 1), y: 0), animated: true)
        }
    }

    @objc private func onTapStart() {
        UIApplication.shared.keyWindow?.set(newRootController: MainModule.instance())
    }

    private func onSwitchSlide(index: Int) {
        let lastSlide = index == pageControl.numberOfPages - 1

        nextButton.set(hidden: lastSlide, animated: true, duration: 0.2)
        startButton.set(hidden: !lastSlide, animated: true, duration: 0.2)
    }

}

extension WelcomeScreenViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageIndex = Int(round(scrollView.contentOffset.x / view.frame.width))

        if pageControl.currentPage != pageIndex {
            pageControl.currentPage = pageIndex
            onSwitchSlide(index: pageIndex)
        }

        let maximumOffset: CGFloat = scrollView.contentSize.width - scrollView.frame.width
        let currentOffset: CGFloat = scrollView.contentOffset.x

        let currentPercent: CGFloat = currentOffset / maximumOffset

        let pagePercent = CGFloat(1) / CGFloat(slides.count - 1)

        for i in 0..<slides.count {
            let fi = CGFloat(i)
            if currentPercent >= (fi - 1) * pagePercent && currentPercent <= (fi + 1) * pagePercent {
                let offset: CGFloat = abs((fi * pagePercent) - currentPercent)
                let percent: CGFloat = offset / pagePercent

                imageViews[i].alpha = 1 - percent

                circleImageView.alpha = min(currentPercent, pagePercent) / pagePercent
            } else {
                imageViews[i].alpha = 0
            }
        }
    }

}

extension WelcomeScreenViewController {

    private struct Slide {
        let title: String?
        let description: String
        let image: String
    }

}
