import Foundation
import SwiftUI
import UIKit

/// Owns the live fold. Sheets reload from this desk after LaneFoldNotice.
@MainActor
final class BoardDesk: ObservableObject {
    enum Plate: String, Identifiable {
        case discover
        case ash
        case profile
        case settings

        var id: String { rawValue }
    }

    let store: LaneChartStore
    @Published private(set) var chart = LaneChart()
    @Published private(set) var load: ChartLoad = .restored
    @Published private(set) var writeFailed = false
    @Published private(set) var ready = false
    @Published var plate: Plate?
    @Published var pendingGrade: BurnMark?
    @Published var laneNote = ""
    @Published var burnLoading = false

    private var reviewApplied = false
    private let demoKey = "spl.demo.v1"

    init(store: LaneChartStore) {
        self.store = store
    }

    func prepare() async {
        #if targetEnvironment(simulator)
        await seedIfNeeded()
        #endif
        await reload()
        ready = true
    }

    func reload() async {
        chart = await store.snapshot()
        load = await store.load
        writeFailed = await store.lastWriteFailed
    }

    func finishOnboarding() async {
        await store.markOnboardingComplete()
        await store.flush()
        await reload()
    }

    func reopenOnboarding() async {
        await store.reopenOnboarding()
        await store.flush()
        await reload()
        plate = nil
    }

    func stash(_ stub: Stub) async {
        await store.stash(stub)
        await reload()
        laneNote = "Stashed \(stub.title) on the stack."
        plate = nil
    }

    func draw() async {
        let result = await store.draw()
        switch result {
        case .seated(let stub):
            laneNote = "\(stub.title) is on the gate. Burn it when the watch finishes."
            await reload()
        case .bare:
            laneNote = "The stack is bare. Stash a title before you draw."
        case .refusedWhileGated:
            laneNote = "The gate already holds a title. Burn it before you draw again."
        }
    }

    func burn() async {
        guard chart.gate != nil, !burnLoading else { return }
        burnLoading = true
        let result = await store.burn(on: Date())
        burnLoading = false
        switch result {
        case .marked(let mark):
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            laneNote = "Burned \(mark.title). Rate the burn."
            pendingGrade = mark
            await reload()
        case .refusedWhilePiled:
            laneNote = "Draw a title onto the gate before you burn."
        case .refusedWhileDark:
            laneNote = "The board has nothing on the gate to burn."
        }
    }

    func grade(_ stars: Int) async {
        guard let mark = pendingGrade else { return }
        _ = await store.grade(burnID: mark.id, stars: stars)
        await store.flush()
        pendingGrade = nil
        await reload()
    }

    func resetAll() async {
        await store.resetAllData()
        await reload()
        laneNote = "The board is clear."
        plate = nil
    }

    func flush() async {
        await store.flush()
    }

    func applyReviewIfNeeded() {
        guard !reviewApplied else { return }
        reviewApplied = true
        guard let surface = ReviewLaunch.screen else { return }
        switch surface {
        case .today, .board:
            plate = nil
        case .log, .ash:
            plate = .ash
        case .goals, .profile:
            plate = .profile
        case .discover:
            plate = .discover
        case .settings:
            plate = .settings
        case .onboarding:
            plate = nil
        }
    }

    #if targetEnvironment(simulator)
    private func seedIfNeeded() async {
        guard UserDefaults.standard.bool(forKey: demoKey) == false else { return }
        let current = await store.snapshot()
        guard current.stack.isEmpty, current.gate == nil, current.burnMarks.isEmpty else {
            UserDefaults.standard.set(true, forKey: demoKey)
            return
        }
        for stub in LocalShelf.titles {
            await store.stash(stub)
        }
        _ = await store.draw()
        await store.markOnboardingComplete()
        await store.flush()
        UserDefaults.standard.set(true, forKey: demoKey)
    }
    #endif
}
