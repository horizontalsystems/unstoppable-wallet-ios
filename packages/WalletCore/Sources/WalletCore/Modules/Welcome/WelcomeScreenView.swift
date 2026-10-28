import SwiftUI

struct WelcomeScreenView: View {
    private let onFinish: () -> Void

    @State private var scrollPositionId: Int? = 0
    @State private var splashVisible = true
    @State private var logoOpacity: Double = 0
    @State private var splashOpacity: Double = 1
    @State private var isFinishing = false
    @State private var contentOpacity: Double = 1

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    var body: some View {
        ZStack {
            Color.themeTyler.ignoresSafeArea()

            background

            GeometryReader { geo in
                let metrics = Metrics(size: geo.size)

                ZStack(alignment: .top) {
                    content(metrics: metrics)

                    overlay(metrics: metrics)
                        .allowsHitTesting(false)
                }
            }

            if splashVisible {
                splash
            }
        }
        .opacity(contentOpacity)
        .allowsHitTesting(!isFinishing)
        .task {
            await runSplashTimeline()
        }
    }

    private var currentPage: Int {
        scrollPositionId ?? 0
    }

    private var background: some View {
        GeometryReader { geo in
            ThemeImage(ComponentImage(image: "Intro - Background", contentMode: .fill), size: geo.size)
                .clipped()
        }
        .ignoresSafeArea()
    }

    private func content(metrics: Metrics) -> some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(Self.slides) { slide in
                        VStack(spacing: 0) {
                            Spacer().frame(height: metrics.spacerHeight)

                            ThemeImage(
                                ComponentImage(image: slide.image, contentMode: .fit),
                                size: CGSize(width: metrics.width, height: metrics.imageHeight)
                            )

                            Spacer().frame(height: 0.5 * metrics.spacerHeight)

                            Color.clear.frame(height: Self.pageControlHeight)

                            Spacer().frame(height: 0.5 * metrics.spacerHeight)

                            textBlock(for: slide, metrics: metrics)

                            Spacer(minLength: 0)
                        }
                        .containerRelativeFrame(.horizontal)
                        .frame(height: metrics.scrollHeight, alignment: .top)
                        .id(slide.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: $scrollPositionId)
            .scrollClipDisabled()
            .frame(height: metrics.scrollHeight)

            ThemeButton(text: "button.next".localized) {
                onTapNext()
            }
            .padding(.horizontal, .margin32)
            .padding(.bottom, .margin32)
        }
    }

    private func textBlock(for slide: Slide, metrics: Metrics) -> some View {
        VStack(spacing: .margin16) {
            ThemeText(slide.title, style: .title3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ThemeText(slide.description, style: .body, colorStyle: .secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, .margin48)
        .frame(width: metrics.width)
        .frame(minHeight: Self.textBlockHeight, alignment: .top)
        .visualEffect { content, proxy in
            let minX = proxy.frame(in: .scrollView).minX
            let width = max(proxy.size.width, 1)

            return content
                .offset(x: -minX)
                .opacity(max(0, 1 - abs(minX) / width))
        }
    }

    private func overlay(metrics: Metrics) -> some View {
        VStack(spacing: 0) {
            Spacer().frame(height: metrics.spacerHeight + metrics.imageHeight + 0.5 * metrics.spacerHeight)

            BarPageControlView(pageCount: Self.slides.count, currentPage: currentPage)

            Spacer()
        }
    }

    private var splash: some View {
        ZStack {
            Color.themeTyler

            VStack(spacing: Self.logoTitleSpacing) {
                ThemeImage(
                    ComponentImage(image: AppIcon.main.imageName, contentMode: .fill),
                    size: .size72
                )
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous))

                ThemeText(AppConfig.appName, style: .title2)
                    .multilineTextAlignment(.center)
            }
            .opacity(logoOpacity)
        }
        .ignoresSafeArea()
        .opacity(splashOpacity)
    }

    private func onTapNext() {
        if currentPage < Self.slides.count - 1 {
            withAnimation(.easeInOut) {
                scrollPositionId = currentPage + 1
            }
        } else {
            finish()
        }
    }

    private func finish() {
        guard !isFinishing else { return }
        isFinishing = true

        withAnimation(.easeInOut(duration: Self.finishDuration)) {
            contentOpacity = 0
        } completion: {
            onFinish()
        }
    }

    private func runSplashTimeline() async {
        try? await Task.sleep(for: .seconds(0.5))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            logoOpacity = 1
        }

        try? await Task.sleep(for: .seconds(1.5))
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.5)) {
            splashOpacity = 0
        }

        try? await Task.sleep(for: .seconds(0.5))
        guard !Task.isCancelled else { return }

        splashVisible = false
    }
}

extension WelcomeScreenView {
    private struct Slide: Identifiable {
        let id: Int
        let title: String
        let description: String
        let image: String

        init(page: Int, title: String, description: String, image: String) {
            id = page
            self.title = title
            self.description = description
            self.image = image
        }
    }

    private struct Metrics {
        let width: CGFloat
        let imageHeight: CGFloat
        let spacerHeight: CGFloat
        let scrollHeight: CGFloat

        init(size: CGSize) {
            width = size.width
            imageHeight = width / WelcomeScreenView.imageAspect

            let fixed = imageHeight + WelcomeScreenView.pageControlHeight + WelcomeScreenView.textBlockHeight + .heightButton + .margin32
            spacerHeight = max(0, (size.height - fixed) / 3)
            scrollHeight = 3 * spacerHeight + imageHeight + WelcomeScreenView.pageControlHeight + WelcomeScreenView.textBlockHeight
        }
    }

    private static let slides = [
        ("intro.unchain_assets", "Intro - Unchain Assets"),
        ("intro.go_borderless", "Intro - Go Borderless"),
        ("intro.stay_private", "Intro - Stay Private"),
    ].enumerated().map { page, slide in
        Slide(page: page, title: "\(slide.0).title".localized, description: "\(slide.0).description".localized, image: slide.1)
    }

    private static let pageControlHeight = BarPageControlView.barSize.height
    private static let textBlockHeight: CGFloat = 82
    private static let logoTitleSpacing: CGFloat = 28
    private static let finishDuration: TimeInterval = 0.3

    private static let imageAspect: CGFloat = 1125 / 1056
}
