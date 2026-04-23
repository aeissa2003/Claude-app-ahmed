import SwiftUI
import UIKit

struct RecipeEditorView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var vm: RecipeEditorViewModel
    @State private var showingCoverPicker = false
    @State private var showingGalleryPicker = false
    @State private var showingIngredientPicker = false
    @State private var editingIngredient: RecipeIngredient?
    @State private var ingredientPhotoPickerTargetId: String?
    @State private var showingIngredientPhotoPicker = false

    init(uid: String, editing: Recipe? = nil) {
        _vm = State(initialValue: RecipeEditorViewModel(uid: uid, editing: editing))
    }

    var body: some View {
        NavigationStack {
            Form {
                coverSection
                basicsSection
                macrosSection
                ingredientsSection
                instructionsSection
                tagsSection
                gallerySection
            }
            .navigationTitle(vm.editing == nil ? "New recipe" : "Edit recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!vm.isValid || vm.isSaving)
                }
            }
            .overlay { if vm.isSaving { savingOverlay } }
            .photoPicker(isPresented: $showingCoverPicker) { image in
                vm.setCoverImage(image)
            }
            .photoPicker(isPresented: $showingGalleryPicker) { image in
                vm.addGalleryImage(image)
            }
            .photoPicker(isPresented: $showingIngredientPhotoPicker) { image in
                if let id = ingredientPhotoPickerTargetId {
                    vm.setIngredientImage(image, for: id)
                }
                ingredientPhotoPickerTargetId = nil
            }
            .sheet(isPresented: $showingIngredientPicker) {
                IngredientPickerView { newIngredient in
                    vm.addIngredient(newIngredient)
                }
                .environment(env)
            }
            .sheet(item: $editingIngredient) { ing in
                IngredientPickerView(editing: ing) { updated in
                    vm.updateIngredient(updated)
                }
                .environment(env)
            }
            .alert("Couldn’t save", isPresented: .constant(vm.errorText != nil)) {
                Button("OK") { vm.errorText = nil }
            } message: {
                Text(vm.errorText ?? "")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder private var coverSection: some View {
        Section {
            coverPreview
                .onTapGesture { showingCoverPicker = true }
        } footer: {
            Text("Tap to add a cover photo")
        }
    }

    @ViewBuilder private var coverPreview: some View {
        ZStack {
            if let image = vm.pendingImages["cover"] {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let url = vm.coverPhotoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            VStack(spacing: 6) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Add cover photo").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var basicsSection: some View {
        Section("Basics") {
            TextField("Title", text: $vm.title)
            Stepper(value: $vm.prepMinutes, in: 0...240, step: 5) {
                HStack { Text("Prep"); Spacer(); Text("\(vm.prepMinutes) min").foregroundStyle(.secondary) }
            }
            Stepper(value: $vm.cookMinutes, in: 0...240, step: 5) {
                HStack { Text("Cook"); Spacer(); Text("\(vm.cookMinutes) min").foregroundStyle(.secondary) }
            }
            Stepper(value: $vm.servings, in: 1...50, step: 1) {
                HStack { Text("Servings"); Spacer(); Text(servingsLabel).foregroundStyle(.secondary) }
            }
        }
    }

    private var servingsLabel: String {
        vm.servings.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(vm.servings))"
            : String(format: "%.1f", vm.servings)
    }

    private var macrosSection: some View {
        Section("Per serving") {
            HStack(spacing: Theme.Spacing.m) {
                macroCell("Protein", "\(Int(vm.perServing.proteinG))g", Theme.Colors.protein)
                macroCell("Carbs",   "\(Int(vm.perServing.carbsG))g",   Theme.Colors.carbs)
                macroCell("Fat",     "\(Int(vm.perServing.fatG))g",     Theme.Colors.fat)
                macroCell("Kcal",    "\(Int(vm.perServing.kcal))",       Theme.Colors.kcal)
            }
            .padding(.vertical, 4)
        }
    }

    private func macroCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundStyle(color)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
    }

    private var ingredientsSection: some View {
        Section {
            ForEach(vm.ingredients) { ing in
                ingredientRow(ing)
                    .contentShape(Rectangle())
                    .onTapGesture { editingIngredient = ing }
            }
            .onDelete(perform: vm.removeIngredient)

            Button {
                showingIngredientPicker = true
            } label: {
                Label("Add ingredient", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Ingredients")
        } footer: {
            if vm.ingredients.isEmpty {
                Text("At least one ingredient is required.")
            }
        }
    }

    private func ingredientRow(_ ing: RecipeIngredient) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            ingredientThumb(ing)
                .onTapGesture {
                    ingredientPhotoPickerTargetId = ing.id
                    showingIngredientPhotoPicker = true
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(ing.ingredientName).font(.subheadline)
                Text(quantityLabel(ing) + " · \(Int(ing.macrosAtEntry.proteinG))g P · \(Int(ing.macrosAtEntry.kcal)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder private func ingredientThumb(_ ing: RecipeIngredient) -> some View {
        Group {
            if let image = vm.pendingImages[ing.id] {
                Image(uiImage: image).resizable().scaledToFill()
            } else if let url = ing.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.secondary.opacity(0.1)
                    }
                }
            } else {
                ZStack {
                    Color.secondary.opacity(0.1)
                    Image(systemName: "camera").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
    }

    private func quantityLabel(_ ing: RecipeIngredient) -> String {
        let q = ing.displayQuantity
        let formatted = q.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(q))"
            : String(format: "%.2f", q)
        return "\(formatted) \(ing.displayUnit)"
    }

    private var instructionsSection: some View {
        Section("Instructions") {
            ForEach($vm.instructions) { $step in
                HStack(alignment: .top, spacing: Theme.Spacing.s) {
                    Text("\(step.order + 1).").fontWeight(.semibold).padding(.top, 8)
                    TextField("Step", text: $step.text, axis: .vertical)
                        .lineLimit(1...6)
                }
            }
            .onDelete(perform: vm.removeInstruction)

            Button {
                vm.addInstruction()
            } label: {
                Label("Add step", systemImage: "plus.circle.fill")
            }
        }
    }

    private var tagsSection: some View {
        Section("Tags") {
            if !vm.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(vm.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)").font(.caption)
                                Button {
                                    vm.removeTag(tag)
                                } label: {
                                    Image(systemName: "xmark.circle.fill").font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            HStack {
                TextField("Add a tag", text: $vm.tagInput)
                    .textInputAutocapitalization(.never)
                    .onSubmit { vm.addTag() }
                Button("Add") { vm.addTag() }
                    .disabled(vm.tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var gallerySection: some View {
        Section("Gallery") {
            if !vm.galleryPhotoURLs.isEmpty || hasPendingGallery {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(vm.galleryPhotoURLs, id: \.self) { url in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                default: Color.secondary.opacity(0.1)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                        }
                        ForEach(pendingGalleryKeys, id: \.self) { key in
                            if let image = vm.pendingImages[key] {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.s))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            Button {
                showingGalleryPicker = true
            } label: {
                Label("Add photo to gallery", systemImage: "plus.circle.fill")
            }
        }
    }

    private var hasPendingGallery: Bool {
        vm.pendingImages.keys.contains { $0.hasPrefix("gallery-") }
    }

    private var pendingGalleryKeys: [String] {
        vm.pendingImages.keys
            .filter { $0.hasPrefix("gallery-") }
            .sorted()
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: Theme.Spacing.s) {
                ProgressView()
                Text("Saving…").font(.footnote).foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
    }

    // MARK: - Save

    private func save() async {
        vm.isSaving = true
        defer { vm.isSaving = false }
        do {
            let recipeId = vm.editing?.id ?? UUID().uuidString

            if let cover = vm.pendingImages["cover"],
               let data = ImageCompressor.jpegData(from: cover) {
                let path = "users/\(vm.uid)/recipes/\(recipeId)/cover.jpg"
                let url = try await env.storage.uploadJPEG(data, to: path)
                vm.coverPhotoURL = url
                vm.pendingImages.removeValue(forKey: "cover")
            }

            for key in pendingGalleryKeys {
                guard let image = vm.pendingImages[key],
                      let data = ImageCompressor.jpegData(from: image) else { continue }
                let filename = "\(UUID().uuidString).jpg"
                let path = "users/\(vm.uid)/recipes/\(recipeId)/gallery/\(filename)"
                let url = try await env.storage.uploadJPEG(data, to: path)
                vm.galleryPhotoURLs.append(url)
                vm.pendingImages.removeValue(forKey: key)
            }

            for idx in vm.ingredients.indices {
                let ing = vm.ingredients[idx]
                guard let image = vm.pendingImages[ing.id],
                      let data = ImageCompressor.jpegData(from: image) else { continue }
                let path = "users/\(vm.uid)/recipes/\(recipeId)/ingredients/\(ing.id).jpg"
                let url = try await env.storage.uploadJPEG(data, to: path)
                vm.ingredients[idx].photoURL = url
                vm.pendingImages.removeValue(forKey: ing.id)
            }

            var snapshot = vm.snapshot()
            snapshot.id = recipeId
            try await env.recipes.save(snapshot)
            dismiss()
        } catch {
            vm.errorText = error.localizedDescription
        }
    }
}
