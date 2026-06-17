import SwiftUI
import Vision
import PhotosUI

struct ScanWorkoutView: View {
    @EnvironmentObject var store: WorkoutStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.dismiss) var dismiss

    let programID: UUID

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var parsedExercises: [Exercise] = []
    @State private var rawLines: [String] = []
    @State private var workoutName = ""
    @State private var selectedSplit: SplitType = .custom
    @State private var phase: ScanPhase = .pick
    @State private var showingSplitPicker = false
    @State private var expandedID: UUID?

    enum ScanPhase { case pick, processing, review }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                switch phase {
                case .pick:       pickPhaseView
                case .processing: processingView
                case .review:     reviewPhaseView
                }
            }
            .navigationTitle("Scan Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Pick Phase
    private var pickPhaseView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero illustration
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(settings.accentColor.opacity(0.1))
                            .frame(width: 120, height: 120)
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundStyle(settings.accentColor)
                    }

                    Text("Scan Handwritten Workout")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text("Take a photo of your handwritten workout notes and we'll extract the exercises automatically.")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 24)

                // Photo picker
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title3)
                        Text("Choose from Library")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(settings.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .onChange(of: selectedItem) { newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImage = image
                            await processImage(image)
                        }
                    }
                }

                // Tips
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tips for best results")
                        .font(.caption.bold())
                        .foregroundColor(.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    TipRow(icon: "light.max", text: "Good lighting helps OCR accuracy")
                    TipRow(icon: "square.dashed", text: "Write clearly in a structured format")
                    TipRow(icon: "text.alignleft", text: "Format: Exercise Name – Sets x Reps @ Weight")
                    TipRow(icon: "pencil.and.outline", text: "You can edit any parsed result")
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Processing Phase
    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(settings.accentColor)
            Text("Scanning workout…")
                .font(.headline)
                .foregroundColor(.white)
            Text("Recognizing text and parsing exercises")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Spacer()
        }
    }

    // MARK: - Review Phase
    private var reviewPhaseView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // Workout details
                VStack(spacing: 14) {
                    SectionHeader("Workout Details")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    DarkTextField(placeholder: "Workout name", text: $workoutName)

                    Button {
                        showingSplitPicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedSplit.icon)
                                .foregroundStyle(selectedSplit.color)
                            Text(selectedSplit.rawValue)
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
                        SplitPickerSheet(selected: $selectedSplit)
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Parsed exercises
                VStack(spacing: 12) {
                    HStack {
                        SectionHeader("Parsed Exercises")
                        Spacer()
                        Text("\(parsedExercises.count) found")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if parsedExercises.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundStyle(.yellow)
                            Text("No exercises detected")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Text("You can add them manually below.")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(parsedExercises) { exercise in
                            ExerciseEditorRow(
                                exercise: exercise,
                                isExpanded: expandedID == exercise.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        expandedID = expandedID == exercise.id ? nil : exercise.id
                                    }
                                },
                                onChange: { updated in
                                    if let i = parsedExercises.firstIndex(where: { $0.id == updated.id }) {
                                        parsedExercises[i] = updated
                                    }
                                },
                                onDelete: {
                                    withAnimation {
                                        parsedExercises.removeAll { $0.id == exercise.id }
                                    }
                                }
                            )
                        }
                    }

                    // Add exercise button
                    Button {
                        withAnimation {
                            let new = Exercise()
                            parsedExercises.append(new)
                            expandedID = new.id
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill").foregroundStyle(settings.accentColor)
                            Text("Add Exercise").font(.subheadline.bold()).foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(settings.accentColor.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(16)
                .background(Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // Raw OCR lines (collapsible)
                if !rawLines.isEmpty {
                    rawLinesSection
                }

                // Save button
                Button {
                    saveWorkout()
                } label: {
                    Text("Save Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(settings.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(workoutName.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(workoutName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)

                Button {
                    // Reset to pick phase
                    withAnimation {
                        phase = .pick
                        selectedImage = nil
                        selectedItem = nil
                        parsedExercises = []
                        rawLines = []
                    }
                } label: {
                    Text("Scan Another Image")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 40)
        }
    }

    private var rawLinesSection: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(rawLines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
        } label: {
            Text("Raw OCR Text")
                .font(.caption.bold())
                .foregroundColor(.textSecondary)
                .textCase(.uppercase)
                .tracking(1)
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .tint(.textSecondary)
    }

    // MARK: - OCR Processing
    private func processImage(_ image: UIImage) async {
        await MainActor.run { phase = .processing }

        let lines = await recognizeText(in: image)
        let exercises = parseExercises(from: lines)

        await MainActor.run {
            rawLines = lines
            parsedExercises = exercises
            if workoutName.isEmpty { workoutName = "Scanned Workout" }
            phase = .review
        }
    }

    private func recognizeText(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let results = req.results as? [VNRecognizedTextObservation] ?? []
                let lines = results.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    private func parseExercises(from lines: [String]) -> [Exercise] {
        var exercises: [Exercise] = []

        let setsRepsPattern = try? NSRegularExpression(
            pattern: #"(\d+)\s*[xX×]\s*(\d+(?:-\d+)?(?:\s*(?:reps?|AMRAP))?)"#,
            options: .caseInsensitive
        )
        let weightPattern = try? NSRegularExpression(
            pattern: #"[@(]?\s*(\d+(?:\.\d+)?)\s*(lbs?|kg|pounds?)?"#,
            options: .caseInsensitive
        )

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, trimmed.count > 2 else { continue }

            let nsLine = trimmed as NSString
            let range = NSRange(location: 0, length: nsLine.length)

            if let match = setsRepsPattern?.firstMatch(in: trimmed, range: range) {
                let sets = Int(nsLine.substring(with: match.range(at: 1))) ?? 3
                let reps = nsLine.substring(with: match.range(at: 2))
                    .trimmingCharacters(in: .whitespaces)

                // Extract name: everything before the match
                let matchStart = match.range.location
                var name = String(trimmed.prefix(matchStart))
                    .trimmingCharacters(in: .init(charactersIn: " -–:"))
                if name.isEmpty { name = "Exercise" }

                // Extract weight
                var weight = ""
                if let wMatch = weightPattern?.firstMatch(in: trimmed, range: range),
                   wMatch.range(at: 1).location != NSNotFound {
                    let wNum = nsLine.substring(with: wMatch.range(at: 1))
                    var unit = ""
                    if wMatch.range(at: 2).location != NSNotFound {
                        unit = " " + nsLine.substring(with: wMatch.range(at: 2))
                    }
                    weight = wNum + unit
                }

                exercises.append(Exercise(name: name, sets: sets, reps: reps, weight: weight))
            }
        }

        return exercises
    }

    // MARK: - Save
    private func saveWorkout() {
        let validExercises = parsedExercises.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let workout = Workout(
            name:      workoutName.trimmingCharacters(in: .whitespaces),
            split:     selectedSplit,
            exercises: validExercises
        )
        store.addWorkout(workout, toProgramID: programID)
        dismiss()
    }
}

// MARK: - Tip Row
struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .frame(width: 20)
            Text(text)
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
    }
}
