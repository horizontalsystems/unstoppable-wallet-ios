import Kingfisher
import MessageUI
import SwiftUI
import ThemeKit

struct MainSettingsView: View {
    @StateObject var viewModel = MainSettingsViewModel()

    @State private var manageWalletsPresented = false
    @State private var purchasesPresented = false
    @State private var supportPresented = false
    @State private var donatePresented = false
    @State private var addressCheckerPresented = false

    @StateObject var walletConnectViewModifierModel = WalletConnectViewModifierModel()

    @State private var shareText: String?

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
                        appSettings()
                        subscription()
                        contacts()
                        backupManager()
                    }

                    Spacer().frame(height: .margin24)

                    VStack(spacing: 0) {
                        premiumHeader()

                        ListSection {
                            vipSupport()
                            addressChecker()
                        }
                        .modifier(ThemeListStyleModifier(themeListStyle: .borderedLawrence, selected: true))
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

                    if AppConfig.donateEnabled {
                        Spacer().frame(height: .margin32)

                        ListSection {
                            donate()
                        }
                    }

                    Spacer().frame(height: .margin32)

                    footer()

                    if viewModel.showTestSwitchers {
                        Spacer().frame(height: .margin32)
                        testSwitchersSection()
                    }
                }
                .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))
            }
            .padding(EdgeInsets(top: .margin12, leading: 0, bottom: .margin32, trailing: 0))
        }
        .navigationTitle("settings.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $purchasesPresented) {
            PurchasesView()
        }
        .bottomSheet(isPresented: $supportPresented) {
            SupportView { telegramUrl in
                UrlManager.open(url: telegramUrl)
            }
            .onFirstAppear {
                stat(page: .settings, event: .open(page: .vipSupport))
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
                        .fill(currentSlideIndex == index ? Color.themeJacob : Color.themeSteel20)
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

            currentSlideIndex = (currentSlideIndex + 1) % viewModel.slides.count
        }
    }

    @ViewBuilder private func slide(slide: MainSettingsViewModel.Slide) -> some View {
        switch slide {
        case .premium:
            premiumSlide()
                .onTapGesture {
                    purchasesPresented = true
                }
        case .miniApp:
            miniAppSlide()
                .onTapGesture {
                    UrlManager.open(url: "https://t.me/\(AppConfig.appTokenTelegramAccount)/app")
                }
        }
    }

    @ViewBuilder private func premiumSlide() -> some View {
        ZStack(alignment: .trailing) {
            GeometryReader { geometry in
                Image("banner_premium")
                    .clipped()
                    .frame(width: geometry.size.width, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: .margin4) {
                Text("premium.cell.title".localized).textHeadline1(color: .themeYellow)
                Spacer()
                Text("premium.cell.description".localized).textSubhead1(color: .themeSteelLight)

                if let introductoryOffer = viewModel.introductoryOffer {
                    Text(introductoryOffer).textCaptionSB(color: .themeGreen)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: 138))
        }
        .background(Color.themeDarker)
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
                Spacer()
                Text("mini_app.cell.description".localized).textSubhead1(color: .themeSteelLight)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: 185))
        }
        .background(Color.themeDarker)
    }

    @ViewBuilder private func manageWallets() -> some View {
        NavigationRow(spacing: .margin8, destination: {
            ManageAccountsView(mode: .manage)
                .navigationTitle("settings_manage_keys.title".localized)
                .ignoresSafeArea()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .manageWallets))
                }
        }) {
            HStack(spacing: .margin16) {
                Image("wallet_24").themeIcon()
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
            Image("blocks_24").themeIcon()
            Text("settings.blockchain_settings".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func security() -> some View {
        NavigationRow(spacing: .margin8, destination: {
            SecuritySettingsModule.view()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .security))
                }
        }) {
            HStack(spacing: .margin16) {
                Image("shield_24").themeIcon()
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
            Image("lock_24").themeIcon()
            Text("settings.privacy".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func dAppConnection() -> some View {
        ClickableRow(spacing: .margin8) {
            walletConnectViewModifierModel.handle()
        } content: {
            HStack(spacing: .margin16) {
                Image("wallet_connect_24").themeIcon()
                Text("settings.dapp_connection".localized).textBody()
            }

            Spacer()

            if viewModel.walletConnectPendingRequestCount > 0 {
                BadgeViewNew(style: .medium, text: "\(viewModel.walletConnectPendingRequestCount)")
            } else if viewModel.walletConnectSessionCount > 0 {
                Text("\(viewModel.walletConnectSessionCount)").textSubhead1()
            }

            Image.disclosureIcon
        }
        .modifier(WalletConnectViewModifier(viewModel: walletConnectViewModifierModel, statPage: .settings))
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
            Image("uw_24").themeIcon()
            Text("settings.app_settings".localized).themeBody()
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
            Image("star_24").themeIcon()
            Text("subscription.title".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func contacts() -> some View {
        NavigationRow(spacing: .margin8, destination: {
            ContactBookView(mode: .edit)
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .contacts))
                }
        }) {
            HStack(spacing: .margin16) {
                Image("user_24").themeIcon()
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
                .navigationTitle("backup_app.backup_manager.title".localized)
                .ignoresSafeArea()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .backupManager))
                }
        }) {
            Image("icloud_24").themeIcon()
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
            if viewModel.activated(premiumFeature: .vipSupport) {
                supportPresented = true
            } else {
                purchasesPresented = true
            }
        }) {
            Image("support_2_24").themeIcon(color: .themeJacob)
            Text("purchases.vip_support".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func addressChecker() -> some View {
        ClickableRow(action: {
            if viewModel.activated(premiumFeature: .addressChecker) {
                addressCheckerPresented = true
            } else {
                purchasesPresented = true
            }
        }) {
            Image("radar_24").themeIcon(color: .themeJacob)
            Text("address_checker.title".localized).themeBody()
            Image.disclosureIcon
        }

        NavigationLink(
            isActive: $addressCheckerPresented,
            destination: {
                AddressCheckerView()
                    .onFirstAppear {
                        stat(page: .settings, event: .open(page: .addressChecker))
                    }
            }
        ) {
            EmptyView()
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
                Image("circle_information_24").themeIcon()
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
            Image("chart_24").themeIcon()
            Text("settings.rate_us".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func tellFriend() -> some View {
        ClickableRow(action: {
            shareText = "settings_tell_friends.text".localized + "\n" + AppConfig.appWebPageLink
            stat(page: .settings, event: .open(page: .tellFriends))
        }) {
            Image("share_1_24").themeIcon()
            Text("settings.tell_friends".localized).themeBody()
            Image.disclosureIcon
        }
        .sheet(item: $shareText) { shareText in
            ActivityView.view(activityItems: [shareText])
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
            Image("message_square_24").themeIcon()
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
            Image("academy_1_24").themeIcon()
            Text("education.title".localized).themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func telegram() -> some View {
        ClickableRow(action: {
            UrlManager.open(url: "https://t.me/\(AppConfig.appTelegramAccount)")
            stat(page: .settings, event: .open(page: .externalTelegram))
        }) {
            Image("telegram_24").themeIcon()
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
                UrlManager.open(url: "https://twitter.com/\(account)")
            }

            stat(page: .settings, event: .open(page: .externalTwitter))
        }) {
            Image("twitter_24").themeIcon()
            Text("Twitter").themeBody()
            Image.disclosureIcon
        }
    }

    @ViewBuilder private func donate() -> some View {
        ClickableRow(action: {
            donatePresented = true
        }) {
            Image("heart_24").themeIcon()
            Text("settings.donate.title".localized).themeBody()
            Image.disclosureIcon
        }
        .sheet(isPresented: $donatePresented) {
            DonateTokenListView()
                .ignoresSafeArea()
                .onFirstAppear {
                    stat(page: .settings, event: .open(page: .donate))
                }
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
                    UrlManager.open(url: AppConfig.companyWebPageLink)
                    stat(page: .settings, event: .open(page: .externalCompanyWebsite))
                }
        }
    }

    @ViewBuilder private func testSwitchersSection() -> some View {
        ListSection {
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
        }
    }
}
