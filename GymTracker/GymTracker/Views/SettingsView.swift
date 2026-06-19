import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings

    @State private var showClearConfirm  = false
    @State private var showExportSheet   = false
    @State private var showImportSheet   = false
    @State private var exportText        = ""
    @State private var importText        = ""
    @State private var importError: String?
    @State private var showImportSuccess = false
    @State private var showImportError   = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        appHeaderSection
                        appearanceSection
                        unitsSection
                        dataSection
                        aboutSection
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 40)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showExportSheet) { ExportSheet(json: exportText) }
        .sheet(isPresented: $showImportSheet) {
            ImportSheet(text: $importText) { json in
                do {
                    try store.importJSON(json)
                    showImportSuccess = true
                } catch {
                    importError = error.localizedDescription
                    showImportError = true
                }
            }
        }
        .alert("Import Successful", isPresented: $showImportSuccess) { Button("OK") {} }
        message: { Text("Workouts imported successfully.") }
        .alert("Import Failed", isPresented: $showImportError, presenting: importError) { _ in
            Button("OK") {}
        } message: { err in Text(err) }
        .alert("Clear All Data?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) { store.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete all programs and workouts.") }
    }

    // MARK: - Header
    private var appHeaderSection: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18).fill(settings.accentColor).frame(width: 64, height: 64)
                Image(systemName: "dumbbell.fill").font(.system(size: 28)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("GymTracker").font(.title2.bold()).foregroundColor(.white)
                Text("Your personal workout companion").font(.caption).foregroundColor(.textSecondary)
                Text("\(store.programs.count) programs · \(totalWorkouts) workouts").font(.caption).foregroundColor(.textSecondary)
            }
            Spacer()
        }
        .padding(20).background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var totalWorkouts: Int { store.programs.reduce(0) { $0 + $1.workouts.count } }

    // MARK: - Appearance
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Accent Color").font(.subheadline).foregroundColor(.white)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                    ForEach(AppSettings.presetColors, id: \.hex) { preset in
                        Button {
                            withAnimation(.spring(response: 0.2)) { settings.accentColorHex = preset.hex }
                        } label: {
                            ZStack {
                                Circle().fill(Color(hex: preset.hex)).frame(width: 44, height: 44)
                                if settings.accentColorHex == preset.hex {
                                    Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }

            Divider().background(Color.divider)

            SettingsRow(icon: "textformat.size", iconColor: settings.accentColor, label: "Text Size") {
                Picker("", selection: $settings.fontSize) {
                    ForEach(AppSettings.FontSize.allCases) { size in Text(size.rawValue).tag(size) }
                }
                .pickerStyle(.segmented).frame(width: 180)
            }

            Divider().background(Color.divider)

            SettingsRow(icon: "timer", iconColor: .blue, label: "Show Rest Times") {
                Toggle("", isOn: $settings.showRestTimes).tint(settings.accentColor)
            }
        }
    }

    // MARK: - Units
    private var unitsSection: some View {
        SettingsSection(title: "Units") {
            SettingsRow(icon: "scalemass.fill", iconColor: .green, label: "Weight Unit") {
                Picker("", selection: $settings.weightUnit) {
                    ForEach(AppSettings.WeightUnit.allCases) { unit in Text(unit.label).tag(unit) }
                }
                .pickerStyle(.segmented).frame(width: 120)
            }
        }
    }

    // MARK: - Data
    private var dataSection: some View {
        SettingsSection(title: "Data") {
            Button {
                exportText = store.exportJSON() ?? "Error"
                showExportSheet = true
            } label: {
                SettingsRowLabel(icon: "square.and.arrow.up", iconColor: .blue, label: "Export Workouts")
            }
            Divider().background(Color.divider)
            Button { showImportSheet = true } label: {
                SettingsRowLabel(icon: "square.and.arrow.down", iconColor: .green, label: "Import Workouts")
            }
            Divider().background(Color.divider)
            Button { showClearConfirm = true } label: {
                SettingsRowLabel(icon: "trash", iconColor: .red, label: "Clear All Data", labelColor: .red)
            }
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRowLabel(icon: "info.circle", iconColor: .blue, label: "Version 1.0.0")
            Divider().background(Color.divider)
            SettingsRowLabel(icon: "hammer.fill", iconColor: settings.accentColor, label: "Built with SwiftUI")
        }
    }
}

// MARK: - Reusable Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.caption.bold()).foregroundColor(.textSecondary)
                .textCase(.uppercase).tracking(1).padding(.horizontal, 4).padding(.bottom, 8)
            VStack(spacing: 0) { content() }
                .padding(16).background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String; let iconColor: Color; let label: String
    @ViewBuilder let trailing: () -> Trailing
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.subheadline)
                .frame(width: 28, height: 28).background(iconColor.opacity(0.2))
                .foregroundStyle(iconColor).clipShape(RoundedRectangle(cornerRadius: 7))
            Text(label).font(.subheadline).foregroundColor(.white)
            Spacer()
            trailing()
        }
    }
}

struct SettingsRowLabel: View {
    let icon: String; let iconColor: Color; let label: String
    var labelColor: Color = .white
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.subheadline)
                .frame(width: 28, height: 28).background(iconColor.opacity(0.2))
                .foregroundStyle(iconColor).clipShape(RoundedRectangle(cornerRadius: 7))
            Text(label).font(.subheadline).foregroundColor(labelColor)
            Spacer()
            if labelColor == .white {
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.textSecondary)
            }
        }
    }
}

// MARK: - Export Sheet
struct ExportSheet: View {
    @Environment(\.dismiss) var dismiss
    let json: String
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    Text(json).font(.system(.caption, design: .monospaced))
                        .foregroundColor(.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                        .padding().background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 12)).padding()
                }
            }
            .navigationTitle("Export JSON").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: json, subject: Text("GymTracker Export")) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) { Button("Done") { dismiss() } }
            }
        }
    }
}

// MARK: - Import Sheet
struct ImportSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var text: String
    let onImport: (String) -> Void
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Paste exported GymTracker JSON below:")
                        .font(.subheadline).foregroundColor(.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text).frame(minHeight: 300).padding(12)
                            .background(Color.cardBackground).clipShape(RoundedRectangle(cornerRadius: 14))
                            .foregroundColor(.white).scrollContentBackground(.hidden).tint(.white)
                        if text.isEmpty {
                            Text("Paste JSON here...").foregroundColor(.textSecondary)
                                .padding(.horizontal, 16).padding(.top, 20).allowsHitTesting(false)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Import Workouts").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import") { onImport(text); dismiss() }.font(.headline).disabled(text.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }
}
