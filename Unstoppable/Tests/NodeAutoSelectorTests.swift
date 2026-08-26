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
            currentId: "a"
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

    // MARK: - Unreachable results (nil responseTime)

    @Test func unreachableNodeIsNeverSelected() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [result("a", time: 0.5, height: 100), NodeAutoSelector.PingResult(id: "b", responseTime: nil, height: 100)],
            currentId: "a"
        )
        #expect(winner == nil)
    }

    @Test func unreachableHeightDoesNotRaiseTheTip() {
        // A dead node's height must not push reachable nodes past the lag threshold
        let winner = NodeAutoSelector.fastestNodeId(
            results: [
                NodeAutoSelector.PingResult(id: "x", responseTime: nil, height: UInt64.max),
                result("a", time: 0.5, height: 100),
                result("b", time: 0.2, height: 100),
            ],
            currentId: "a"
        )
        #expect(winner == "b")
    }

    @Test func unreachableCurrentGetsNoHysteresis() {
        let winner = NodeAutoSelector.fastestNodeId(
            results: [NodeAutoSelector.PingResult(id: "a", responseTime: nil, height: 100), result("b", time: 0.9, height: 100)],
            currentId: "a"
        )
        #expect(winner == "b")
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
