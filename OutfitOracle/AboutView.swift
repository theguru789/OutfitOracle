//
//  AboutView.swift
//  OutfitOracle
//
//  Mission, privacy (what stays on the phone and what doesn't), and credits
//  for the datasets and services the app is built on.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var safariURL: URL?

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ooCream.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Image("OracleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Outfit Oracle logo")

                        card("Our mission", color: .ooButter) {
                            Text("Every unworn piece of clothing is wasted fabric, water and energy. Outfit Oracle helps you re-wear and remix what you already own. It keeps you on trend without buying more, and when you do need something, it points you to secondhand first.")
                        }

                        card("Your privacy", color: .ooBlue.opacity(0.35)) {
                            privacyLine("checkmark.shield", "No account, no sign-in, no ads, no tracking.")
                            privacyLine("iphone", "Your photos, closet and wear history are stored only on this iPhone.")
                            privacyLine("cpu", "Clothing detection, outfit scoring and chat run on-device with Core ML and Apple Intelligence.")
                            privacyLine("location", "Approximate location is sent to Open-Meteo only to get today's weather, and only if you allow it.")
                            privacyLine("arrow.down.circle", "The app downloads the latest trend list from the Outfit Oracle GitHub repository. Nothing about you is sent.")
                            privacyLine("safari", "Shop and donate links open the store's website only when you tap them.")
                        }

                        card("Built with", color: Color.ooPink.opacity(0.5)) {
                            creditLine("DeepFashion2", "garment detection training data", "https://github.com/switchablenorms/DeepFashion2")
                            creditLine("DeepFashion", "clothing attribute training data", "http://mmlab.ie.cuhk.edu.hk/projects/DeepFashion.html")
                            creditLine("Polyvore Outfits", "outfit compatibility training data", "https://github.com/mvasil/fashion-compatibility")
                            creditLine("Ultralytics YOLOv8", "detection model (AGPL-3.0)", "https://github.com/ultralytics/ultralytics")
                            creditLine("Open-Meteo", "weather data (CC BY 4.0)", "https://open-meteo.com")
                        }

                        card("The team", color: .ooButter) {
                            Text("Built by Guru Sanka for the Congressional App Challenge.")
                            Text("Outfit Oracle began as a MAGNT BLAST team project with Medha Bhat, Neha Koteru, Akshith Narravula and Tejesh Sanka, mentored by Ms. Maureen Stillman.")
                                .font(.subheadline)
                        }

                        Text("Version \(version)")
                            .font(.caption)
                            .foregroundColor(.ooBrown.opacity(0.7))
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
            .navigationTitle("About & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safariSheet(url: $safariURL)
        }
        .tint(.ooBrown)
    }

    private func card<Content: View>(_ title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content()
        }
        .font(.subheadline)
        .foregroundColor(.ooBrown)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color)
        .cornerRadius(20)
    }

    private func privacyLine(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: symbol)
        }
    }

    private func creditLine(_ name: String, _ detail: String, _ url: String) -> some View {
        Button {
            safariURL = URL(string: url)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).font(.subheadline.bold())
                    Text(detail).font(.caption)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the website")
    }
}
