import Foundation

protocol ExerciseCatalogProtocol: Sendable {
    var all: [Exercise] { get }
    func exercise(id: String) -> Exercise?
    func search(_ query: String, limit: Int) -> [Exercise]
}

/// Bundle-loaded exercise catalog. Used by the workout editor in Phase 5;
/// added here so the app environment has one source of truth from day one.
final class BundledExerciseCatalog: ExerciseCatalogProtocol, @unchecked Sendable {
    private(set) var all: [Exercise] = []
    private var byId: [String: Exercise] = [:]

    init(resourceName: String = "exercises", bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            assertionFailure("Missing \(resourceName).json in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Payload.self, from: data)
            self.all = decoded.exercises
            self.byId = Dictionary(uniqueKeysWithValues: decoded.exercises.map { ($0.id, $0) })
        } catch {
            assertionFailure("Failed to decode \(resourceName).json: \(error)")
        }
    }

    func exercise(id: String) -> Exercise? { byId[id] }

    func search(_ query: String, limit: Int = 20) -> [Exercise] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Array(all.prefix(limit)) }
        return all.filter { $0.name.lowercased().contains(q) }.prefix(limit).map { $0 }
    }

    private struct Payload: Decodable { let exercises: [Exercise] }
}
