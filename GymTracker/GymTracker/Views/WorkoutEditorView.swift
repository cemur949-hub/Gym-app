import SwiftUI

struct WorkoutEditorView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let programID: UUID
    let workout: Workout?

    @State private var name: String
    @State private var selectedSplitID: UUID?
    @State private var notes: String
    @State private var exercises: [Exercise]
    @State private var expandedExerciseID: UUID?
    @State private var showingCreateSplit = false

    private var isEditing: Bool { workout != nil }

    private var currentProgram: WorkoutProgram? {
        store.programs.first { $0.id == programID }
    }

    init(programID: UUID, workout: Workout?) {
        self.programID = programID
        self.workout   = workout
        _name             = State(initialValue: workout?.name ?? "")
        _selectedSplitID  = State(initialValue: workout?.splitID)
        _notes            = State(initialValue: workout?.notes ?? "")
        _exercises        = State(initialValue: workout?.exercises ?? [])
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        workoutInfoSection
                        exercisesSection
                        if !exercises.isEmpty { notesSection }
                    }
                    .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 60)
                }
            }
            .navigationTitle(isEditing ? "Edit Workout" : "New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .font(.headline)
                        .foregroundStyle(canSave ? settings.accentColor : Color.textSecondary)
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Workout Info
    private var workoutInfoSection: some View {
        VStack(spacing: 14) {
            SectionHeader("Workout Info").frame(maxWidth: .infinity, alignment: .leading)
            DarkTextField(placeholder: "Workout name (e.g. Push Day)", text: $name)

            // Split selector
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Split Tag")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // None pill
                        Button {
                            selectedSplitID = nil
                        } label: {
                            Text("None")
                                .font(.subheadline.bold())
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedSplitID == nil ? settings.accentColor : Color.cardSurface)
                                .foregroundColor(selectedSplitID == nil ? .white : .textSecondary)
                                .clipShape(Capsule())
                        }

                        ForEach(currentProgram?.splits ?? []) { split in
                            Button {
                                selectedSplitID = split.id
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: split.icon).font(.caption)
                                    Text(split.name).font(.subheadline.bold())
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(selectedSplitID == split.id ? split.color : Color.cardSurface)
                                .foregroundColor(selectedSplitID == split.id ? .white : .textSecondary)
                                .clipShape(Capsule())
                            }
                        }

                        // Create split button
                        Button {
                            showingCreateSplit = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus").font(.caption.bold())
                                Text("New Split").font(.subheadline.bold())
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.cardSurface)
                            .foregroundStyle(settings.accentColor)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(settings.accentColor.opacity(0.4), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(16).background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .sheet(isPresented: $showingCreateSplit) {
            CreateSplitSheet(programID: programID)
        }
    }

    // MARK: - Exercises
    private var exercisesSection: some View {
        VStack(spacing: 12) {
            HStack {
                SectionHeader("Exercises")
                Spacer()
                Text("\(exercises.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(settings.accentColor.opacity(0.2))
                    .foregroundStyle(settings.accentColor)
                    .clipShape(Capsule())
            }

            if exercises.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 32))
                        .foregroundStyle(settings.accentColor.opacity(0.4))
                    Text("No exercises added yet").font(.subheadline).foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                ForEach(exercises) { exercise in
                    ExerciseEditorRow(
                        exercise: exercise,
                        isExpanded: expandedExerciseID == exercise.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                expandedExerciseID = expandedExerciseID == exercise.id ? nil : exercise.id
                            }
                        },
                        onChange: { updated in
                            if let i = exercises.firstIndex(where: { $0.id == updated.id }) {
                                exercises[i] = updated
                            }
                        },
                        onDelete: {
                            withAnimation {
                                exercises.removeAll { $0.id == exercise.id }
                                if expandedExerciseID == exercise.id { expandedExerciseID = nil }
                            }
                        }
                    )
                }
            }

            Button {
                withAnimation(.spring(response: 0.35)) {
                    let new = Exercise()
                    exercises.append(new)
                    expandedExerciseID = new.id
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill").foregroundStyle(settings.accentColor)
                    Text("Add Exercise").font(.subheadline.bold()).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(settings.accentColor.opacity(0.3), lineWidth: 1))
            }
        }
        .padding(16).background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Notes
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Notes")
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .frame(minHeight: 80).padding(10)
                    .background(Color.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white).tint(settings.accentColor)
                    .scrollContentBackground(.hidden)
                if notes.isEmpty {
                    Text("Workout notes, instructions...")
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 14).padding(.top, 18)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(16).background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Save
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if var existing = workout {
            existing.name      = trimmed
            existing.splitID   = selectedSplitID
            existing.notes     = notes
            existing.exercises = exercises
            store.updateWorkout(existing, inProgramID: programID)
        } else {
            store.addWorkout(
                Workout(name: trimmed, splitID: selectedSplitID, exercises: exercises, notes: notes),
                toProgramID: programID
            )
        }
        dismiss()
    }
}

