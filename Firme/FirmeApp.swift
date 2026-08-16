import SwiftUI
import SwiftData

@main
struct FirmeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [UserProfile.self, PauseAttempt.self, CustomSite.self, FallLog.self])
    }
}
