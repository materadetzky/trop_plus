//
//  LiquidGlass.swift
//  Trop
//
//  Created by Antigravity on 10/10/2026.
//

import SwiftUI

// Native Liquid Glass styling system providing realistic glass refraction,
// iridescent dispersion, specular rim highlights, and depth shadows matching iOS 26 design language.
struct LiquidGlassModifier<S: Shape>: ViewModifier {
    let shape: S
    var tintColor: Color = .white
    var intensity: Double = 1

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // 1. Base translucent frosted refraction
                    shape
                        .fill(.ultraThinMaterial)

                    // 2. Translucent glass surface tint
                    shape
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.20 * intensity),
                                    Color.white.opacity(0.08 * intensity),
                                    Color.white.opacity(0.03 * intensity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 3. Iridescent chromatic dispersion (prismatic glass caustics)
                    shape
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(red: 1.0, green: 0.65, blue: 0.85).opacity(0.14 * intensity), location: 0.0),
                                    .init(color: Color(red: 0.60, green: 0.82, blue: 1.0).opacity(0.16 * intensity), location: 0.35),
                                    .init(color: Color(red: 0.72, green: 1.0, blue: 0.85).opacity(0.12 * intensity), location: 0.65),
                                    .init(color: Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.09 * intensity), location: 0.88),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // 4. Specular gloss sheen (top-left direct light reflection)
                    shape
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.38 * intensity), location: 0),
                                    .init(color: .white.opacity(0.12 * intensity), location: 0.35),
                                    .init(color: .clear, location: 0.70)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            // 5. Beveled specular glass rim stroke (multi-stop refractive bevel)
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.85 * intensity), location: 0),
                                .init(color: .white.opacity(0.35 * intensity), location: 0.45),
                                .init(color: .white.opacity(0.12 * intensity), location: 0.72),
                                .init(color: .white.opacity(0.50 * intensity), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
            // 6. Ambient depth shadow & subtle specular glow
            .shadow(color: Color.black.opacity(0.20), radius: 14, x: 0, y: 7)
            .shadow(color: Color.white.opacity(0.15 * intensity), radius: 5, x: 0, y: 1)
    }
}

extension View {
    // Applies native Liquid Glass styling with custom shape and sheen.
    func liquidGlass<S: Shape>(_ shape: S, tint: Color = .white, intensity: Double = 1) -> some View {
        modifier(LiquidGlassModifier(shape: shape, tintColor: tint, intensity: intensity))
    }

    // Applies native Liquid Glass capsule styling.
    func liquidGlassCapsule(tint: Color = .white, intensity: Double = 1) -> some View {
        liquidGlass(Capsule(), tint: tint, intensity: intensity)
    }

    // Applies native Liquid Glass circle styling.
    func liquidGlassCircle(tint: Color = .white, intensity: Double = 1) -> some View {
        liquidGlass(Circle(), tint: tint, intensity: intensity)
    }

    // Applies native Liquid Glass rounded rectangle styling.
    func liquidGlassCard(cornerRadius: CGFloat = 20, tint: Color = .white, intensity: Double = 1) -> some View {
        liquidGlass(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint, intensity: intensity)
    }
}
