import Foundation
import SwiftUI

// Routes module events to screens; the only place UI knows how requests and proposals are shown
enum WCNPresenter {
    static func pair(uri: String) {
        WCNLog.log("presenter pair: manager=\(Core.shared.walletConnectNew != nil) account=\(Core.shared.accountManager.activeAccount != nil)")
        guard let manager = Core.shared.walletConnectNew else { return }
        guard Core.shared.accountManager.activeAccount != nil else {
            presentNoAccount()
            return
        }

        Task {
            do {
                let kit = try manager.kit()
                await MainActor.run {
                    WCNLog.log("presenter pair: show waiting hud")
                    HudHelper.instance.show(banner: .waitingForSession)
                }
                try await kit.pair(uri: uri)
                WCNLog.log("presenter pair: paired")
            } catch let error as WCNPairingService.PairingError where error != .proposalTimeout {
                await MainActor.run {
                    WCNLog.log("presenter pair: pairing error \(error)")
                    hideWaiting()
                    presentInvalidUrl(error: error)
                }
            } catch {
                await MainActor.run {
                    WCNLog.log("presenter pair: error \(error)")
                    hideWaiting()
                    HudHelper.instance.show(banner: .error(string: error.smartDescription))
                }
            }
        }
    }

    static func present(proposal item: WCNProposalItem) {
        WCNLog.log("presenter: present proposal \(item.proposal.id) verify=\(item.verifyState) chains=\(item.blockchainProposals.count)")
        hideWaiting()
        let viewModel = WCNConnectViewModel(item: item)
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            WCNConnectView(viewModel: viewModel, isPresented: isPresented)
        } onDismiss: {
            // reject on any dismissal (swipe/cancel); a no-op once connect finished (guarded by `finished`)
            viewModel.reject()
        }
    }

    static func present(request item: WCNRequestItem) {
        WCNLog.log("presenter: present request \(item.requestId.string) result=\(item.result)")
        switch item.result {
        case let .transaction(_, sendData):
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                WCNSendSheetView(item: item, sendData: sendData, isPresented: isPresented)
            } onDismiss: {
                Core.shared.walletConnectNew?.startedKit?.notifyRequestDismissed()
            }
        case .signMessage:
            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                WCNSignMessageSheetView(item: item, isPresented: isPresented)
            } onDismiss: {
                Core.shared.walletConnectNew?.startedKit?.notifyRequestDismissed()
            }
        case .direct, .rejected:
            ()
        }
    }

    static func presentInvalidUrl(error: WCNPairingService.PairingError) {
        let description = error == .expiredUri ? "wallet_connect.error.expired_url".localized : "wallet_connect.error.invalid_url.description".localized
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.error, title: "wallet_connect.error.invalid_url.title".localized),
                    .text(text: description),
                    .buttonGroup(.init(buttons: [
                        .init(style: .gray, title: "button.cancel".localized) {
                            isPresented.wrappedValue = false
                        },
                        .init(style: .yellow, title: "button.try_again".localized) {
                            isPresented.wrappedValue = false
                            presentScanner()
                        },
                    ], alignment: .horizontal)),
                ]
            )
        }
    }

    static func presentRequestFailed() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.error, title: "wallet_connect.error.request_failed.title".localized),
                    .text(text: "wallet_connect.error.request_failed.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .gray, title: "button.close".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        }
    }

    static func presentDisconnect(dAppName: String, host: String, iconUrl: String?, onDisconnect: @escaping () -> Void) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .custom(view: AnyView(WCNDAppTitleView(iconUrl: iconUrl, title: "wallet_connect.list.disconnect.title".localized(dAppName), showGrabber: true))),
                    .subtitle(text: host),
                    .text(text: "wallet_connect.list.disconnect.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .gray, title: "wallet_connect.button_disconnect".localized) {
                            isPresented.wrappedValue = false
                            onDisconnect()
                        },
                    ])),
                ]
            )
        }
    }

    static func presentNoAccount() {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(icon: ThemeImage.warning, title: "wallet_connect.title".localized),
                    .warning(text: "wallet_connect.no_account.description".localized),
                    .buttonGroup(.init(buttons: [
                        .init(style: .yellow, title: "button.ok".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ]
            )
        }
    }

    private static func presentScanner() {
        Coordinator.shared.present { isPresented in
            ScanQrViewNew(reportAfterDismiss: true, isPresented: isPresented) { uri in
                pair(uri: uri)
            }
            .ignoresSafeArea()
        }
    }

    private static func hideWaiting() {
        WCNLog.log("presenter hideWaiting: hud tag=\(HUD.instance.tag ?? "nil")")
        if HUD.instance.tag == HudHelper.BannerType.waitingForSessionKey {
            HudHelper.instance.hide()
        }
    }
}
