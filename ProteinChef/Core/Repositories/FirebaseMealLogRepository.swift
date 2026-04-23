import Foundation
import FirebaseFirestore

final class FirebaseMealLogRepository: MealLogRepositoryProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()

    private func collection(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("mealLogs")
    }

    func list(ownerUid: String, on day: Date) async throws -> [MealLog] {
        let bounds = MealLogDate.dayBounds(day)
        let snapshot = try await collection(ownerUid)
            .whereField("date", isGreaterThanOrEqualTo: bounds.start)
            .whereField("date", isLessThan: bounds.end)
            .order(by: "date")
            .order(by: "createdAt")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: MealLog.self) }
    }

    func listStream(ownerUid: String, on day: Date) -> AsyncThrowingStream<[MealLog], Error> {
        AsyncThrowingStream { continuation in
            let bounds = MealLogDate.dayBounds(day)
            let listener = collection(ownerUid)
                .whereField("date", isGreaterThanOrEqualTo: bounds.start)
                .whereField("date", isLessThan: bounds.end)
                .order(by: "date")
                .order(by: "createdAt")
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    guard let snapshot else { return }
                    do {
                        let logs = try snapshot.documents.map { try $0.data(as: MealLog.self) }
                        continuation.yield(logs)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }

    func save(_ log: MealLog) async throws {
        try collection(log.ownerUid).document(log.id).setData(from: log, merge: true)
    }

    func delete(ownerUid: String, id: String) async throws {
        try await collection(ownerUid).document(id).delete()
    }
}
