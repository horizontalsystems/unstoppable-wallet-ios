import UIKit
import SnapKit
import ThemeKit

class WelcomeScreenViewController: UIViewController {
    private let delegate: IWelcomeScreenViewDelegate

    private let wrapperView = UIView()

    private let scrollView = UIScrollView()
    private let imageWrapperView = UIView()
    private let circleImageView = UIImageView(image: UIImage(named: "Intro - Circle"))
    private var imageViews = [UIImageView]()
    private let bottomWrapperBackground = UIView()
    private let bottomWrapper = UIView()
    private let pageControl: BarPageControl

    private let skipButton = UIButton()
    private let nextButton = UIButton()

    private let logoWrapper = UIView()
    private let logoImageView = UIImageView()
    private let buttonsWrapper = UIView()

    private var pageIndex = 0

    private let slides = [
        Slide(title: nil, description: "intro.brand.description".localized, image: "Intro - Logo"),
        Slide(title: "intro.knowledge.title".localized, description: "intro.knowledge.description".localized, image: "Intro - Knowledge"),
        Slide(title: "intro.independence.title".localized, description: "intro.independence.description".localized, image: "Intro - Independence"),
        Slide(title: "intro.privacy.title".localized, description: "intro.privacy.description".localized, image: "Intro - Privacy")
    ]

    private let versionLabel = UILabel()

    init(delegate: IWelcomeScreenViewDelegate) {
        self.delegate = delegate
        pageControl = BarPageControl(barCount: slides.count)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .themeDarker

        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        wrapperView.addSubview(imageWrapperView)
        imageWrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalToSuperview().multipliedBy(3.0 / 5.0)
        }

        let imageTopOffset = CGFloat.margin4x
        imageWrapperView.addSubview(circleImageView)
        circleImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(imageTopOffset)
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
            let slideView = IntroPageView(title: slide.title, description: slide.description)
            scrollView.addSubview(slideView)
            slideView.frame = CGRect(x: view.width * CGFloat(index), y: 0, width: view.width, height: view.height)

            let imageView = UIImageView(image: UIImage(named: slide.image))

