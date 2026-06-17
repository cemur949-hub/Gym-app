import Foundation
import Combine

class WorkoutStore: ObservableObject {
    @Published var programs: [WorkoutProgram] = []

    private let saveKey = "workout_programs_v1"

    init() {
        load()
        if programs.isEmpty {
            programs = WorkoutProgram.sampleData
        }
    }

    // MARK: - Programs

    func addProgram(_ program: WorkoutProgram) {
        programs.append(program)
        save()
    }

    func updateProgram(_ program: WorkoutProgram) {
        guard let i = programs.firstIndex(where: { $0.id == program.id }) else { return }
        programs[i] = program
        save()
    }

    func deleteProgram(id: UUID) {
        programs.removeAll { $0.id == id }
        save()
    }

    // MARK: - Workouts

    func addWorkout(_ workout: Workout, toProgramID pid: UUID) {
        guard let i = programs.firstIndex(where: { $0.id == pid }) else { return }
        programs[i].workouts.append(workout)
        save()
    }

    func updateWorkout(_ workout: Workout, inProgramID pid: UUID) {
        guard let pi = programs.firstIndex(where: { $0.id == pid }),
              let wi = programs[pi].workouts.firstIndex(where: { $0.id == workout.id }) else { return }
        programs[pi].workouts[wi] = workout
        save()
    }

    func deleteWorkout(id wid: UUID, fromProgramID pid: UUID) {
        guard let pi = programs.firstIndex(where: { $0.id == pid }) else { return }
        programs[pi].workouts.removeAll { $0.id == wid }
        save()
    }

    // MARK: - Persistence

    func save() {
        if let data = try? JSONEncoder().encode(programs) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([WorkoutProgram].self, from: data) else { return }
        programs = decoded
    }

    // MARK: - Export / Import

    func exportJSON() -> String? {
        guard let data = try? JSONEncoder().encode(programs) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8) else { throw StoreError.invalidData }
        programs = try JSONDecoder().decode([WorkoutProgram].self, from: data)
        save()
    }

    func clearAll() {
        programs = []
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    enum StoreError: LocalizedError {
        case invalidData
        var errorDescription: String? { "Invalid JSON data" }
    }
}
