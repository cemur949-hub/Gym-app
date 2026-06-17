import SwiftUI

@main
struct GymTrackerApp: App {
    @StateObject private var store    = WorkoutStore()
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(settings)
                .preferredColorScheme(.dark)
        }
    }
}
