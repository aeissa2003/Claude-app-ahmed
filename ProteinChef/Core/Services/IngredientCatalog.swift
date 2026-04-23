import Foundation
import Observation

protocol IngredientCatalogProtocol: Sendable {
    var all: [Ingredient] { get }
    func ingredient(id: String) -> Ingredient?
    func search(_ query: String, limit: Int) -> [Ingredient]
}

/// Loads the seeded ingredient JSON from the app bundle into memory.
/// Singleton-style: constructed once via AppEnvironment.live().
@Observable
final class BundledIngredientCatalog: IngredientCatalogProtocol, @unchecked Sendable {
    private(set) var all: [Ingredient] = []
    private var byId: [String: Ingredient] = [:]

    init(resourceName: String = "ingredients", bundle: Bundle = .main) {
        load(resourceName: resourceName, bundle: bundle)
    }

    func ingredient(id: String) -> Ingredient? {
        byId[id]
    }

    func search(_ query: String, limit: Int = 20) -> [Ingredient] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return Array(all.prefix(limit)) }
        let scored = all.compactMap { ing -> (Int, Ingredient)? in
            let name = ing.name.lowercased()
            if name.hasPrefix(q) { return (0, ing) }
            if name.contains(q)  { return (1, ing) }
            if ing.aliases.contains(where: { $0.lowercased().contains(q) }) { return (2, ing) }
            return nil
        }
        return scored
            .sorted { $0.0 < $1.0 }
            .prefix(limit)
            .map { $0.1 }
    }

    private func load(resourceName: String, bundle: Bundle) {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            assertionFailure("Missing \(resourceName).json in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(Payload.self, from: data)
            self.all = decoded.ingredients
            self.byId = Dictionary(uniqueKeysWithValues: decoded.ingredients.map { ($0.id, $0) })
        } catch {
            assertionFailure("Failed to decode \(resourceName).json: \(error)")
        }
    }

    private struct Payload: Decodable {
        let ingredients: [Ingredient]
    }
}
