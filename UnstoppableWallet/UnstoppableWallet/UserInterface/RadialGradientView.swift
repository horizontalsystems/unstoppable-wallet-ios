import SwiftUI
import UIKit

final class RadialBackgroundView: UIView {
    private let hostingController: UIHostingController<MainSettingsPremiumBackgroundView>

    override init(frame: CGRect) {
        hostingController = UIHostingController(rootView: MainSettingsPremiumBackgroundView())

        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        hostingController = UIHostingController(rootView: MainSettingsPremiumBackgroundView())

        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        if let hostingView = hostingController.view {
            addSubview(hostingView)
            hostingView.backgroundColor = .clear

            hostingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
}

struct MainSettingsPremiumBackgroundView: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.themeTyler.ignoresSafeArea()

                ZStack {
                    Circle()
                        .fill(Color(hex: 0x003C74).opacity(0.4))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                        .offset(x: proxy.size.width / 2, y: -100)

                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(hex: 0xEDD716), location: 0.35),
                                    .init(color: Color(hex: 0xFF9B26).opacity(0.6), location: 0.7059),
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 75)
                        .offset(x: -proxy.size.width / 2, y: proxy.size.height - 100)
                }
            }
        }
    }
}
