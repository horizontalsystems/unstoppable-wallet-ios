import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class WelcomeScreenViewController: ThemeViewController {
    private let scrollView = UIScrollView()
    private var textViews = [WelcomeTextView]()
    private let pageControl: BarPageControl

    private let logoWrapperView = UIView()
    private let logoView = UIView()

    private var pageIndex = 0

    private let slides = [
        Slide(title: "intro.unchain_assets.title".localized, description: "intro.unchain_assets.description".localized, image: "Intro - Unchain Assets"),
        Slide(title: "intro.go_borderless.title".localized, description: "intro.go_borderless.description".localized, image: "Intro - Go Borderless"),
        Slide(title: "intro.stay_private.title".localized, description: "intro.stay_private.description".localized, image: "Intro - Stay Private")
    ]

    override init() {
        pageControl = BarPageControl(barCount: slides.count)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let backgroundImageView = UIImageView()

        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(named: "Intro - Background")

        let topSpaceView = UIView()

        view.addSubview(topSpaceView)
        topSpaceView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
        }

        let middleUpperSpaceView = UIView()

        view.addSubview(middleUpperSpaceView)
        middleUpperSpaceView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(topSpaceView.snp.height).multipliedBy(0.5)
        }

        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(middleUpperSpaceView.snp.bottom)
        }

        pageControl.currentPage = 0

        let middleLowerSpaceView = UIView()

        view.addSubview(middleLowerSpaceView)
        middleLowerSpaceView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(pageControl.snp.bottom)
            maker.height.equalTo(topSpaceView.snp.height).multipliedBy(0.5)
        }

        let textWrapperView = UIView()

        view.addSubview(textWrapperView)
        textWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.equalTo(middleLowerSpaceView.snp.bottom)
            maker.height.equalTo(82)
        }

        let bottomSpaceView = UIView()

        view.addSubview(bottomSpaceView)
        bottomSpaceView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(textWrapperView.snp.bottom)
            maker.height.equalTo(topSpaceView.snp.height)
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.top.equalTo(topSpaceView)
            maker.bottom.equalTo(bottomSpaceView)
        }

        scrollView.delegate = self
        scrollView.contentSize = CGSize(width: view.width * CGFloat(slides.count), height: 0)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false

        for (index, slide) in slides.enumerated() {
            guard let image = UIImage(named: slide.image) else {
                continue
            }

            let imageView = UIImageView(image: image)
            scrollView.addSubview(imageView)
            imageView.snp.makeConstraints { maker in
                maker.leading.equalTo(view.width * CGFloat(index))
                maker.top.equalTo(topSpaceView.snp.bottom)
                maker.bottom.equalTo(middleUpperSpaceView.snp.top)
                maker.width.equalTo(view)
                maker.height.equalTo(view.width / (image.size.width / image.size.height))
            }

            let textView = WelcomeTextView(title: slide.title, description: slide.description)

            textWrapperView.addSubview(textView)
            textView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }

            textView.alpha = 0
            textViews.append(textView)
        }

        scrollViewDidScroll(scrollView)

        let startButton = PrimaryButton()

        view.addSubview(startButton)
        startButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin32)
            maker.top.equalTo(scrollView.snp.bottom)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin32)
        }

        startButton.set(style: .yellow)
        startButton.setTitle("intro.start".localized, for: .normal)
        startButton.addTarget(self, action: #selector(onTapStart), for: .touchUpInside)

        view.addSubview(logoWrapperView)
        logoWrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        logoWrapperView.backgroundColor = .themeTyler

        logoWrapperView.addSubview(logoView)
        logoView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        logoView.alpha = 0

        let logoImageView = UIImageView()

        logoView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview()
            maker.size.equalTo(72)
        }

        logoImageView.image = UIImage(named: AppIcon.main.imageName)
        logoImageView.contentMode = .scaleAspectFill
        logoImageView.cornerRadius = .cornerRadius16
        logoImageView.layer.cornerCurve = .continuous
        logoImageView.clipsToBounds = true

        let logoTitleLabel = UILabel()

        logoView.addSubview(logoTitleLabel)
        logoTitleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(logoImageView.snp.bottom).offset(28)
            maker.bottom.equalToSuperview()
        }

        logoTitleLabel.numberOfLines = 0
        logoTitleLabel.textAlignment = .center
        logoTitleLabel.font = .title2
        logoTitleLabel.textColor = .themeLeah
        logoTitleLabel.text = "Unstoppable"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.animate(withDuration: 0.5, delay: 0.5, animations: { [weak self] in
            self?.logoView.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 1, animations: { [weak self] in
                self?.logoWrapperView.alpha = 0
            }, completion: { [weak self] _ in
                self?.logoWrapperView.removeFromSuperview()
            })
        })
    }

    @objc private func onTapStart() {
        UIApplication.shared.windows.first { $0.isKeyWindow }?.set(newRootController: MainModule.instance())
    }

}

extension WelcomeScreenViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageIndex = Int(round(scrollView.contentOffset.x / view.frame.width))

        if pageControl.currentPage != pageIndex {
            pageControl.currentPage = pageIndex
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

                textViews[i].alpha = 1 - percent
            } else {
                textViews[i].alpha = 0
            }
        }
    }

}

extension WelcomeScreenViewController {

    private struct Slide {
        let title: String
        let description: String
        let image: String
    }

}
