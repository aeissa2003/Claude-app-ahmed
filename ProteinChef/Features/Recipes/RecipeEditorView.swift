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
        ZStack(alignment: .bottom) {
            Theme.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        coverBlock
                        titleBlock
                        quickStats
                        ingredientsBlock
                        stepsBlock
                        tagsBlock
                        galleryBlock
                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.top, Theme.Spacing.s)
                }
            }
            liveMacrosCard
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
        } message: { Text(vm.errorText ?? "") }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            PCIconButton(systemName: "xmark", variant: .paper) { dismiss() }
            Spacer()
            PCEyebrow(text: vm.editing == nil ? "New recipe" : "Edit recipe")
            Spacer()
            Button {
                Task { await save() }
            } label: {
                Text("Save")
                    .font(Theme.Fonts.ui(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(vm.isValid ? Theme.Colors.indigo : Theme.Colors.ink3)
                    .clipShape(Capsule())
            }
            .disabled(!vm.isValid || vm.isSaving)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.s)
    }

    // MARK: - Cover

    private var coverBlock: some View {
        Button {
            showingCoverPicker = true
        } label: {
            ZStack {
                if let image = vm.pendingImages["cover"] {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
                } else if let url = vm.coverPhotoURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill()
                        default: dashedPlaceholder
                        }
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.l))
                } else {
                    dashedPlaceholder
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var dashedPlaceholder: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.l)
            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            .foregroundStyle(Theme.Colors.line2)
            .frame(height: 200)
            .overlay {
                VStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Theme.Colors.ink3)
                    Text("Tap to add cover")
                        .font(Theme.Fonts.mono(11))
                        .tracking(1.0)
                        .foregroundStyle(Theme.Colors.ink3)
                }
            }
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Recipe name", text: $vm.title)
                .font(Theme.Fonts.display(26))
                .foregroundStyle(Theme.Colors.ink)
            Rectangle()
                .fill(Theme.Colors.line2)
                .frame(height: 1)
        }
    }

    // MARK: - Quick stats

    private var quickStats: some View {
        HStack(spacing: 10) {
            quickStatCell(label: "Servings",
                          value: servingsLabel,
                          onMinus: { if vm.servings > 1 { vm.servings -= 1 } },
                          onPlus:  { vm.servings += 1 })
            quickStatCell(label: "Prep",
                          value: "\(vm.prepMinutes) min",
                          onMinus: { vm.prepMinutes = max(0, vm.prepMinutes - 5) },
                          onPlus:  { vm.prepMinutes += 5 })
            quickStatCell(label: "Cook",
                          value: "\(vm.cookMinutes) min",
                          onMinus: { vm.cookMinutes = max(0, vm.cookMinutes - 5) },
                          onPlus:  { vm.cookMinutes += 5 })
        }
    }

    private func quickStatCell(label: String,
                               value: String,
                               onMinus: @escaping () -> Void,
                               onPlus: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            PCEyebrow(text: label)
            HStack(spacing: 8) {
                Button(action: onMinus) {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(Theme.Colors.ink.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                Text(value)
                    .font(Theme.Fonts.display(18))
                    .frame(maxWidth: .infinity)
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                        .frame(width: 22, height: 22)
                        .background(Theme.Colors.ink.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    private var servingsLabel: String {
        vm.servings.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(vm.servings))"
            : String(format: "%.1f", vm.servings)
    }

    // MARK: - Ingredients

    private var ingredientsBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .lastTextBaseline) {
                Text("Ingredients").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                Spacer()
                PCChip(text: "Add", style: .active, systemImage: "plus") {
                    showingIngredientPicker = true
                }
            }
            if vm.ingredients.isEmpty {
                Text("Add at least one ingredient — macros auto-calc from the catalog.")
                    .font(Theme.Fonts.ui(13))
                    .foregroundStyle(Theme.Colors.ink3)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(vm.ingredients.enumerated()), id: \.element.id) { idx, ing in
                        ingredientRow(index: idx + 1, ing: ing)
                    }
                }
            }
        }
    }

    private func ingredientRow(index: Int, ing: RecipeIngredient) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(Theme.Fonts.display(14))
                .foregroundStyle(Theme.Colors.protein)
                .frame(width: 26, height: 26)
                .background(Theme.Colors.protein.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button { editingIngredient = ing } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ing.ingredientName)
                        .font(Theme.Fonts.bodyStrong)
                        .foregroundStyle(Theme.Colors.ink)
                    Text("\(Int(ing.quantityG)) g · \(Int(ing.macrosAtEntry.kcal)) kcal")
                        .font(Theme.Fonts.mono(11))
                        .foregroundStyle(Theme.Colors.ink3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text("\(Int(ing.macrosAtEntry.proteinG))g")
                .font(Theme.Fonts.display(16))
                .foregroundStyle(Theme.Colors.protein)

            Button {
                if let idx = vm.ingredients.firstIndex(where: { $0.id == ing.id }) {
                    vm.removeIngredient(at: IndexSet(integer: idx))
                }
            } label: {
                Image(systemName: "xmark").font(.system(size: 12)).foregroundStyle(Theme.Colors.ink3)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.Colors.paper)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.m)
                .stroke(Theme.Colors.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
    }

    // MARK: - Steps

    private var stepsBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .lastTextBaseline) {
                Text("Method").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                Spacer()
                PCChip(text: "Add step", style: .outlined, systemImage: "plus") {
                    vm.addInstruction()
                }
            }
            VStack(spacing: 8) {
                ForEach($vm.instructions) { $step in
                    HStack(alignment: .top, spacing: 12) {
                        Text(String(format: "%02d", step.order + 1))
                            .font(Theme.Fonts.display(22))
                            .foregroundStyle(Theme.Colors.indigo)
                            .padding(.top, 4)
                        TextField("Step", text: $step.text, axis: .vertical)
                            .font(Theme.Fonts.ui(14))
                            .lineLimit(1...6)
                        Button {
                            if let idx = vm.instructions.firstIndex(where: { $0.id == step.id }) {
                                vm.removeInstruction(at: IndexSet(integer: idx))
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.Colors.ink3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Theme.Colors.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.m)
                            .stroke(Theme.Colors.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                }
            }
        }
    }

    // MARK: - Tags

    private var tagsBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("Tags").font(Theme.Fonts.sectionTitle).tracking(-0.5)
            if !vm.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(vm.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag).font(Theme.Fonts.ui(12, weight: .medium))
                                Button { vm.removeTag(tag) } label: {
                                    Image(systemName: "xmark").font(.system(size: 9))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.Colors.paper)
                            .overlay(Capsule().stroke(Theme.Colors.line, lineWidth: 1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            HStack {
                TextField("Add a tag", text: $vm.tagInput)
                    .textInputAutocapitalization(.never)
                    .padding(10)
                    .background(Theme.Colors.paper)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.Colors.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onSubmit { vm.addTag() }
                Button("Add") { vm.addTag() }
                    .font(Theme.Fonts.ui(14, weight: .semibold))
                    .disabled(vm.tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Gallery

    private var galleryBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .lastTextBaseline) {
                Text("Gallery").font(Theme.Fonts.sectionTitle).tracking(-0.5)
                Spacer()
                PCChip(text: "Add photo", style: .outlined, systemImage: "plus") {
                    showingGalleryPicker = true
                }
            }
            if !vm.galleryPhotoURLs.isEmpty || hasPendingGallery {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(vm.galleryPhotoURLs, id: \.self) { url in
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img): img.resizable().scaledToFill()
                                default: Theme.Colors.ink.opacity(0.05)
                                }
                            }
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                        }
                        ForEach(pendingGalleryKeys, id: \.self) { key in
                            if let image = vm.pendingImages[key] {
                                Image(uiImage: image)
                                    .resizable().scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
                            }
                        }
                    }
                }
            }
        }
    }

    private var hasPendingGallery: Bool {
        vm.pendingImages.keys.contains { $0.hasPrefix("gallery-") }
    }

    private var pendingGalleryKeys: [String] {
        vm.pendingImages.keys.filter { $0.hasPrefix("gallery-") }.sorted()
    }

    // MARK: - Live macros

    private var liveMacrosCard: some View {
        PCCard(style: .ink, padding: 14) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    PCEyebrow(text: "Per serving", color: Theme.Colors.ink4)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(Int(vm.perServing.proteinG))")
                            .font(Theme.Fonts.display(28))
                            .foregroundStyle(Theme.Colors.lime)
                        Text("g P")
                            .font(Theme.Fonts.ui(11))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Text("\(Int(vm.perServing.kcal)) kcal · \(Int(vm.perServing.carbsG))C · \(Int(vm.perServing.fatG))F")
                        .font(Theme.Fonts.mono(10))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
                Spacer()
                if vm.perServing.proteinG >= 25 {
                    Text("HIGH PROTEIN")
                        .font(Theme.Fonts.mono(9, weight: .semibold))
                        .tracking(1.0)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.lime)
                        .foregroundStyle(Theme.Colors.limeInk)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.m)
    }

    // MARK: - Save

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            ProgressView("Saving…")
                .padding(24)
                .background(Theme.Colors.paper)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.m))
        }
    }

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
