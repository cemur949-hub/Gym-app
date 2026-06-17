import SwiftUI

// MARK: - Programs List
struct ProgramsListView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings

    @State private var showingCreate = false
    @State private var editingProgram: WorkoutProgram?
    @State private var deleteTarget: WorkoutProgram?
    @State private var showDeleteAlert = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if store.programs.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(store.programs) { program in
                                NavigationLink(destination: ProgramDetailView(program: program)) {
                                    ProgramCard(program: program)
                                        .contextMenu {
                                            Button { editingProgram = program } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) {
                                                deleteTarget = program
                                                showDeleteAlert = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("My Programs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(settings.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                ProgramEditorSheet(program: nil)
            }
            .sheet(item: $editingProgram) { prog in
                ProgramEditorSheet(program: prog)
            }
            .alert("Delete Program?", isPresented: $showDeleteAlert, presenting: deleteTarget) { prog in
                Button("Delete", role: .destructive) {
                    withAnimation { store.deleteProgram(id: prog.id) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { prog in
                Text(""\(prog.name)" and all its workouts will be permanently deleted.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell")
                .font(.system(size: 60))
                .foregroundStyle(settings.accentColor.opacity(0.6))

            Text("No Programs Yet")
                .font(.title2).bold()
                .foregroundColor(.white)

            Text("Create your first workout program\nto start tracking your training.")
                .multilineTextAlignment(.center)
                .foregroundColor(.textSecondary)

            Button {
                showingCreate = true
            } label: {
                Label("Create Program", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(settings.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(32)
    }
}

// MARK: - Program Card
struct ProgramCard: View {
    @EnvironmentObject var settings: AppSettings
    let program: WorkoutProgram

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top accent bar
            Rectangle()
                .fill(program.color)
                .frame(height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.bottom, 14)

            // Emoji
            Text(program.emoji)
                .font(.system(size: 44))
                .padding(.bottom, 10)

            // Name
            Text(program.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            // Stats row
            HStack(spacing: 12) {
                statBadge(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(program.workouts.count)",
                    label: program.workouts.count == 1 ? "workout" : "workouts"
                )
            }
            .padding(.top, 8)

            if !program.description.isEmpty {
                Text(program.description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(program.color.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: program.color.opacity(0.15), radius: 12, x: 0, y: 4)
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(program.color)
            Text("\(value) \(label)")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Program Editor Sheet
struct ProgramEditorSheet: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let program: WorkoutProgram?

    @State private var name = ""
    @State private var description = ""
    @State private var emoji = "💪"
    @State private var colorHex = "FF6B35"
    @State private var showEmojiPicker = false

    private var isEditing: Bool { program != nil }

    private let presetEmojis = ["💪", "🔥", "⚡", "🏋️", "🎯", "💥", "🦾", "🏆", "⚔️", "🌊", "🧠", "🚀"]

    init(program: WorkoutProgram?) {
        self.program = program
        if let p = program {
            _name        = State(initialValue: p.name)
            _description = State(initialValue: p.description)
            _emoji       = State(initialValue: p.emoji)
            _colorHex    = State(initialValue: p.colorHex)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preview card
                        previewCard

                        // Emoji picker
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Emoji")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(presetEmojis, id: \.self) { e in
                                    Text(e)
                                        .font(.title2)
                                        .frame(width: 48, height: 48)
                                        .background(emoji == e ? Color(hex: colorHex).opacity(0.25) : Color.cardSurface)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(emoji == e ? Color(hex: colorHex) : Color.clear, lineWidth: 2)
                                        )
                                        .onTapGesture { emoji = e }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Name & description
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Details")
                            DarkTextField(placeholder: "Program name", text: $name)
                            DarkTextField(placeholder: "Description (optional)", text: $description)
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Color picker
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Color")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(AppSettings.presetColors, id: \.hex) { preset in
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: colorHex == preset.hex ? 3 : 0)
                                        )
                                        .scaleEffect(colorHex == preset.hex ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.2), value: colorHex)
                                        .onTapGesture { colorHex = preset.hex }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Program" : "New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.textSecondary : settings.accentColor)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var previewCard: some View {
        HStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 48))

            VStack(alignment: .leading, spacing: 4) {
                Text(name.isEmpty ? "Program Name" : name)
                    .font(.title3).bold()
                    .foregroundColor(name.isEmpty ? .textSecondary : .white)
                if !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
        }
        .padding(20)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(hex: colorHex).opacity(0.5), lineWidth: 2)
        )
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if var existing = program {
            existing.name        = trimmedName
            existing.description = description
            existing.emoji       = emoji
            existing.colorHex    = colorHex
            store.updateProgram(existing)
        } else {
            store.addProgram(WorkoutProgram(
                name:        trimmedName,
                description: description,
                emoji:       emoji,
                colorHex:    colorHex
            ))
        }
    }
}
