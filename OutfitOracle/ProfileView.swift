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
        case stats, settings, accessibility, archives, about, guide
        var id: String { rawValue }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query private var outfits: [SavedOutfit]
    private var rewears: Int { items.reduce(0) { $0 + max(0, $1.wearCount - 1) } }
    private var wornThisMonthPercent: Int {
        guard !items.isEmpty else { return 0 }
        let worn = items.filter { $0.lastWorn != nil && $0.daysSinceWorn < 30 }.count
        return Int((Double(worn) / Double(items.count) * 100).rounded())
    }

    private func impactTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption2).multilineTextAlignment(.center).lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .padding(6)
        .background(Color.ooCream)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }

    var body: some View {
        ZStack {
            // Background
            Color.ooCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // Compact header: photo + name + quick numbers on one row
                    HStack(spacing: 14) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Circle()
                                .fill(Color.ooBlue)
                                .frame(width: 76, height: 76)
                                .overlay {
                                    if let image = UIImage(data: photoData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 34))
                                            .foregroundColor(.ooCream)
                                    }
                                }
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.ooButter)
                                }
                        }
                        .accessibilityLabel("Change profile photo")

                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                draftName = name
                                editingName = true
                            } label: {
                                Text(name.isEmpty ? "Tap to add your name" : name)
                                    .font(.title2.bold())
                                    .foregroundColor(.ooLightText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            Text("\(items.count) items · \(outfits.count) outfits · \(rewears) re-wears")
                                .font(.caption)
                                .foregroundColor(.ooLightText.opacity(0.85))
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.ooBrown)

                    // Grid buttons
                    LazyVGrid(columns: columns, spacing: 12) {
                        ProfileCard(icon: "chart.bar.fill", title: "Stats") { sheet = .stats }
                        ProfileCard(icon: "gearshape.fill", title: "Settings") { sheet = .settings }
                        ProfileCard(icon: "slider.horizontal.3", title: "Accessibility") { sheet = .accessibility }
                        ProfileCard(icon: "archivebox.fill", title: "Archives") { sheet = .archives }
                        ProfileCard(icon: "info.circle.fill", title: "About & Privacy") { sheet = .about }
                        ProfileCard(icon: "book.fill", title: "How it works") { sheet = .guide }
                    }
                    .padding()

                    // At-a-glance impact (full details under Stats)
                    Button { sheet = .stats } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Your impact", systemImage: "leaf.fill")
                                .font(.headline)
                            HStack(spacing: 8) {
                                impactTile("\(rewears)", "re-wears")
                                impactTile("\(wornThisMonthPercent)%", "closet worn this month")
                                impactTile("\(items.filter(\.isForgotten).count)", "not worn lately")
                            }
                        }
                        .foregroundColor(.ooBrown)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.ooButter)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Most-loved pieces (what you actually re-wear)
                    let loved = items.filter { $0.wearCount > 0 }.sorted { $0.wearCount > $1.wearCount }.prefix(10)
                    if !loved.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Most-loved pieces")
                                .font(.headline)
                                .foregroundColor(.ooBrown)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(loved)) { item in
                                        VStack(spacing: 2) {
                                            ItemThumbnail(item: item, height: 80)
                                                .frame(width: 76)
                                            Text("\(item.wearCount)× worn")
                                                .font(.caption2)
                                                .foregroundColor(.ooBrown)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
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
            case .about: AboutView()
            case .guide: HowItWorksGuideView()
            }
        }
    }

    struct ProfileCard: View {
        let icon: String
        let title: String
        var action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(Color.ooBrown)

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.ooBrown)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, minHeight: 84)
                .background(Color.ooButter)
                .cornerRadius(18)
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
    @AppStorage(PrefKeys.gender) private var genderRaw = Gender.unspecified.rawValue
    @AppStorage(PrefKeys.styleNotes) private var styleNotes = ""
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
                    TextField("e.g. comfy, earthy colors, no leather", text: $styleNotes, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    Text("In your own words")
                } footer: {
                    Text("The Oracle avoids what you say no to and favors what you like.")
                }

                Section {
                    Picker("I am", selection: $genderRaw) {
                        ForEach(Gender.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                } footer: {
                    Text("Used to show the right section in shop links.")
                }

                Section {
                    Toggle("Check for new trends", isOn: $checkForTrends)
                        .tint(.ooBrown)
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
            .keyboardDoneButton()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(.ooBrown)
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
    var minWidth: CGFloat = 96
    @ViewBuilder var label: (String) -> ChipLabel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth), spacing: 8)], spacing: 8) {
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
                        .tint(.ooBrown)
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
        .tint(.ooBrown)
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
        .tint(.ooBrown)
    }
}
