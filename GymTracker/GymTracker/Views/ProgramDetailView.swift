import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings

    let program: WorkoutProgram

    @State private var selectedSplitID: UUID? = nil
    @State private var showingAddWorkout   = false
    @State private var showingScanWorkout  = false
    @State private var editingWorkout: Workout?
    @State private var deleteTarget: Workout?
    @State private var showDeleteAlert = false
    @State private var showAddMenu     = false
    @State private var showManageSplits = false

    private var currentProgram: WorkoutProgram {
        store.programs.first { $0.id == program.id } ?? program
    }

    private var filteredWorkouts: [Workout] {
        guard let sid = selectedSplitID else { return currentProgram.workouts }
        return currentProgram.workouts.filter { $0.splitID == sid }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                splitFilterBar
                if filteredWorkouts.isEmpty {
                    emptyWorkouts
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredWorkouts) { workout in
                                let split = currentProgram.split(for: workout)
                                NavigationLink(destination: WorkoutDetailView(workout: workout, programID: program.id)) {
                                    WorkoutRow(workout: workout, split: split)
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

            fabButton
        }
        .navigationTitle(currentProgram.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showManageSplits = true
                } label: {
                    Image(systemName: "tag.fill")
                        .foregroundStyle(settings.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddWorkout) {
            WorkoutEditorView(programID: program.id, workout: nil)
        }
        .sheet(isPresented: $showingScanWorkout) {
            ScanWorkoutView(programID: program.id)
        }
        .sheet(item: $editingWorkout) { w in
            WorkoutEditorView(programID: program.id, workout: w)
        }
        .sheet(isPresented: $showManageSplits) {
            ManageSplitsSheet(programID: program.id)
        }
        .alert("Delete Workout?", isPresented: $showDeleteAlert, presenting: deleteTarget) { w in
            Button("Delete", role: .destructive) {
                withAnimation { store.deleteWorkout(id: w.id, fromProgramID: program.id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: { w in
            Text("\"\(w.name)\" will be permanently deleted.")
        }
    }

    // MARK: - Split Filter Bar
    private var splitFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SplitPill(label: "All", color: settings.accentColor, isSelected: selectedSplitID == nil) {
                    withAnimation(.spring(response: 0.3)) { selectedSplitID = nil }
                }
                ForEach(currentProgram.splits) { split in
                    SplitPill(label: split.name, color: split.color, isSelected: selectedSplitID == split.id) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedSplitID = selectedSplitID == split.id ? nil : split.id
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
            Text(selectedSplitID == nil ? "No Workouts" : "No Workouts in this Split")
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
    let workout: Workout
    let split: WorkoutSplit?

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(split?.color ?? Color.cardSurface)
                .frame(width: 4, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.headline)
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    if let split = split {
                        SplitBadge(split: split)
                        Text("·").foregroundColor(.textSecondary)
                    }
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

// MARK: - Workout Detail View
struct WorkoutDetailView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings

    let workout: Workout
    let programID: UUID

    @State private var showingEditor = false

    private var currentProgram: WorkoutProgram? {
        store.programs.first { $0.id == programID }
    }
    private var currentWorkout: Workout {
        currentProgram?.workouts.first { $0.id == workout.id } ?? workout
    }
    private var currentSplit: WorkoutSplit? {
        currentProgram?.split(for: currentWorkout)
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if currentWorkout.exercises.isEmpty {
                        emptyExercises
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(currentWorkout.exercises.enumerated()), id: \.element.id) { idx, ex in
                                ExerciseCard(exercise: ex, index: idx + 1)
                            }
                        }
                    }
                    if !currentWorkout.notes.isEmpty { notesCard }
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
                Button { showingEditor = true } label: {
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
                if let split = currentSplit {
                    SplitBadge(split: split).padding(.bottom, 2)
                }
                Text("\(currentWorkout.exercises.count) exercises")
                    .font(.subheadline).foregroundColor(.textSecondary)
            }
            Spacer()
            if let split = currentSplit {
                Image(systemName: split.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(split.color.opacity(0.8))
            }
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
            Text("No exercises yet").foregroundColor(.textSecondary)
            Button("Add Exercises") { showingEditor = true }
                .font(.headline).foregroundStyle(settings.accentColor)
        }
        .frame(maxWidth: .infinity).padding(40)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.caption.bold()).foregroundColor(.textSecondary).textCase(.uppercase)
            Text(currentWorkout.notes).font(.subheadline).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16).background(Color.cardBackground)
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
            Text("\(index)")
                .font(.caption.bold())
                .frame(width: 28, height: 28)
                .background(settings.accentColor.opacity(0.2))
                .foregroundStyle(settings.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name).font(.headline).foregroundColor(.white)
                HStack(spacing: 8) {
                    chip(icon: "arrow.counterclockwise", text: "\(exercise.sets) sets")
                    chip(icon: "repeat", text: exercise.reps + " reps")
                    if !exercise.weight.isEmpty {
                        chip(icon: "scalemass.fill", text: exercise.weight)
                    }
                }
            }
            Spacer()
            if exercise.restSeconds > 0 {
                VStack(spacing: 2) {
                    Image(systemName: "timer").font(.caption2)
                    Text(exercise.restDisplay).font(.caption2)
                }
                .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.caption2)
            Text(text).font(.caption)
        }
        .foregroundColor(.textSecondary)
    }
}

