import Foundation
import Observation

@Observable
final class AppEnvironment {
    let auth: AuthServiceProtocol
    let firestore: FirestoreServiceProtocol
    let storage: StorageServiceProtocol
    let push: PushServiceProtocol

    let userProfiles: UserProfileRepositoryProtocol
    let recipes: RecipeRepositoryProtocol
    let customIngredients: CustomIngredientRepositoryProtocol
    let mealLogs: MealLogRepositoryProtocol

    let ingredientCatalog: IngredientCatalogProtocol
    let exerciseCatalog: ExerciseCatalogProtocol

    init(
        auth: AuthServiceProtocol,
        firestore: FirestoreServiceProtocol,
        storage: StorageServiceProtocol,
        push: PushServiceProtocol,
        userProfiles: UserProfileRepositoryProtocol,
        recipes: RecipeRepositoryProtocol,
        customIngredients: CustomIngredientRepositoryProtocol,
        mealLogs: MealLogRepositoryProtocol,
        ingredientCatalog: IngredientCatalogProtocol,
        exerciseCatalog: ExerciseCatalogProtocol
    ) {
        self.auth = auth
        self.firestore = firestore
        self.storage = storage
        self.push = push
        self.userProfiles = userProfiles
        self.recipes = recipes
        self.customIngredients = customIngredients
        self.mealLogs = mealLogs
        self.ingredientCatalog = ingredientCatalog
        self.exerciseCatalog = exerciseCatalog
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            auth: FirebaseAuthService(),
            firestore: FirebaseFirestoreService(),
            storage: FirebaseStorageService(),
            push: FirebasePushService(),
            userProfiles: FirebaseUserProfileRepository(),
            recipes: FirebaseRecipeRepository(),
            customIngredients: FirebaseCustomIngredientRepository(),
            mealLogs: FirebaseMealLogRepository(),
            ingredientCatalog: BundledIngredientCatalog(),
            exerciseCatalog: BundledExerciseCatalog()
        )
    }
}
