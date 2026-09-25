import SwiftUI

struct ContentView: View {
    @StateObject private var desk = BoardDesk(store: LaneChartStore(defaults: .standard))
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !desk.ready {
                DesignTokens.bg
            } else if ReviewLaunch.screen == .onboarding || !desk.chart.onboardingComplete {
                OnboardingCover {
                    Task { await desk.finishOnboarding() }
                }
            } else {
                BoardRoot(desk: desk)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg.ignoresSafeArea())
        .task {
            await desk.prepare()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .inactive || phase == .background else { return }
            Task { await desk.flush() }
        }
    }
}

#Preview {
    ContentView()
}
