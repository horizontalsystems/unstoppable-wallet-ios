import Kingfisher
import MessageUI
import SwiftUI

struct MainSettingsView: View {
    @StateObject var viewModel = MainSettingsViewModel()
    @Environment(\.openURL) var openURL

    @State private var manageWalletsPresented = false
    @State private var walletConnectPresented = false

    @StateObject var walletConnectVerificationModel = WalletConnectVerificationModel(
        accountManager: Core.shared.accountManager,
        cloudBackupManager: Core.shared.cloudBackupManager
    )

    @State private var currentSlideIndex: Int = 0
    @State private var isFirstAppear = true

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin12) {
                slider()

                VStack(spacing: 0) {
                    ListSection {
                        manageWallets()
                        blockchainSettings()
                        security()
                        privacy()
                        dAppConnection()
                        // tonConnect()
                    }

                    Spacer().frame(height: .margin32)

                    ListSection {
                        contacts()
                    }

                    Spacer().frame(height: .margin32)

                    ListSection {
                        appSettings()
                        subscription()
                        backupManager()
                    }

                    Spacer().frame(height: .margin24)

                    VStack(spacing: 0) {
                        SectionHeader(image: Image.premiumIcon, text: ComponentText(text: "subscription.premium.label".localized, colorStyle: .yellow), horizontalInsets: .margin16)

                        ListSection {
                            vipSupport()
                            addressChecker()
                        }
                        .modifier(ThemeListStyleModifier(themeListStyle: .borderedPremium, selected: true))
                    }

                    Spacer().frame(height: .margin32)

                    ListSection {
                        aboutApp()
                        rateUs()
                        tellFriend()
                        faq()
                        academy()
                    }

                    Spacer().frame(height: .margin24)

                    VStack(spacing: 0) {
                        ListSectionHeader(text: "settings.social_networks.label".localized)

                        ListSection {
                            telegram()
                            twitter()
                        }
                    }

                    // Spacer().frame(height: .margin32)

                    // ListSection {
                    //     donate()
                    // }

                    Spacer().frame(height: .margin32)

                    footer()

                    if viewModel.showTestSwitchers {
                        Spacer().frame(height: .margin32)
                        testSwitchersSection()
                    }
                }
                .padding(.padding16)
            }
            .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin32, trailing: 0))
        }
        .navigationDestination(isPresented: $walletConnectPresented) {
            WalletConnectListView()
                .navigationTitle("wallet_connect_list.title".localized)
                .ignoresSafeArea()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .walletConnect))
                }
        }
    }

    @ViewBuilder private func slider() -> some View {
        VStack(spacing: 0) {
            TabView(selection: $currentSlideIndex) {
                ForEach(0 ..< viewModel.slides.count, id: \.self) { index in
                    ZStack {
                        slide(slide: viewModel.slides[index])
                            .frame(height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous))
                    }
                    .padding(.horizontal, .margin16)
                    .tag(index)
                }
            }
            .frame(height: 130)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            HStack(spacing: .margin4) {
                ForEach(0 ..< viewModel.slides.count, id: \.self) { index in
                    Capsule()
                        .fill(currentSlideIndex == index ? Color.themeJacob : Color.themeBlade)
                        .frame(width: 20, height: 4)
                }
            }
            .frame(height: .margin32)
        }
        .onAppear {
            guard !isFirstAppear else {
                isFirstAppear = false
                return
            }

            currentSlideIndex = PremiumFactory.forceShowingPremium ? 0 : (currentSlideIndex + 1) % viewModel.slides.count
        }
    }

    @ViewBuilder private func slide(slide: MainSettingsViewModel.Slide) -> some View {
        switch slide {
        case .premium:
            PremiumFactory.slide(offer: viewModel.introductoryOffer)
                .onTapGesture {
                    Coordinator.shared.presentPurchase(page: .settings, trigger: .banner)
                }
        case .miniApp:
            miniAppSlide()
                .onTapGesture {
                    let appUrl = URL(string: "tg://resolve?domain=\(AppConfig.appTokenTelegramAccount)&startapp")!
                    let webUrl = URL(string: "https://t.me/\(AppConfig.appTokenTelegramAccount)?startapp")!

                    if UIApplication.shared.canOpenURL(appUrl) {
                        openURL(appUrl)
                    } else {
                        Coordinator.shared.present(url: webUrl)
                    }
                }
        }
    }

    @ViewBuilder private func miniAppSlide() -> some View {
        ZStack(alignment: .trailing) {
            GeometryReader { geometry in
                Image("banner_mini_app")
                    .clipped()
                    .frame(width: geometry.size.width, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: .margin4) {
                Text("mini_app.cell.title".localized).textHeadline1(color: .themeYellow)
                Spacer(minLength: 0)
                Text("mini_app.cell.description".localized).textSubhead1(color: .themeLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: 185))
        }
        .background(Color.themeDarker)
    }

    @ViewBuilder private func manageWallets() -> some View {
        NavigationRow(spacing: .margin8, destination: {
            ManageAccountsView()
        }) {
            HStack(spacing: .margin16) {
                ThemeImage("wallet", size: .iconSize24)
                Text("settings.manage_accounts".localized).textBody()
            }

            Spacer()

            if viewModel.manageWalletsAlert {
                Image.warningIcon
            }

            Image.disclosureIcon
        }
    }

    @ViewBuilder private func blockchainSettings() -> some View {
        NavigationRow(destination: {
            BlockchainSettingsModule.view()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .blockchainSettings))
                }
        }) {
            ThemeImage("box", size: .iconSize24)
            Text("settings.blockchain_settings".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func security() -> some View {
        NavigationRow(spacing: .margin8, destination: {
            SecuritySettingsView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .security))
                }
        }) {
            HStack(spacing: .margin16) {
                ThemeImage("shield", size: .iconSize24)
                Text("settings.security".localized).textBody()
            }

            Spacer()

            if viewModel.securityAlert {
                Image.warningIcon
            }

            Image.disclosureIcon
        }
    }

    @ViewBuilder private func privacy() -> some View {
        NavigationRow(destination: {
            PrivacyPolicyView(config: .privacy)
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .privacy))
                }
        }) {
            ThemeImage("lock", size: .iconSize24)
            Text("settings.privacy".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func dAppConnection() -> some View {
        ClickableRow(spacing: .margin8) {
            walletConnectVerificationModel.handle {
                walletConnectPresented = true
            }
        } content: {
            HStack(spacing: .margin16) {
                ThemeImage("link", size: .iconSize24)
                Text("settings.dapp_connection".localized).textBody()
            }

            Spacer()

            if viewModel.walletConnectPendingRequestCount > 0 {
                BadgeViewNew("\(viewModel.walletConnectPendingRequestCount)") // TODO: use different badge
            } else if viewModel.walletConnectSessionCount > 0 {
                Text("\(viewModel.walletConnectSessionCount)").textSubhead1()
            }

            Image.disclosureIcon
        }
    }

    @ViewBuilder private func tonConnect() -> some View {
        NavigationRow(destination: {
            TonConnectListView()
        }) {
            HStack(spacing: .margin16) {
                Image("ton_connect_24").themeIcon()
                Text("TON Connect").textBody()
            }
            Spacer()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func appSettings() -> some View {
        NavigationRow(destination: {
            AppearanceView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .appearance))
                }
        }) {
            ThemeImage("uw_logo", size: .iconSize24)
            Text("settings.appearance".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func subscription() -> some View {
        NavigationRow(destination: {
            PurchaseListView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .subscription))
                }
        }) {
            ThemeImage("premium", size: .iconSize24)
            Text("subscription.title".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func contacts() -> some View {
        ClickableRow(spacing: .margin8) {
            Coordinator.shared.present { _ in
                ContactBookView(mode: .edit, presented: true)
                    .ignoresSafeArea()
                    .onFirstAppear {
                        stat(page: .settings, event: .open(page: .contacts))
                    }
            }
        } content: {
            HStack(spacing: .margin16) {
                ThemeImage("user", size: .iconSize24)
                Text("contacts.title".localized).textBody()
            }

            Spacer()

            if viewModel.iCloudUnavailable {
                Image.warningIcon
            }

            Image.disclosureIcon
        }
    }

    @ViewBuilder private func backupManager() -> some View {
        NavigationRow(destination: {
            BackupManagerView()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .backupManager))
                }
        }) {
            ThemeImage("cloud", size: .iconSize24)
            Text("settings.backup_manager".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func premiumHeader() -> some View {
        HStack(spacing: 6) {
            Image("star_filled_16").themeIcon(color: .themeJacob)
            Text("subscription.premium.label".localized).themeSubhead1(color: .themeJacob)
        }
        .padding(.horizontal, .margin16)
        .frame(height: .margin32)
    }

    @ViewBuilder private func vipSupport() -> some View {
        ClickableRow(action: {
            Coordinator.shared.performAfterPurchase(premiumFeature: .prioritySupport, page: .settings, trigger: .vipSupport) {
                let appUrl = URL(string: "tg://message?slug=\(AppConfig.appTelegramSupportSlug)")!
                let webUrl = URL(string: "https://t.me/m/\(AppConfig.appTelegramSupportSlug)")!

                if UIApplication.shared.canOpenURL(appUrl) {
                    openURL(appUrl)
                } else {
                    Coordinator.shared.present(url: webUrl)
                }

                stat(page: .settings, event: .open(page: .vipSupport))
            }
        }) {
            ThemeImage("support", size: .iconSize24, colorStyle: .yellow)
            Text("purchases.priority_support".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func addressChecker() -> some View {
        ClickableRow(action: {
            Coordinator.shared.performAfterPurchase(premiumFeature: .scamProtection, page: .settings, trigger: .vipSupport) {
                Coordinator.shared.present { isPresented in
                    CheckAddressView(isPresented: isPresented)
                        .onFirstAppear {
                            stat(page: .settings, event: .open(page: .addressChecker))
                        }
                }
            }
        }) {
            ThemeImage("radar", size: .iconSize24, colorStyle: .yellow)
            Text("address_checker.title".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func aboutApp() -> some View {
        NavigationRow(spacing: .margin8, destination: {
            AboutModule.view()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .aboutApp))
                }
        }) {
            HStack(spacing: .margin16) {
                ThemeImage("information", size: .iconSize24)
                Text("settings.about_app.title".localized).textBody()
            }

            Spacer()

            if viewModel.aboutAlert {
                Image.warningIcon
            }

            Image.disclosureIcon
        }
    }

    @ViewBuilder private func rateUs() -> some View {
        ClickableRow(action: {
            viewModel.rateApp()
            stat(page: .settings, event: .open(page: .rateUs))
        }) {
            ThemeImage("star", size: .iconSize24)
            Text("settings.rate_us".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func tellFriend() -> some View {
        ClickableRow(action: {
            Coordinator.shared.present { _ in
                ActivityView(activityItems: ["settings_tell_friends.text".localized + "\n" + AppConfig.appWebPageLink])
            }
            stat(page: .settings, event: .open(page: .tellFriends))
        }) {
            ThemeImage("arrow_out", size: .iconSize24)
            Text("settings.tell_friends".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func faq() -> some View {
        NavigationRow(destination: {
            FaqView()
                .navigationTitle("faq.title".localized)
                .ignoresSafeArea()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .faq))
                }
        }) {
            ThemeImage("message", size: .iconSize24)
            Text("settings.faq".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func academy() -> some View {
        NavigationRow(destination: {
            EducationView().onFirstAppear {
                stat(page: .settings, event: .open(page: .education))
            }
        }) {
            ThemeImage("book", size: .iconSize24)
            Text("education.title".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func telegram() -> some View {
        ClickableRow(action: {
            let appUrl = URL(string: "tg://resolve?domain=\(AppConfig.appTelegramAccount)")!
            let webUrl = URL(string: "https://t.me/\(AppConfig.appTelegramAccount)")!

            if UIApplication.shared.canOpenURL(appUrl) {
                openURL(appUrl)
            } else {
                Coordinator.shared.present(url: webUrl)
            }

            stat(page: .settings, event: .open(page: .externalTelegram))
        }) {
            ThemeImage("telegram_logo", size: .iconSize24)
            Text("Telegram").themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func twitter() -> some View {
        ClickableRow(action: {
            let account = AppConfig.appTwitterAccount

            if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
                UIApplication.shared.open(appUrl)
            } else {
                Coordinator.shared.present(url: "https://twitter.com/\(account)")
            }

            stat(page: .settings, event: .open(page: .externalTwitter))
        }) {
            ThemeImage("x_logo", size: .iconSize24)
            Text("Twitter").themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func donate() -> some View {
        ClickableRow(action: {
            Coordinator.shared.present { isPresented in
                DonateTokenListView(isPresented: isPresented)
            }
            stat(page: .settings, event: .open(page: .donate))
        }) {
            Image("heart_24").themeIcon()
            Text("settings.donate.title".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func footer() -> some View {
        VStack(spacing: .margin32) {
            VStack(spacing: 0) {
                Text("\(AppConfig.appName.uppercased()) \(viewModel.appVersion)")
                    .textCaption()
                    .padding(.bottom, .margin8)

                HorizontalDivider()

                Text("settings.info_subtitle".localized)
                    .textMicro()
                    .padding(.top, .margin4)
            }
            .fixedSize(horizontal: true, vertical: false)

            Image("HS Logo Image")
                .onTapGesture {
                    Coordinator.shared.present(url: AppConfig.companyWebPageLink)
                    stat(page: .settings, event: .open(page: .externalCompanyWebsite))
                }
        }
    }

    @ViewBuilder private func testSwitchersSection() -> some View {
        ListSection {
            ListRow {
                Toggle(isOn: $viewModel.forceEnableSwap) {
                    Text("Force Enable Swap").themeBody()
                }
                .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
            }

            ListRow {
                Toggle(isOn: $viewModel.emulatePurchase) {
                    Text("Emulate Purchase").themeBody()
                }
                .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
            }

            ListRow {
                Toggle(isOn: $viewModel.testNetEnabled) {
                    Text("TestNet Enabled").themeBody()
                }
                .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
            }

            ListRow {
                Toggle(isOn: $viewModel.mayaStagenetEnabled) {
                    Text("Maya Stagenet Enabled").themeBody()
                }
                .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
            }

            row(
                title: "AML checking result".localized,
                subtitle: "Oerride checking result from serer".localized,
                value: viewModel.debuggingAmlResult?.rawValue ?? "clear",
                action: {
                    Coordinator.shared.present(type: .alert) { isPresented in
                        OptionAlertView(
                            title: "AML Result".localized,
                            viewItems: [.init(text: "clear".localized, selected: viewModel.debuggingAmlResult == nil)] +
                                MultiSwapViewModel.AmlRiskResult.allCases.map {
                                    AlertViewItem(text: $0.rawValue, selected: viewModel.debuggingAmlResult == $0)
                                },
                            onSelect: { index in
                                switch index {
                                case 0: viewModel.debuggingAmlResult = nil
                                default: viewModel.debuggingAmlResult = MultiSwapViewModel.AmlRiskResult.allCases[index - 1]
                                }
                            },
                            isPresented: isPresented
                        )
                    }
                }
            )
        }
    }

    @ViewBuilder private func row(title: String, subtitle: String, value: String, action: (() -> Void)?) -> some View {
        let enabled = action != nil
        Cell(
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeText(
                    value,
                    style: .subheadSB,
                    colorStyle: enabled ? .primary : .secondary
                )
                .arrow(
                    style: .dropdown,
                    colorStyle: enabled ? .primary : .secondary
                )
            },
            action: action
        )
    }
}
