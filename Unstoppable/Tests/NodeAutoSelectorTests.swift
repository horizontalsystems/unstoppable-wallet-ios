import Foundation
import Testing
@testable import WalletCore

struct NodeAutoSelectorTests {
    private func result(_ id: String, time: TimeInterval, height: UInt64) -> NodeAutoSelector.PingResult {
        NodeAutoSelector.PingResult(id: id, responseTime: time, height: height)
    }

    // MARK: - fastestNodeId policy

    @Test func emptyCandidatesYieldNothing() {
        let winner = NodeAutoSelector.fastestNodeId(results: [], currentId: "a")
        #expect(winner == nil)
    }

    @Test func picksFastestCandidate() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.5, height: 100), result("b", time: 0.2, height: 100)],
            currentId: "a"
        )
        #expect(winner == "b")
    }

    @Test func laggingNodeIsNeverSelected() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.5, height: 100), result("b", time: 0.1, height: 89)],
            currentId: "a"
        )
        #expect(winner == nil)
    }

    @Test func lagBoundaryIsInclusive() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.5, height: 100), result("b", time: 0.1, height: 90)],
            currentId: "a"
        )
        #expect(winner == "b")
    }

    @Test func hugeHeightDoesNotTrap() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.5, height: UInt64.max), result("b", time: 0.1, height: 100)],
            currentId: "b"
        )
        #expect(winner == nil)
    }

    @Test func fastestEqualsCurrentYieldsNothing() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.2, height: 100), result("b", time: 0.5, height: 100)],
            currentId: "a"
        )
        #expect(winner == nil)
    }

    @Test func hysteresisKeepsComparableCurrent() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.25, height: 100), result("b", time: 0.2, height: 100)],
            currentId: "a"
        )
        #expect(winner == nil)
    }

    @Test func meaningfullyFasterNodeWins() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.5, height: 100), result("b", time: 0.2, height: 100)],
            currentId: "a"
        )
        #expect(winner == "b")
    }

    @Test func deadCurrentIsSwitchedAwayFrom() {
        // current node absent from candidates (unreachable): hysteresis must not apply
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("b", time: 0.9, height: 100)],
            currentId: "a"
        )
        #expect(winner == "b")
    }

    // MARK: - Zcash candidate projection

    @Test func unreachableNodesAreNotCandidates() {
        let node = ZcashNode(name: "a", url: URL(string: "https://a.example:443")!)
        let candidates = ZcashNodeManager.candidates(from: [
            .init(node: node, responseTime: nil, height: 0),
            .init(node: node, responseTime: 0.2, height: 50),
        ])
        #expect(candidates.count == 1)
        #expect(candidates[0].responseTime == 0.2)
        #expect(candidates[0].height == 50)
    }

    @Test func negativeHeightClampsToZero() {
        let node = ZcashNode(name: "a", url: URL(string: "https://a.example:443")!)
        let candidates = ZcashNodeManager.candidates(from: [
            .init(node: node, responseTime: 0.2, height: -5),
        ])
        #expect(candidates[0].height == 0)
    }

    // MARK: - Backup codec

    @Test func backupRoundTripKeepsAutoSelect() throws {
        let backup = ZcashNodeManager.NodeBackup(selected: [], custom: [], autoSelect: false)
        let data = try JSONEncoder().encode(backup)
        let decoded = try JSONDecoder().decode(ZcashNodeManager.NodeBackup.self, from: data)
        #expect(decoded.autoSelect == false)

        let json = String(data: data, encoding: .utf8) ?? ""
        #expect(json.contains("auto_select"))
    }

    @Test func oldBackupWithoutFlagDecodesNil() throws {
        let data = Data("{\"selected\":[],\"custom\":[]}".utf8)
        let decoded = try JSONDecoder().decode(ZcashNodeManager.NodeBackup.self, from: data)
        #expect(decoded.autoSelect == nil)
    }
}
