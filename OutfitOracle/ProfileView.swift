//
//  ProfileView.swift
//  OutfitOracle
//
//  Created by Guru Sanka on 2/28/26.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ProfileView: View {
    @AppStorage(PrefKeys.name) private var name = ""
    @AppStorage(PrefKeys.photo) private var photoData = Data()

    @State private var photoItem: PhotosPickerItem?
    @State private var editingName = false
    @State private var draftName = ""
    @State private var sheet: ProfileSheet?

    enum ProfileSheet: String, Identifiable {
        case stats, settings, accessibility, archives
        var id: String { rawValue }
    }

    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]

    var body: some View {
        ZStack {
            // Background
            Color.ooCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // Top Header
                    VStack(spacing: 16) {
                        Spacer().frame(height: 12)

                        // Profile Image
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Circle()
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 150, height: 150)
                                .overlay {
                                    if let image = UIImage(data: photoData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 70)
                                            .foregroundColor(.ooCream)
                                    }
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.ooButter)
                                }
                        }
                        .accessibilityLabel("Change profile photo")

                        // Name
                        Button {
                            draftName = name
                            editingName = true
                        } label: {
                            Text(name.isEmpty ? "Tap to add your name" : name)
                                .font(.largeTitle.bold())
                                .foregroundColor(.ooLightText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .padding(.horizontal)
                        }

                        Spacer().frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.brown)

                    // Grid buttons
                    LazyVGrid(columns: columns, spacing: 20) {
                        ProfileCard(icon: "chart.bar.fill", title: "Stats") { sheet = .stats }
                        ProfileCard(icon: "gearshape.fill", title: "Settings") { sheet = .settings }
                        ProfileCard(icon: "slider.horizontal.3", title: "Accessibility") { sheet = .accessibility }
                        ProfileCard(icon: "archivebox.fill", title: "Archives") { sheet = .archives }
                    }
                    .padding(24)
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoData = GarmentDetectionService.normalized(image, maxSide: 400)
                        .jpegData(compressionQuality: 0.8) ?? Data()
                }
                photoItem = nil
            }
        }
        .alert("Your name", isPresented: $editingName) {
            TextField("Name", text: $draftName)
            Button("Save") { name = draftName.trimmingCharacters(in: .whitespaces) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .stats: StatsView()
            case .settings: SettingsView()
            case .accessibility: AccessibilitySettingsView()
            case .archives: ArchivesView()
            }
        }
    }

    struct ProfileCard: View {
        let icon: String
        let title: String
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(Color.brown)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(Color.brown)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.ooButter)
                .cornerRadius(25)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Settings: style preferences + trend updates + demo data
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TrendService.self) private var trends
    @AppStorage(PrefKeys.favoriteColors) private var favoriteColorsRaw = ""
    @AppStorage(PrefKeys.styles) private var stylesRaw = ""
    @AppStorage(PrefKeys.checkForTrends) private var checkForTrends = true
    @State private var sampleLoaded = false

    static let styleOptions = ["Casual", "Streetwear", "Preppy", "Minimal", "Boho", "Sporty", "Formal"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    FlowChips(options: Vocabulary.colors, selected: binding(for: $favoriteColorsRaw)) { color in
                        HStack(spacing: 4) {
                            ColorSwatch(hex: Vocabulary.hex(for: color), size: 12)
                            Text(color.capitalizedFirst)
                        }
                    }
                } header: {
                    Text("Colors you love")
                } footer: {
                    Text("The Oracle gives outfits with these colors a small boost.")
                }

                Section("Your style") {
                    FlowChips(options: Self.styleOptions, selected: binding(for: $stylesRaw)) { Text($0) }
                }

                Section {
                    Toggle("Check for new trends", isOn: $checkForTrends)
                        .tint(.brown)
                    Button("Check now") { Task { await trends.refresh() } }
                } header: {
                    Text("Trends")
                } footer: {
                    Text("Trend feed: \(trends.feed.season) (v\(trends.feed.version))")
                }

                Section {
                    Button(sampleLoaded ? "Sample closet added" : "Load sample closet") {
                        SampleData.load(into: modelContext)
                        sampleLoaded = true
                    }
                    .disabled(sampleLoaded)
                } header: {
                    Text("Demo")
                } footer: {
                    Text("Adds example clothes so you can try outfits and trends right away.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ooCream)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.brown)
    }

    /// Stores a set of strings as a comma-separated @AppStorage value
    private func binding(for raw: Binding<String>) -> Binding<Set<String>> {
        Binding(
            get: { Set(raw.wrappedValue.split(separator: ",").map(String.init)) },
            set: { raw.wrappedValue = $0.sorted().joined(separator: ",") }
        )
    }
}

/// Multi-select chips that wrap onto new lines
struct FlowChips<ChipLabel: View>: View {
    let options: [String]
    @Binding var selected: Set<String>
    @ViewBuilder var label: (String) -> ChipLabel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isOn = selected.contains(option)
                Button {
                    if isOn { selected.remove(option) } else { selected.insert(option) }
                } label: {
                    label(option)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isOn ? Color.ooBrown : Color.ooButter)
                        .foregroundColor(isOn ? .ooLightText : .ooBrown)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Accessibility
struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKeys.highContrast) private var highContrast = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("High-contrast text", isOn: $highContrast)
                        .tint(.brown)
                } footer: {
                    Text("Uses dark brown text on the pink cards so it's easier to read. Outfit Oracle also follows your iPhone's text size setting.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ooCream)
            .navigationTitle("Accessibility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.brown)
    }
}

// MARK: - Archives: pieces you've passed on (restorable)
struct ArchivesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WardrobeItem> { $0.isArchived },
           sort: \WardrobeItem.dateAdded, order: .reverse)
    private var archived: [WardrobeItem]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                if archived.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 44))
                        Text("Nothing archived")
                            .font(.headline)
                        Text("Items you sell, donate or retire show up here.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(.ooBrown)
                    .padding()
                } else {
                    List {
                        ForEach(archived) { item in
                            HStack {
                                ItemThumbnail(item: item, height: 60)
                                    .frame(width: 60)
                                Text(item.name)
                                Spacer()
                                Button("Restore") {
                                    item.isArchived = false
                                    try? modelContext.save()
                                }
                                .buttonStyle(.bordered)
                            }
                            .listRowBackground(Color.ooButter)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Archives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.brown)
    }
}
