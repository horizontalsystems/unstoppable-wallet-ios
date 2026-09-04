import ReownWalletKit

struct WCNProposalItem {
    let proposal: Session.Proposal
    let verifyState: WCNVerifyState
    let blockchainProposals: [WCNBlockchainProposal]
}
