//
//  Camera.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/25/26.
//

import PhotosUI
import SwiftData
import SwiftUI

struct UploadView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var photoItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showCamera = false
    @State private var isAnalyzing = false
    @State private var manualMode = false
    @State private var drafts: [GarmentDraft] = []
    @State private var showReview = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 15) {

                // MARK: Hint Bar (same shape as the search bar)
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text(manualMode ? "Adding shoes or accessories" : "Snap an outfit or a single piece")
                        .foregroundColor(.brown.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Image(systemName: "sparkles")
                }
                .foregroundColor(.brown)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color.brown, lineWidth: 2)
                )
                .padding(.horizontal)


                // MARK: Outfit Image (grows/shrinks with the screen)
                ZStack {
                    if let pickedImage {
                        Image(uiImage: pickedImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image("outfit_sample")
                            .resizable()
                            .scaledToFill()
                            .overlay(Color.black.opacity(0.25))
                            .overlay(
                                Text("Take or upload a photo\nof your clothes")
                                    .font(.headline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white)
                            )
                    }

                    if isAnalyzing {
                        Color.black.opacity(0.35)
                        VStack(spacing: 10) {
                            ProgressView().tint(.white).scaleEffect(1.4)
                            Text("The Oracle is looking at your clothes…")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .padding(.horizontal)


                // MARK: Buttons, Upload & retake
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Text("Upload")
                }
                .buttonStyle(OOButtonStyle())
                .padding(.horizontal)
                .disabled(isAnalyzing)

                if CameraPicker.isAvailable {
                    Button(pickedImage == nil ? "Take Photo" : "Retake") {
                        showCamera = true
                    }
                    .buttonStyle(OOButtonStyle())
                    .padding(.horizontal)
                    .disabled(isAnalyzing)
                }

                Button {
                    manualMode.toggle()
                } label: {
                    Label(manualMode ? "Back to auto-detect" : "Add shoes or accessories manually",
                          systemImage: manualMode ? "wand.and.stars" : "hand.point.up.left")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.brown)
                }
            }
            .padding(.vertical)
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await analyze(image)
                }
                photoItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                Task { await analyze(image) }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showReview) {
            ReviewGarmentsSheet(drafts: $drafts) {
                save()
            }
        }
        .alert("Couldn't read that photo", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Actions
    private func analyze(_ image: UIImage) async {
        pickedImage = image
        isAnalyzing = true
        defer { isAnalyzing = false }

        if manualMode {
            let data = GarmentDetectionService.normalized(image, maxSide: 1024).jpegData(compressionQuality: 0.8) ?? Data()
            let (color, hex) = ColorExtractor.dominantColor(of: image)
            drafts = [GarmentDraft(image: image, imageData: data, role: .shoes, color: color,
                                   colorHex: hex, pattern: "solid", fabric: "unknown",
                                   styleTag: "casual", detectorLabel: "shoes")]
            showReview = true
            return
        }

        guard let service = GarmentDetectionService.shared else {
            errorMessage = GarmentDetectionService.DetectionError.modelNotLoaded.localizedDescription
            return
        }
        do {
            let garments = try await service.detectGarments(in: image)
            drafts = garments.map(GarmentDraft.init)
            showReview = !drafts.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        for draft in drafts where draft.keep {
            let item = WardrobeItem(
                croppedImageData: draft.imageData,
                category: draft.detectorLabel,
                role: draft.role,
                color: draft.color,
                colorHex: draft.colorHex,
                pattern: draft.pattern,
                styleTag: draft.styleTag,
                fabricType: draft.fabric,
                name: draft.name.isEmpty ? nil : draft.name
            )
            modelContext.insert(item)
        }
        try? modelContext.save()
        drafts = []
        pickedImage = nil
        manualMode = false
        showReview = false
        appState.selectedTab = .closet
    }
}

extension GarmentDetectionService {
    /// Loaded once; nil if the models are missing from the bundle
    static let shared: GarmentDetectionService? = try? GarmentDetectionService()
}

// MARK: - Editable result from the detector
struct GarmentDraft: Identifiable {
    let id = UUID()
    let image: UIImage?
    let imageData: Data
    var role: GarmentRole
    var color: String
    var colorHex: String
    var pattern: String
    var fabric: String
    var styleTag: String
    var detectorLabel: String
    var name: String = ""
    var keep = true

    init(image: UIImage?, imageData: Data, role: GarmentRole, color: String, colorHex: String,
         pattern: String, fabric: String, styleTag: String, detectorLabel: String) {
        self.image = image
        self.imageData = imageData
        self.role = role
        self.color = color
        self.colorHex = colorHex
        self.pattern = pattern
        self.fabric = fabric
        self.styleTag = styleTag
        self.detectorLabel = detectorLabel
    }

    init(_ garment: DetectedGarment) {
        self.init(image: garment.image, imageData: garment.imageData, role: garment.role,
                  color: garment.color, colorHex: garment.colorHex, pattern: garment.pattern,
                  fabric: garment.fabric, styleTag: garment.styleTag, detectorLabel: garment.detectorLabel)
    }
}

// MARK: - Review sheet: fix anything the ML got wrong before saving
struct ReviewGarmentsSheet: View {
    @Binding var drafts: [GarmentDraft]
    var onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Found \(drafts.count) item\(drafts.count == 1 ? "" : "s"). Check the details, then save.")
                            .font(.subheadline)
                            .foregroundColor(.ooBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach($drafts) { $draft in
                            DraftCard(draft: $draft)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save to closet") { onSave() }
                        .bold()
                        .disabled(!drafts.contains { $0.keep })
                }
            }
        }
        .tint(.brown)
    }
}

struct DraftCard: View {
    @Binding var draft: GarmentDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Group {
                    if let image = draft.image {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Color.ooBlue
                    }
                }
                .frame(width: 96, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 15))

                VStack(alignment: .leading, spacing: 6) {
                    TextField(WardrobeItem.defaultName(color: draft.color, fabric: draft.fabric, role: draft.role),
                              text: $draft.name)
                        .font(.headline)
                        .textFieldStyle(.roundedBorder)
                    Toggle("Keep", isOn: $draft.keep)
                        .tint(.brown)
                    HStack {
                        ColorSwatch(hex: draft.colorHex)
                        Text(draft.color.capitalizedFirst)
                            .font(.caption)
                    }
                }
            }

            AttributePicker(title: "Type", selection: $draft.role, options: GarmentRole.allCases) { $0.singular.capitalizedFirst }
            AttributePicker(title: "Color", selection: Binding(
                get: { draft.color },
                set: { draft.color = $0; draft.colorHex = Vocabulary.hex(for: $0) }
            ), options: Vocabulary.colors) { $0.capitalizedFirst }
            AttributePicker(title: "Pattern", selection: $draft.pattern, options: Vocabulary.patterns) { $0.capitalizedFirst }
            AttributePicker(title: "Fabric", selection: $draft.fabric, options: Vocabulary.fabrics) { $0.capitalizedFirst }
        }
        .foregroundColor(.ooBrown)
        .padding()
        .background(Color.ooButter)
        .cornerRadius(20)
        .opacity(draft.keep ? 1 : 0.5)
    }
}

struct AttributePicker<Option: Hashable>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        HStack {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(.brown)
        }
    }
}
