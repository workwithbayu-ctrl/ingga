import SwiftUI
import Combine

struct LuxurySplashScreen: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var progress: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var showTagline = false
    @State private var showButtons = false
    @State private var particleOffset: CGFloat = 0

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Deep luxury background
            Color(hex: "0A0E1A")!
                .ignoresSafeArea()

            // Animated background particles
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<20) { i in
                        Circle()
                            .fill(Color(hex: "64B4FF")!.opacity(0.1))
                            .frame(width: CGFloat.random(in: 2...6))
                            .position(
                                x: CGFloat.random(in: 0...geo.size.width),
                                y: CGFloat.random(in: 0...geo.size.height)
                            )
                            .offset(y: particleOffset * CGFloat(i % 3 + 1) * 0.3)
                            .opacity(isAnimating ? 0.6 : 0)
                    }
                }
            }

            // Main content
            VStack(spacing: 0) {
                Spacer()

                // Logo container with glass effect
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color(hex: "64B4FF")!.opacity(0.15))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 0.5 : 0)

                    // Middle ring
                    Circle()
                        .stroke(Color(hex: "64B4FF")!.opacity(0.3), lineWidth: 1)
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(rotation))

                    // Inner circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "1A1F3A")!,
                                    Color(hex: "0F1629")!
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "64B4FF")!.opacity(0.5),
                                            Color(hex: "8B5CF6")!.opacity(0.3)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )

                    // Shield icon
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "64B4FF")!,
                                    Color(hex: "8B5CF6")!
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
                .padding(.bottom, 40)

                // App name with luxury styling
                VStack(spacing: 12) {
                    Text("SafeMoney")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "FFFFFF")!,
                                    Color(hex: "64B4FF")!
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(opacity)

                    // Animated underline
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "64B4FF")!,
                                    Color(hex: "8B5CF6")!
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: isAnimating ? 200 : 0, height: 3)
                        .opacity(isAnimating ? 1 : 0)
                }
                .padding(.bottom, 20)

                // Tagline
                Text("Your Financial Fortress")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "8B9BB4")!)
                    .opacity(showTagline ? 1 : 0)
                    .offset(y: showTagline ? 0 : 20)

                Spacer()

                // Loading indicator
                VStack(spacing: 16) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1A1F3A")!)
                            .frame(width: 200, height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "64B4FF")!,
                                        Color(hex: "8B5CF6")!
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200 * progress, height: 8)
                    }
                    .opacity(showContent ? 1 : 0)

                    Text("Securing your assets...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "8B9BB4")!)
                        .opacity(showContent ? 1 : 0)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimation()
        }
        .onReceive(timer) { _ in
            if progress < 1.0 {
                withAnimation(.linear(duration: 0.05)) {
                    progress += 0.015
                }
            }
        }
    }

    private func startAnimation() {
        // Phase 1: Initial appearance
        withAnimation(.easeOut(duration: 0.8)) {
            scale = 1.0
            opacity = 1.0
        }

        // Phase 2: Ring rotation and glow
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 1.2)) {
                isAnimating = true
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }

        // Phase 3: Show tagline
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.6)) {
                showTagline = true
            }
        }

        // Phase 4: Show progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.4)) {
                showContent = true
            }
        }

        // Phase 5: Particle animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
            particleOffset = -30
        }
    }
}

#Preview {
    LuxurySplashScreen()
}
