import UIKit
import SnapKit
import ThemeKit

class IntroViewController: UIViewController {
    private let animationDuration: TimeInterval = 0.2

    private let delegate: IIntroViewDelegate

    private let scrollView = UIScrollView()
    private var imageViews = [UIImageView]()
    private let pageControl = UIPageControl()

    private let skipButton = UIButton()
    private let nextButton = UIButton()
    private let startButton = UIButton()

    private let slides = [
        Slide(title: "intro.independence.title".localized, description: "intro.independence.description".localized, image: "Intro - Independence"),
        Slide(title: "intro.knowledge.title".localized, description: "intro.knowledge.description".localized, image: "Intro - Knowledge"),
        Slide(title: "intro.privacy.title".localized, description: "intro.privacy.description".localized, image: "Intro - Privacy")
    ]

    init(delegate: IIntroViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeDarker

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: view.width * CGFloat(slides.count), height: view.height)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        let imageWrapperView = UIView()

        view.addSubview(imageWrapperView)
        imageWrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalToSuperview().dividedBy(2)
        }

        for (index, slide) in slides.enumerated() {
            let slideView = IntroPageView(title: slide.title, description: slide.description)
            scrollView.addSubview(slideView)
            slideView.frame = CGRect(x: view.width * CGFloat(index), y: 0, width: view.width, height: view.height)

            let imageView = UIImageView(image: UIImage(named: slide.image))

            imageWrapperView.addSubview(imageView)
            imageView.snp.makeConstraints { maker in
                maker.center.equalToSuperview()
            }

            imageView.alpha = 0
            imageViews.append(imageView)
        }

        scrollViewDidScroll(scrollView)

        let bottomWrapperBackground = UIView()
        let bottomWrapper = UIView()

        view.addSubview(bottomWrapperBackground)
        view.addSubview(bottomWrapper)

        bottomWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.height.equalTo(CGFloat.heightButton)
        }
        bottomWrapperBackground.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(bottomWrapper.snp.top)
            maker.bottom.equalToSuperview()
        }

        bottomWrapperBackground.backgroundColor = .themeDark

        bottomWrapper.addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .themeSteel20
        pageControl.currentPageIndicatorTintColor = .themeJacob

        bottomWrapper.addSubview(skipButton)
        skipButton.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        setup(button: skipButton)
        skipButton.setTitle("intro.skip".localized, for: .normal)
        skipButton.addTarget(self, action: #selector(onTapSkip), for: .touchUpInside)

        bottomWrapper.addSubview(nextButton)
        nextButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
        }

        setup(button: nextButton)
        nextButton.setTitle("intro.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNextButton), for: .touchUpInside)

        bottomWrapper.addSubview(startButton)
        startButton.snp.makeConstraints { maker in
            maker.top.trailing.bottom.equalToSuperview()
        }

        setup(button: startButton)
        startButton.setTitle("intro.get_started".localized, for: .normal)
        startButton.addTarget(self, action: #selector(onTapStartButton), for: .touchUpInside)
        startButton.isHidden = true
    }

    private func setup(button: UIButton) {
        button.setTitleColor(.themeLeah, for: .normal)
        button.setTitleColor(.themeGray50, for: .highlighted)
        button.titleLabel?.font = .headline2
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin6x, bottom: 0, right: .margin6x)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    @objc private func onTapSkip() {
        delegate.didTapSkip()
    }

    @objc private func onTapNextButton() {
        guard pageControl.currentPage < pageControl.numberOfPages - 1 else {
            return
        }

        scrollView.setContentOffset(CGPoint(x: scrollView.width * CGFloat(pageControl.currentPage + 1), y: 0), animated: true)
    }

    @objc private func onTapStartButton() {
        delegate.didTapGetStarted()
    }

    private func onSwitchSlide(index: Int) {
        let lastSlide = index == pageControl.numberOfPages - 1

        skipButton.set(hidden: lastSlide, animated: true, duration: animationDuration)
        nextButton.set(hidden: lastSlide, animated: true, duration: animationDuration)
        startButton.set(hidden: !lastSlide, animated: true, duration: animationDuration)
    }

}

extension IntroViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / view.frame.width))

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
            }
        }
    }

}

extension IntroViewController {

    private struct Slide {
        let title: String
        let description: String
        let image: String
    }

}
