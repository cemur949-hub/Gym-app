import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ProgramsListView()
                .tabItem {
                    Label("Programs", systemImage: "dumbbell.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
        .tint(settings.accentColor)
    }
}
