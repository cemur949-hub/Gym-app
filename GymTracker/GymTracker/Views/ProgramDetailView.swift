import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let program: WorkoutProgram

    @State private var selectedSplit: SplitType? = nil
    @State private var showingAddWorkout  = false
    @State private var showingScanWorkout = false
    @State private var editingWorkout: Workout?
    @State private var deleteTarget: Workout?
    @State private var showDeleteAlert = false
    @State private var showAddMenu = false

    private var currentProgram: WorkoutProgram {
        store.programs.first { $0.id == program.id } ?? program
    }

    private var filteredWorkouts: [Workout] {
        guard let split = selectedSplit else { return currentProgram.workouts }
        return currentProgram.workouts.filter { $0.split == split }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Split filter bar
                if !currentProgram.availableSplits.isEmpty || currentProgram.workouts.count > 1 {
                    splitFilterBar
                }

                // Workout list
                if filteredWorkouts.isEmpty {
                    emptyWorkouts
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredWorkouts) { workout in
                                NavigationLink(destination: WorkoutDetailView(workout: workout, programID: program.id)) {
                                    WorkoutRow(workout: workout)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button { editingWorkout = workout } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        deleteTarget = workout
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 100)
                    }
                }
            }

            // FAB
            fabButton
        }
        .navigationTitle(currentProgram.name)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddWorkout) {
            WorkoutEditorView(programID: program.id, workout: nil)
        }
        .sheet(isPresented: $showingScanWorkout) {
            ScanWorkoutView(programID: program.id)
        }
        .sheet(item: $editingWorkout) { w in
            WorkoutEditorView(programID: program.id, workout: w)
        }
        .alert("Delete Workout?", isPresented: $showDeleteAlert, presenting: deleteTarget) { w in
            Button("Delete", role: .destructive) {
                withAnimation { store.deleteWorkout(id: w.id, fromProgramID: program.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { w in
            Text(""\(w.name)" will be permanently deleted.")
        }
    }

    // MARK: - Split Filter Bar
    private var splitFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SplitPill(label: "All", color: settings.accentColor, isSelected: selectedSplit == nil) {
                    withAnimation(.spring(response: 0.3)) { selectedSplit = nil }
                }
                ForEach(currentProgram.availableSplits) { split in
                    SplitPill(label: split.rawValue, color: split.color, isSelected: selectedSplit == split) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSplit = selectedSplit == split ? nil : split
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Empty State
    private var emptyWorkouts: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(settings.accentColor.opacity(0.5))
            Text(selectedSplit == nil ? "No Workouts" : "No \(selectedSplit!.rawValue) Workouts")
                .font(.title3).bold()
                .foregroundColor(.white)
            Text("Tap + to add your first workout.")
                .foregroundColor(.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - FAB
    private var fabButton: some View {
        VStack(spacing: 0) {
            if showAddMenu {
                VStack(spacing: 8) {
                    FABMenuItem(icon: "camera.fill", label: "Scan Handwritten", color: .blue) {
                        showAddMenu = false
                        showingScanWorkout = true
                    }
                    FABMenuItem(icon: "pencil", label: "Create Manually", color: settings.accentColor) {
                        showAddMenu = false
                        showingAddWorkout = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal:   .move(edge: .bottom).combined(with: .opacity)
                ))
                .padding(.bottom, 12)
            }

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showAddMenu.toggle()
                }
            } label: {
                Image(systemName: showAddMenu ? "xmark" : "plus")
                    .font(.title3.bold())
                    .frame(width: 60, height: 60)
                    .background(settings.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(color: settings.accentColor.opacity(0.5), radius: 12, x: 0, y: 4)
                    .rotationEffect(.degrees(showAddMenu ? 45 : 0))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAddMenu)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Workout Row
struct WorkoutRow: View {
    @EnvironmentObject var settings: AppSettings
    let workout: Workout

    var body: some View {
        HStack(spacing: 14) {
            // Split color bar
            RoundedRectangle(cornerRadius: 3)
                .fill(workout.split.color)
                .frame(width: 4, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    SplitBadge(split: workout.split)
                    Text("·")
                        .foregroundColor(.textSecondary)
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Workout Detail View (exercise list)
struct WorkoutDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings

    let workout: Workout
    let programID: UUID

    @State private var showingEditor = false

    private var currentWorkout: Workout {
        store.programs
            .first { $0.id == programID }?
            .workouts
            .first { $0.id == workout.id } ?? workout
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header card
                    headerCard

                    // Exercises
                    if currentWorkout.exercises.isEmpty {
                        emptyExercises
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(currentWorkout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseCard(exercise: exercise, index: index + 1)
                            }
                        }
                    }

                    if !currentWorkout.notes.isEmpty {
                        notesCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(currentWorkout.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            WorkoutEditorView(programID: programID, workout: currentWorkout)
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                SplitBadge(split: currentWorkout.split)
                    .padding(.bottom, 2)
                Text("\(currentWorkout.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: currentWorkout.split.icon)
                .font(.system(size: 36))
                .foregroundStyle(currentWorkout.split.color.opacity(0.8))
        }
        .padding(18)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var emptyExercises: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 40))
                .foregroundStyle(settings.accentColor.opacity(0.4))
            Text("No exercises yet")
                .foregroundColor(.textSecondary)
            Button("Add Exercises") { showingEditor = true }
                .font(.headline)
                .foregroundStyle(settings.accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.caption.bold())
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
            Text(currentWorkout.notes)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @EnvironmentObject var settings: AppSettings
    let exercise: Exercise
    let index: Int

    var body: some View {
        HStack(spacing: 14) {
            // Index circle
            Text("\(index)")
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .background(settings.accentColor.opacity(0.2))
                .foregroundStyle(settings.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    statChip(icon: "arrow.counterclockwise", text: "\(exercise.sets) sets")
                    statChip(icon: "repeat", text: exercise.reps + " reps")
                    if !exercise.weight.isEmpty {
                        statChip(icon: "scalemass.fill", text: exercise.weight)
                    }
                }
            }

            Spacer()

            if exercise.restSeconds > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption2)
                    Text(exercise.restDisplay)
                        .font(.caption2)
                }
                .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statChip(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(.textSecondary)
    }
}

// MARK: - Shared UI Components

struct SplitBadge: View {
    let split: SplitType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: split.icon)
                .font(.caption2)
            Text(split.rawValue)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(split.color.opacity(0.2))
        .foregroundStyle(split.color)
        .clipShape(Capsule())
    }
}

struct SplitPill: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : Color.cardSurface)
                .foregroundColor(isSelected ? .white : .textSecondary)
                .clipShape(Capsule())
        }
    }
}

struct FABMenuItem: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                Image(systemName: icon)
                    .font(.subheadline)
                    .frame(width: 36, height: 36)
                    .background(color)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding(.trailing, 12)
    }
}

struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.caption.bold())
            .foregroundColor(.textSecondary)
            .textCase(.uppercase)
            .tracking(1)
    }
}

struct DarkTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardSurface)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .tint(.white)
    }
}