// MARK: - Manage Splits Sheet
struct ManageSplitsSheet: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let programID: UUID
    @State private var showingCreate = false

    private var program: WorkoutProgram? {
        store.programs.first { $0.id == programID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if let prog = program {
                    if prog.splits.isEmpty {
                        emptySplits
                    } else {
                        List {
                            ForEach(prog.splits) { split in
                                HStack(spacing: 14) {
                                    Image(systemName: split.icon)
                                        .font(.subheadline)
                                        .frame(width: 32, height: 32)
                                        .background(split.color.opacity(0.2))
                                        .foregroundStyle(split.color)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    Text(split.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    let count = prog.workouts.filter { $0.splitID == split.id }.count
                                    Text("\(count) workouts")
                                        .font(.caption)
                                        .foregroundColor(.textSecondary)
                                }
                                .listRowBackground(Color.cardBackground)
                            }
                            .onDelete { offsets in
                                for i in offsets {
                                    store.deleteSplit(id: prog.splits[i].id, fromProgramID: programID)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Splits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus").foregroundStyle(settings.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateSplitSheet(programID: programID)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var emptySplits: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundStyle(settings.accentColor.opacity(0.4))
            Text("No Splits Yet")
                .font(.title3.bold()).foregroundColor(.white)
            Text("Create splits to organize your workouts\n(e.g. Push, Pull, Legs, Upper, Lower)")
                .multilineTextAlignment(.center)
                .foregroundColor(.textSecondary)
            Button {
                showingCreate = true
            } label: {
                Label("Create Split", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(settings.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(32)
    }
}

// MARK: - Create Split Sheet
struct CreateSplitSheet: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let programID: UUID
    @State private var name = ""
    @State private var colorHex = "FF6B35"
    @State private var icon = "tag.fill"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Preview
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 52, height: 52)
                                .background(Color(hex: colorHex).opacity(0.2))
                                .foregroundStyle(Color(hex: colorHex))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(name.isEmpty ? "Split Name" : name)
                                .font(.title3.bold())
                                .foregroundColor(name.isEmpty ? .textSecondary : .white)
                            Spacer()
                        }
                        .padding(18)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18)
                            .stroke(Color(hex: colorHex).opacity(0.4), lineWidth: 2))

                        // Name
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader("Name")
                            DarkTextField(placeholder: "e.g. Push, Pull, Legs, Upper...", text: $name)
                        }
                        .padding(16).background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Color
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Color")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                ForEach(WorkoutSplit.presetColors, id: \.hex) { preset in
                                    Circle()
                                        .fill(Color(hex: preset.hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(Circle().stroke(Color.white, lineWidth: colorHex == preset.hex ? 3 : 0))
                                        .scaleEffect(colorHex == preset.hex ? 1.15 : 1.0)
                                        .animation(.spring(response: 0.2), value: colorHex)
                                        .onTapGesture { colorHex = preset.hex }
                                }
                            }
                        }
                        .padding(16).background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Icon
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader("Icon")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                ForEach(WorkoutSplit.presetIcons, id: \.self) { ic in
                                    Image(systemName: ic)
                                        .font(.title3)
                                        .frame(width: 44, height: 44)
                                        .background(icon == ic ? Color(hex: colorHex).opacity(0.25) : Color.cardSurface)
                                        .foregroundStyle(icon == ic ? Color(hex: colorHex) : Color.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10)
                                            .stroke(icon == ic ? Color(hex: colorHex) : Color.clear, lineWidth: 2))
                                        .onTapGesture { icon = ic }
                                }
                            }
                        }
                        .padding(16).background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 16)
                }
            }
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let split = WorkoutSplit(name: name.trimmingCharacters(in: .whitespaces), colorHex: colorHex, icon: icon)
                        store.addSplit(split, toProgramID: programID)
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
}

// MARK: - Shared UI Components

struct SplitBadge: View {
    let split: WorkoutSplit

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: split.icon).font(.caption2)
            Text(split.name).font(.caption.bold())
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
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
                .padding(.horizontal, 16).padding(.vertical, 8)
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
                Text(label).font(.subheadline.bold()).foregroundColor(.white)
                Image(systemName: icon).font(.subheadline)
                    .frame(width: 36, height: 36)
                    .background(color).foregroundColor(.white).clipShape(Circle())
            }
        }
        .padding(.trailing, 12)
    }
}

struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title).font(.caption.bold()).foregroundColor(.textSecondary)
            .textCase(.uppercase).tracking(1)
    }
}

struct DarkTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color.cardSurface).foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12)).tint(.white)
    }
}