            imageWrapperView.addSubview(imageView)
            imageView.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.centerY.equalToSuperview().offset(imageTopOffset)
            }

            imageView.alpha = 0
            imageViews.append(imageView)
        }

        scrollViewDidScroll(scrollView)

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

        pageControl.currentPage = 0

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

        view.addSubview(logoWrapper)
        logoWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.snp.top)
            maker.height.equalToSuperview().dividedBy(2)
        }

        logoWrapper.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        logoImageView.image = UIImage(named: "Intro - Logo")

        view.addSubview(buttonsWrapper)
        buttonsWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.snp.bottom)
            maker.height.equalToSuperview().dividedBy(2)
        }

        let createButton = ThemeButton()

        buttonsWrapper.addSubview(createButton)
        createButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        createButton.apply(style: .primaryYellow)
        createButton.setTitle("welcome.new_wallet".localized, for: .normal)
        createButton.addTarget(self, action: #selector(didTapCreate), for: .touchUpInside)

        let restoreButton = ThemeButton()

        buttonsWrapper.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.top.equalTo(createButton.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        restoreButton.apply(style: .primaryGray)
        restoreButton.setTitle("welcome.restore_wallet".localized, for: .normal)
        restoreButton.addTarget(self, action: #selector(didTapRestore), for: .touchUpInside)

        let privacyButton = UIButton()

        buttonsWrapper.addSubview(privacyButton)
        privacyButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(restoreButton.snp.bottom).offset(CGFloat.margin6x)
            maker.height.equalTo(24)
        }

        privacyButton.titleLabel?.font = .subhead2
        privacyButton.setTitleColor(.themeLeah, for: .normal)
        privacyButton.setTitleColor(.themeGray50, for: .highlighted)
        privacyButton.setTitleColor(.themeGray50, for: .disabled)
        privacyButton.setBackgroundColor(color: .themeLawrence, forState: .normal)
        privacyButton.contentEdgeInsets.left = .margin3x
        privacyButton.contentEdgeInsets.right = .margin3x
        privacyButton.cornerRadius = .cornerRadius3x

        privacyButton.setTitle("welcome.privacy_settings".localized, for: .normal)
        privacyButton.addTarget(self, action: #selector(didTapPrivacy), for: .touchUpInside)

        buttonsWrapper.addSubview(versionLabel)
        versionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(privacyButton.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.centerX.equalToSuperview()
        }

        versionLabel.textColor = .themeGray
        versionLabel.font = .caption

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    @objc func didTapCreate() {
        delegate.didTapCreate()
    }

    @objc func didTapRestore() {
        delegate.didTapRestore()
    }

    @objc func didTapPrivacy() {
        delegate.didTapPrivacy()
    }

    @objc private func onTapSkip() {
        showWelcome()
    }

    @objc private func onTapNextButton() {
        if pageControl.currentPage < pageControl.numberOfPages - 1 {
            scrollView.setContentOffset(CGPoint(x: scrollView.width * CGFloat(pageControl.currentPage + 1), y: 0), animated: true)
        } else {
            showWelcome()
        }
    }

    private func setup(button: UIButton) {
        button.setTitleColor(.themeLeah, for: .normal)
        button.setTitleColor(.themeGray50, for: .highlighted)
        button.titleLabel?.font = .headline2
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: .margin6x, bottom: 0, right: .margin6x)
    }

    private func onSwitchSlide(index: Int) {
        let lastSlide = index == pageControl.numberOfPages - 1

        skipButton.set(hidden: lastSlide, animated: true, duration: 0.2)
    }

    private func showWelcome() {
        let animationDuration: TimeInterval = 0.4

        if pageIndex == 0 {
            logoWrapper.isHidden = true
            buttonsWrapper.isHidden = true
            logoWrapper.snp.remakeConstraints { maker in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalToSuperview().dividedBy(2)
            }
            buttonsWrapper.snp.remakeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(logoWrapper.snp.bottom)
                maker.bottom.equalTo(view.safeAreaLayoutGuide)
            }
            view.layoutIfNeeded()

            scrollView.set(hidden: true, animated: true, duration: animationDuration)
            bottomWrapperBackground.set(hidden: true, animated: true, duration: animationDuration)
            bottomWrapper.set(hidden: true, animated: true, duration: animationDuration)
            buttonsWrapper.set(hidden: false, animated: true, duration: animationDuration)

            imageViews[0].snp.remakeConstraints { maker in
                maker.edges.equalTo(logoImageView)
            }
        } else {
            logoWrapper.snp.remakeConstraints { maker in
                maker.leading.equalTo(view.snp.trailing)
                maker.leading.trailing.equalTo(logoImageView)
                maker.top.equalToSuperview()
                maker.height.equalToSuperview().dividedBy(2)
            }
            buttonsWrapper.snp.remakeConstraints { maker in
                maker.leading.equalTo(view.snp.trailing)
                maker.top.equalTo(logoWrapper.snp.bottom)
                maker.bottom.equalTo(view.safeAreaLayoutGuide)
            }
            view.layoutIfNeeded()

            wrapperView.set(hidden: true, animated: true, duration: animationDuration)
            scrollView.set(hidden: true, animated: true, duration: animationDuration)
            bottomWrapperBackground.set(hidden: true, animated: true, duration: animationDuration)
            bottomWrapper.set(hidden: true, animated: true, duration: animationDuration)

            logoWrapper.snp.remakeConstraints { maker in
                maker.leading.top.trailing.equalToSuperview()
                maker.height.equalToSuperview().dividedBy(2)
            }

            buttonsWrapper.snp.remakeConstraints { maker in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(logoWrapper.snp.bottom)
                maker.bottom.equalTo(view.safeAreaLayoutGuide)
            }
        }

        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            if self.pageIndex == 0 {
                self.logoWrapper.isHidden = false
                self.wrapperView.isHidden = true
            }
        })
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
            }
        }
    }

}

extension WelcomeScreenViewController: IWelcomeScreenView {

    func set(appVersion: String) {
        versionLabel.text = "version".localized(appVersion)
    }

}

extension WelcomeScreenViewController {

    private struct Slide {
        let title: String?
        let description: String
        let image: String
    }

}
