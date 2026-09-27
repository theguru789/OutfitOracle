//
//  Theme.swift
//  OutfitOracle
//
//  Shared colors + small building blocks so every screen keeps the same
//  brown / cream / butter-yellow / pink / blue look.
//

import SwiftUI

extension Color {
    static let ooCream     = Color(red: 0.94, green: 0.92, blue: 0.87)
    static let ooBrown     = Color.brown
    static let ooButter    = Color(red: 0.95, green: 0.90, blue: 0.55)
    static let ooLightText = Color(red: 0.98, green: 0.95, blue: 0.90)
    static let ooPink      = Color.pink.opacity(0.4)
    static let ooBlue      = Color.blue.opacity(0.4)
    static let ooChatInput = Color(red: 0.97, green: 0.95, blue: 0.70)

    /// Builds a Color from "#RRGGBB" (used for trend palettes + item swatches)
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        self.init(
            red:   Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue:  Double(value & 0xFF) / 255
        )
    }
}

// MARK: - Brown header bar (Closet / Chat style)
struct OOHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.system(.title, design: .default).weight(.bold))
                .foregroundColor(.ooLightText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            trailing()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.ooBrown)
    }
}

extension OOHeader where Trailing == EmptyView {
    init(title: String) {
        self.title = title
        self.trailing = { EmptyView() }
    }
}

// MARK: - Filter chip (Closet style)
struct OOChip: View {
    let title: String
    let selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(selected ? Color.ooBrown : Color.ooButter)
                .foregroundColor(selected ? .ooLightText : .ooBrown)
                .cornerRadius(20)
        }
    }
}

// MARK: - Big brown button (Upload / Retake style)
struct OOButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.bold))
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.brown.opacity(configuration.isPressed ? 0.7 : 0.5))
            .foregroundColor(.white)
            .cornerRadius(25)
    }
}

// MARK: - Butter card background
extension View {
    func ooCard(_ color: Color = .ooButter, radius: CGFloat = 20) -> some View {
        self
            .padding(10)
            .background(color)
            .cornerRadius(radius)
    }
}

// MARK: - Swatch dot
struct ColorSwatch: View {
    let hex: String
    var size: CGFloat = 16

    var body: some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: size, height: size)
            .overlay(Circle().stroke(Color.ooBrown.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Item thumbnail
struct ItemThumbnail: View {
    let item: WardrobeItem
    var height: CGFloat = 120

    var body: some View {
        Group {
            if let image = item.croppedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.ooBlue.overlay(
                    Image(systemName: item.role.symbol)
                        .font(.system(size: 40))
                        .foregroundColor(.ooBrown)
                )
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .cornerRadius(15)
    }
}