// MARK: - Exercise Editor Row
struct ExerciseEditorRow: View {
    @EnvironmentObject var settings: AppSettings
    let exercise: Exercise
    let isExpanded: Bool
    let onTap: () -> Void
    let onChange: (Exercise) -> Void
    let onDelete: () -> Void

    @State private var localExercise: Exercise

    init(exercise: Exercise, isExpanded: Bool, onTap: @escaping () -> Void,
         onChange: @escaping (Exercise) -> Void, onDelete: @escaping () -> Void) {
        self.exercise = exercise; self.isExpanded = isExpanded
        self.onTap = onTap; self.onChange = onChange; self.onDelete = onDelete
        _localExercise = State(initialValue: exercise)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                    .foregroundStyle(isExpanded ? settings.accentColor : Color.textSecondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    if localExercise.name.isEmpty {
                        Text("New Exercise").font(.subheadline).foregroundColor(.textSecondary)
                    } else {
                        Text(localExercise.name).font(.subheadline.bold()).foregroundColor(.white)
                        Text(localExercise.displayString).font(.caption).foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7))
                }.padding(8)
            }
            .contentShape(Rectangle()).onTapGesture(perform: onTap)
            .padding(.horizontal, 14).padding(.vertical, 10)

            if isExpanded {
                Divider().background(Color.divider)
                VStack(spacing: 14) {
                    fieldRow("Exercise Name") {
                        TextField("e.g. Bench Press", text: $localExercise.name)
                            .styledInput()
                            .onChange(of: localExercise.name) { _ in onChange(localExercise) }
                    }
                    HStack(spacing: 12) {
                        fieldRow("Sets") {
                            HStack {
                                Button {
                                    if localExercise.sets > 1 { localExercise.sets -= 1; onChange(localExercise) }
                                } label: { Image(systemName: "minus").font(.caption.bold()) }
                                .frame(width: 28, height: 28).background(Color.cardBackground)
                                .clipShape(Circle()).foregroundColor(.white)

                                Text("\(localExercise.sets)").font(.headline).foregroundColor(.white).frame(minWidth: 24)

                                Button {
                                    localExercise.sets += 1; onChange(localExercise)
                                } label: { Image(systemName: "plus").font(.caption.bold()) }
                                .frame(width: 28, height: 28).background(settings.accentColor)
                                .clipShape(Circle()).foregroundColor(.white)
                            }.padding(.vertical, 6)
                        }.frame(maxWidth: .infinity)

                        fieldRow("Reps") {
                            TextField("10 or 8-12", text: $localExercise.reps)
                                .styledInput()
                                .onChange(of: localExercise.reps) { _ in onChange(localExercise) }
                        }.frame(maxWidth: .infinity)
                    }
                    fieldRow("Weight (optional)") {
                        TextField("135 lbs, 60 kg...", text: $localExercise.weight)
                            .styledInput()
                            .onChange(of: localExercise.weight) { _ in onChange(localExercise) }
                    }
                    fieldRow("Rest: \(localExercise.restDisplay)") {
                        Slider(value: Binding(
                            get: { Double(localExercise.restSeconds) },
                            set: { localExercise.restSeconds = Int($0); onChange(localExercise) }
                        ), in: 0...300, step: 15).tint(settings.accentColor)
                    }
                    fieldRow("Notes (optional)") {
                        TextField("Cues, form tips...", text: $localExercise.notes)
                            .styledInput()
                            .onChange(of: localExercise.notes) { _ in onChange(localExercise) }
                    }
                }
                .padding(14)
            }
        }
        .background(Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func fieldRow<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundColor(.textSecondary)
            content()
        }
    }
}

extension View {
    func styledInput() -> some View {
        self.padding(.horizontal, 12).padding(.vertical, 10)
            .background(Color.cardBackground).foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10)).tint(.white)
    }
}
