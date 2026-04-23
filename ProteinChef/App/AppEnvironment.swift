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
    let workouts: WorkoutRepositoryProtocol
    let workoutTemplates: WorkoutTemplateRepositoryProtocol
    let customExercises: CustomExerciseRepositoryProtocol
    let friends: FriendRepositoryProtocol
    let feed: FeedRepositoryProtocol
    let notifications: NotificationRepositoryProtocol
    let accountDeletion: AccountDeletionServiceProtocol

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
        workouts: WorkoutRepositoryProtocol,
        workoutTemplates: WorkoutTemplateRepositoryProtocol,
        customExercises: CustomExerciseRepositoryProtocol,
        friends: FriendRepositoryProtocol,
        feed: FeedRepositoryProtocol,
        notifications: NotificationRepositoryProtocol,
        accountDeletion: AccountDeletionServiceProtocol,
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
        self.workouts = workouts
        self.workoutTemplates = workoutTemplates
        self.customExercises = customExercises
        self.friends = friends
        self.feed = feed
        self.notifications = notifications
        self.accountDeletion = accountDeletion
        self.ingredientCatalog = ingredientCatalog
        self.exerciseCatalog = exerciseCatalog
    }

    static func live() -> AppEnvironment {
        let auth = FirebaseAuthService()
        return AppEnvironment(
            auth: auth,
            firestore: FirebaseFirestoreService(),
            storage: FirebaseStorageService(),
            push: FirebasePushService(),
            userProfiles: FirebaseUserProfileRepository(),
            recipes: FirebaseRecipeRepository(),
            customIngredients: FirebaseCustomIngredientRepository(),
            mealLogs: FirebaseMealLogRepository(),
            workouts: FirebaseWorkoutRepository(),
            workoutTemplates: FirebaseWorkoutTemplateRepository(),
            customExercises: FirebaseCustomExerciseRepository(),
            friends: FirebaseFriendRepository(),
            feed: FirebaseFeedRepository(),
            notifications: FirebaseNotificationRepository(),
            accountDeletion: AccountDeletionService(auth: auth),
            ingredientCatalog: BundledIngredientCatalog(),
            exerciseCatalog: BundledExerciseCatalog()
        )
    }
}
