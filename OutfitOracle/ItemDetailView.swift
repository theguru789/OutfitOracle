//
//  ItemDetailView.swift
//  OutfitOracle
//

import SwiftData
import SwiftUI

struct ItemDetailView: View {
    @Bindable var item: WardrobeItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TrendService.self) private var trends

    @State private var showArchiveOptions = false
    @State private var showDeleteConfirm = false
    @State private var safariURL: URL?
    @State private var justLogged = false

    private var fittingTrends: [TrendLook] {
        trends.looks.filter { look in
            look.slots.contains { TrendMatcher.similarity(item.snapshot, $0) >= TrendMatcher.threshold }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        ItemThumbnail(item: item, height: 260)

                        // Wear tracking
                        HStack(spacing: 12) {
                            statCard(value: "\(item.wearCount)", label: "times worn")
                            statCard(value: item.lastWorn.map { $0.formatted(.relative(presentation: .named)) } ?? "Never",
                                     label: "last worn")
                        }

                        Button {
                            logWear()
                        } label: {
                            Label(justLogged ? "Logged — nice re-wear!" : "Wore it today",
                                  systemImage: justLogged ? "checkmark.circle.fill" : "arrow.clockwise.circle")
                        }
                        .buttonStyle(OOButtonStyle())
                        .disabled(justLogged)

                        // Editable attributes
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("Name", text: $item.name)
                                .font(.headline)
                                .textFieldStyle(.roundedBorder)
                            AttributePicker(title: "Type", selection: Binding(
                                get: { item.role }, set: { item.role = $0 }
                            ), options: GarmentRole.allCases) { $0.singular.capitalizedFirst }
                            AttributePicker(title: "Color", selection: Binding(
                                get: { item.color },
                                set: { item.color = $0; item.colorHex = Vocabulary.hex(for: $0) }
                            ), options: Vocabulary.colors) { $0.capitalizedFirst }
                            AttributePicker(title: "Pattern", selection: $item.pattern, options: Vocabulary.patterns) { $0.capitalizedFirst }
                            AttributePicker(title: "Fabric", selection: $item.fabricType, options: Vocabulary.fabrics) { $0.capitalizedFirst }
                        }
                        .foregroundColor(.ooBrown)
                        .padding()
                        .background(Color.ooButter)
                        .cornerRadius(20)

                        // Trends this piece already works for
                        if !fittingTrends.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Already on trend for")
                                    .font(.headline)
                                ForEach(fittingTrends) { look in
                                    HStack {
                                        ForEach(look.palette.prefix(3), id: \.self) { ColorSwatch(hex: $0, size: 12) }
                                        Text(look.name)
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.ooBlue)
                            .cornerRadius(20)
                        }

                        // Done with it? Pass it on instead of trashing it.
                        Button {
                            showArchiveOptions = true
                        } label: {
                            Label("Not wearing this anymore?", systemImage: "arrow.3.trianglepath")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ooPink)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }

                        Button("Delete from closet", role: .destructive) {
                            showDeleteConfirm = true
                        }
                        .font(.footnote)
                    }
                    .padding()
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Give it a second life", isPresented: $showArchiveOptions, titleVisibility: .visible) {
                ForEach(ShopService.donateLinks) { link in
                    Button(link.store) {
                        archive()
                        safariURL = link.url
                    }
                }
                Button("Just archive it") { archive(); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Selling or donating keeps clothes out of landfills. It moves to Archives, and you can restore it anytime.")
            }
            .confirmationDialog("Delete \(item.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(item)
                    try? modelContext.save()
                    dismiss()
                }
            }
            .safariSheet(url: $safariURL)
        }
        .tint(.brown)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold())
            Text(label).font(.caption)
        }
        .foregroundColor(.ooBrown)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.ooButter)
        .cornerRadius(20)
    }

    private func logWear() {
        item.markWorn()
        modelContext.insert(WearLog(itemIDs: [item.id]))
        try? modelContext.save()
        justLogged = true
    }

    private func archive() {
        item.isArchived = true
        try? modelContext.save()
    }
}
