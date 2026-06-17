import SwiftUI

struct WorkoutEditorView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let programID: UUID
    let workout: Workout?

    @State private var name: String
    @State private var split: SplitType
    @State private var notes: String
    @State private var exercises: [Exercise]

    @State private var expandedExerciseID: UUID?
    @State private var showingSplitPicker = false

    private var isEditing: Bool { workout != nil }

    init(programID: UUID, workout: Workout?) {
        self.programID = programID
        self.workout   = workout
        _name      = State(initialValue: workout?.name ?? "")
        _split     = State(initialValue: workout?.split ?? .custom)
        _notes     = State(initialValue: workout?.notes ?? "")
        _exercises = State(initialValue: workout?.exercises ?? [])
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
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle(isEditing ? "Edit Workout" : "New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
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

    // MARK: - Sections

    private var workoutInfoSection: some View {
        VStack(spacing: 14) {
            SectionHeader("Workout Info")
                .frame(maxWidth: .infinity, alignment: .leading)

            DarkTextField(placeholder: "Workout name (e.g. Push Day)", text: $name)

            // Split selector
            Button {
                showingSplitPicker = true
            } label: {
                HStack {
                    Image(systemName: split.icon)
                        .foregroundStyle(split.color)
                    Text(split.rawValue)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .sheet(isPresented: $showingSplitPicker) {
                SplitPickerSheet(selected: $split)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var exercisesSection: some View {
        VStack(spacing: 12) {
            HStack {
                SectionHeader("Exercises")
                Spacer()
                Text("\(exercises.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(settings.accentColor.opacity(0.2))
                    .foregroundStyle(settings.accentColor)
                    .clipShape(Capsule())
            }

            if exercises.isEmpty {
                emptyExercisePlaceholder
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

            // Add exercise button
            Button {
                withAnimation(.spring(response: 0.35)) {
                    let new = Exercise()
                    exercises.append(new)
                    expandedExerciseID = new.id
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(settings.accentColor)
                    Text("Add Exercise")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(settings.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Notes")
            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(Color.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.white)
                    .tint(settings.accentColor)
                    .scrollContentBackground(.hidden)
                if notes.isEmpty {
                    Text("Workout notes, instructions...")
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 18)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var emptyExercisePlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 32))
                .foregroundStyle(settings.accentColor.opacity(0.4))
            Text("No exercises added yet")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Save
    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if var existing = workout {
            existing.name      = trimmed
            existing.split     = split
            existing.notes     = notes
            existing.exercises = exercises
            store.updateWorkout(existing, inProgramID: programID)
        } else {
            store.addWorkout(
                Workout(name: trimmed, split: split, exercises: exercises, notes: notes),
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
        self.exercise   = exercise
        self.isExpanded = isExpanded
        self.onTap      = onTap
        self.onChange   = onChange
        self.onDelete   = onDelete
        _localExercise  = State(initialValue: exercise)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.right.circle.fill")
                    .foregroundStyle(isExpanded ? settings.accentColor : Color.textSecondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    if localExercise.name.isEmpty {
                        Text("New Exercise")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    } else {
                        Text(localExercise.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                        Text(localExercise.displayString)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                }
                .padding(8)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Expanded form
            if isExpanded {
                Divider()
                    .background(Color.divider)

                VStack(spacing: 14) {
                    // Name
                    fieldRow(label: "Exercise Name") {
                        TextField("e.g. Bench Press", text: $localExercise.name)
                            .styledInput()
                            .onChange(of: localExercise.name) { _ in onChange(localExercise) }
                    }

                    // Sets & Reps row
                    HStack(spacing: 12) {
                        fieldRow(label: "Sets") {
                            HStack {
                                Button {
                                    if localExercise.sets > 1 {
                                        localExercise.sets -= 1
                                        onChange(localExercise)
                                    }
                                } label: {
                                    Image(systemName: "minus").font(.caption.bold())
                                }
                                .frame(width: 28, height: 28)
                                .background(Color.cardBackground)
                                .clipShape(Circle())
                                .foregroundColor(.white)

                                Text("\(localExercise.sets)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 24)

                                Button {
                                    localExercise.sets += 1
                                    onChange(localExercise)
                                } label: {
                                    Image(systemName: "plus").font(.caption.bold())
                                }
                                .frame(width: 28, height: 28)
                                .background(settings.accentColor)
                                .clipShape(Circle())
                                .foregroundColor(.white)
                            }
                            .padding(.vertical, 6)
                        }
                        .frame(maxWidth: .infinity)

                        fieldRow(label: "Reps") {
                            TextField("10 or 8-12", text: $localExercise.reps)
                                .styledInput()
                                .onChange(of: localExercise.reps) { _ in onChange(localExercise) }
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Weight
                    fieldRow(label: "Weight (optional)") {
                        TextField("135 lbs, 60 kg...", text: $localExercise.weight)
                            .styledInput()
                            .onChange(of: localExercise.weight) { _ in onChange(localExercise) }
                    }

                    // Rest time
                    fieldRow(label: "Rest: \(localExercise.restDisplay)") {
                        Slider(value: Binding(
                            get: { Double(localExercise.restSeconds) },
                            set: { localExercise.restSeconds = Int($0); onChange(localExercise) }
                        ), in: 0...300, step: 15)
                        .tint(settings.accentColor)
                    }

                    // Notes
                    fieldRow(label: "Notes (optional)") {
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

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.textSecondary)
            content()
        }
    }
}

// MARK: - Split Picker Sheet
struct SplitPickerSheet: View {
    @Binding var selected: SplitType
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(SplitType.allCases) { split in
                            Button {
                                selected = split
                                dismiss()
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: split.icon)
                                        .font(.title3)
                                        .foregroundStyle(split.color)
                                        .frame(width: 36)

                                    Text(split.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Spacer()

                                    if selected == split {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(split.color)
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(Color.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Choose Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - TextField style helper
extension View {
    func styledInput() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.cardBackground)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .tint(.white)
    }
}
