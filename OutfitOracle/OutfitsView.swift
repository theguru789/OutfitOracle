//
//  OutfitsView.swift
//  OutfitOracle
//
//  Closet ▸ Outfits: outfits you put together and named, the Oracle's advice
//  for each one, and Oracle picks you can save.
//

import SwiftData
import SwiftUI

/// Shown in Closet when the switch is on "Outfits"
struct ClosetOutfitsList: View {
    @Binding var showBuilder: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \SavedOutfit.dateCreated, order: .reverse) private var outfits: [SavedOutfit]
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]
    @Query(sort: \WearLog.date, order: .reverse) private var logs: [WearLog]

    @State private var selected: SavedOutfit?
    @State private var picks: [Outfit] = []
    @State private var pickToSave: Outfit?
    @State private var newName = ""

    var body: some View {
        let lookup = ClosetContext(items: items, logs: logs).lookup

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if outfits.isEmpty {
                    Button {
                        showBuilder = true
                    } label: {
                        Label("Make your first outfit", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.ooButter)
                            .foregroundColor(.ooBrown)
                            .cornerRadius(20)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                    ForEach(outfits) { outfit in
                        Button {
                            selected = outfit
                        } label: {
                            SavedOutfitCard(outfit: outfit, lookup: lookup)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !picks.isEmpty {
                    Label("Oracle picks for you", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundColor(.ooBrown)
                        .padding(.top, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(picks) { pick in
                                VStack(spacing: 8) {
                                    OutfitFlatLay(outfit: pick, lookup: lookup, height: 200)
                                    Text("\(pick.percent)% match")
                                        .font(.caption.bold())
                                    Button {
                                        newName = OutfitEngine.suggestedName(for: pick.items)
                                        pickToSave = pick
                                    } label: {
                                        Label("Save", systemImage: "plus")
                                            .font(.subheadline.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(Color.ooBrown)
                                            .foregroundColor(.ooLightText)
                                            .cornerRadius(12)
                                    }
                                }
                                .foregroundColor(.ooBrown)
                                .frame(width: 180)
                                .padding(10)
                                .background(Color.ooButter)
                                .cornerRadius(20)
                            }
                        }
                    }
                }
            }
            .padding()
            .padding(.bottom, 70)   // room for the floating + button
        }
        .task(id: items.count) {
            picks = await ClosetContext(items: items, logs: logs)
                .suggest(weather: appState.weather, count: 4)
        }
        .sheet(item: $selected) { SavedOutfitDetailView(outfit: $0) }
        .alert("Name this outfit", isPresented: Binding(
            get: { pickToSave != nil }, set: { if !$0 { pickToSave = nil } }
        )) {
            TextField("Outfit name", text: $newName)
            Button("Save") {
                if let pick = pickToSave {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    modelContext.insert(SavedOutfit(name: name.isEmpty ? OutfitEngine.suggestedName(for: pick.items) : name,
                                                    itemIDs: pick.itemIDs))
                    try? modelContext.save()
                }
                pickToSave = nil
            }
            Button("Cancel", role: .cancel) { pickToSave = nil }
        }
    }
}

// MARK: - Card in the grid
struct SavedOutfitCard: View {
    let outfit: SavedOutfit
    let lookup: [UUID: WardrobeItem]
    @State private var percent: Int?

    private var pieces: [WardrobeItem] { outfit.itemIDs.compactMap { lookup[$0] } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            OutfitCollage(items: pieces, height: 130)
            Text(outfit.name)
                .font(.caption.bold())
                .lineLimit(1)
            if let percent {
                Text("\(percent)% match")
                    .font(.caption2)
            }
        }
        .foregroundColor(.ooBrown)
        .padding(6)
        .background(Color.ooButter)
        .cornerRadius(16)
        .task(id: outfit.itemIDs) {
            let score = OutfitEngine.shared.modelScore(OutfitEngine.normalized(pieces.map(\.snapshot)))
            percent = Int((min(max(score, 0), 1) * 100).rounded())
        }
    }
}

// MARK: - Detail: big picture, rename, Oracle's advice, wear / share / delete
struct SavedOutfitDetailView: View {
    @Bindable var outfit: SavedOutfit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }) private var items: [WardrobeItem]

    @State private var advice: OutfitAdvice?
    @State private var logged = false
    @State private var confirmDelete = false

    private var lookup: [UUID: WardrobeItem] {
        Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }
    private var pieces: [WardrobeItem] { outfit.itemIDs.compactMap { lookup[$0] } }
    private var asOutfit: Outfit {
        let snaps = pieces.map(\.snapshot)
        let score = OutfitEngine.shared.modelScore(OutfitEngine.normalized(snaps))
        return Outfit(items: snaps, modelScore: score, score: score, reasons: [])
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        OutfitCollage(items: pieces, height: 400)

                        TextField("Outfit name", text: $outfit.name)
                            .font(.title3.bold())
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)

                        Text("\(asOutfit.percent)% style match")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ooBrown)
                            .foregroundColor(.ooLightText)
                            .cornerRadius(12)

                        if let advice {
                            AdviceCard(advice: advice) { change in
                                outfit.itemIDs = change.map(\.id)
                                try? modelContext.save()
                                refreshAdvice()
                            }
                        }

                        HStack(spacing: 12) {
                            Button(logged ? "Logged!" : "Wear this") {
                                ClosetContext.logWear(asOutfit, lookup: lookup, in: modelContext)
                                outfit.wearCount += 1
                                outfit.lastWorn = Date()
                                logged = true
                            }
                            .buttonStyle(OOButtonStyle())
                            .disabled(logged)
                            .sensoryFeedback(.success, trigger: logged)

                            ShareOutfitButton(outfit: asOutfit, lookup: lookup)
                        }

                        Text(outfit.wearCount == 0 ? "Not worn yet" : "Worn \(outfit.wearCount) time\(outfit.wearCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.ooBrown)

                        Button("Delete outfit", role: .destructive) { confirmDelete = true }
                            .font(.footnote)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(outfit.name)
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { try? modelContext.save(); dismiss() }
                }
            }
            .confirmationDialog("Delete \(outfit.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(outfit)
                    try? modelContext.save()
                    dismiss()
                }
            } message: {
                Text("Your clothes stay in your closet.")
            }
            .task { refreshAdvice() }
        }
        .tint(.ooBrown)
    }

    private func refreshAdvice() {
        advice = OutfitEngine.shared.recommendation(for: pieces.map(\.snapshot),
                                                    closet: items.map(\.snapshot),
                                                    weather: appState.weather)
    }
}

