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
            ingredientCatalog: BundledIngredientCatalog(),
            exerciseCatalog: BundledExerciseCatalog()
        )
    }
}