/// "Oracle says: swap X for Y (+8% match)" with an Apply button
struct AdviceCard: View {
    let advice: OutfitAdvice
    var onApply: ([ItemSnapshot]) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Oracle recommends", systemImage: "sparkles")
                .font(.headline)
            Text(advice.text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            if let change = advice.change {
                Button {
                    onApply(change)
                } label: {
                    Label("Apply", systemImage: "wand.and.stars")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.ooBrown)
                        .foregroundColor(.ooLightText)
                        .cornerRadius(12)
                }
            }
        }
        .foregroundColor(.ooDeepBrown)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ooLatte)
        .cornerRadius(18)
    }
}

// MARK: - Builder: pick pieces, name it, see the picture + advice live
struct OutfitBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(filter: #Predicate<WardrobeItem> { !$0.isArchived }, sort: \WardrobeItem.dateAdded)
    private var items: [WardrobeItem]

    @State private var selection: [GarmentRole: UUID] = [:]
    @State private var name = ""
    @State private var nameEdited = false
    @State private var advice: OutfitAdvice?

    private let roles: [GarmentRole] = [.top, .bottom, .dress, .outerwear, .shoes, .accessory]

    private var chosen: [WardrobeItem] {
        roles.compactMap { role in selection[role].flatMap { id in items.first { $0.id == id } } }
    }
    private var isWearable: Bool {
        selection[.dress] != nil || (selection[.top] != nil && selection[.bottom] != nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Name your outfit", text: Binding(
                            get: { name }, set: { name = $0; nameEdited = true }
                        ))
                        .font(.headline)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)

                        if chosen.isEmpty {
                            Text("Pick a top and bottom, or a dress.")
                                .font(.subheadline)
                                .foregroundColor(.ooBrown)
                                .frame(maxWidth: .infinity, minHeight: 120)
                                .background(Color.white.opacity(0.5))
                                .cornerRadius(20)
                        } else {
                            OutfitCollage(items: chosen, height: 280)
                        }

                        if isWearable, let advice {
                            AdviceCard(advice: advice) { change in
                                selection = Dictionary(change.map { ($0.role, $0.id) }, uniquingKeysWith: { first, _ in first })
                            }
                        }

                        ForEach(roles) { role in
                            let options = items.filter { $0.role == role }
                            if !options.isEmpty {
                                Text(role.displayName).font(.headline).foregroundColor(.ooBrown)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(options) { item in
                                            Button {
                                                toggle(item)
                                            } label: {
                                                ItemThumbnail(item: item, height: 90)
                                                    .frame(width: 80)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .stroke(selection[role] == item.id ? Color.ooBrown : .clear, lineWidth: 3)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityAddTraits(selection[role] == item.id ? .isSelected : [])
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New outfit")
            .navigationBarTitleDisplayMode(.inline)
            .keyboardDoneButton()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(!isWearable)
                }
            }
            .onChange(of: selection) { _, _ in
                if !nameEdited { name = chosen.isEmpty ? "" : OutfitEngine.suggestedName(for: chosen.map(\.snapshot)) }
                advice = isWearable ? OutfitEngine.shared.recommendation(
                    for: chosen.map(\.snapshot), closet: items.map(\.snapshot), weather: appState.weather) : nil
            }
        }
        .tint(.ooBrown)
    }

    /// One piece per type; a dress replaces top + bottom (and the other way round)
    private func toggle(_ item: WardrobeItem) {
        if selection[item.role] == item.id {
            selection[item.role] = nil
            return
        }
        selection[item.role] = item.id
        if item.role == .dress { selection[.top] = nil; selection[.bottom] = nil }
        if item.role == .top || item.role == .bottom { selection[.dress] = nil }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let finalName = trimmed.isEmpty ? OutfitEngine.suggestedName(for: chosen.map(\.snapshot)) : trimmed
        modelContext.insert(SavedOutfit(name: finalName, itemIDs: chosen.map(\.id)))
        try? modelContext.save()
        dismiss()
    }
}
