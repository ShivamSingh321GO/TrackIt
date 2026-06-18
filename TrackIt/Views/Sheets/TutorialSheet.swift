import SwiftUI

struct TutorialSlide: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct TutorialSheet: View {
    @Bindable var manager: SessionFlowManager
    @Environment(\.dismiss) var dismiss
    @State private var currentSlideIndex = 0
    
    let slides = [
        TutorialSlide(
            id: 0,
            title: "Welcome to TrackIt",
            description: "A premium, minimalist ambient timer that fits perfectly into your macOS workflow, helping you manage and visualize your focus blocks.",
            icon: "timer",
            color: .blue
        ),
        TutorialSlide(
            id: 1,
            title: "Natural Language Input",
            description: "Simply type durations like '20 mins', '1h 30m', '+10m', or '-5m' in the top bar and press Enter to instantly start or adjust your countdown.",
            icon: "keyboard",
            color: .purple
        ),
        TutorialSlide(
            id: 2,
            title: "Status Bar widget",
            description: "A compact live timer stays in your macOS menu bar. Click it to quick-start, pause, reset, or open Settings and Tutorials.",
            icon: "menubar.arrow.up.rectangle",
            color: .green
        ),
        TutorialSlide(
            id: 3,
            title: "Workspace & Projects",
            description: "Switch to the full Workspace view to organize focus sessions by projects, track categories, and log notes to review your productivity history.",
            icon: "square.grid.2x2.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Slide Content with transition
            ZStack {
                let slide = slides[currentSlideIndex]
                VStack(spacing: 20) {
                    Image(systemName: slide.icon)
                        .font(.system(size: 64))
                        .foregroundColor(slide.color)
                        .padding()
                        .background(slide.color.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: slide.color.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    Text(slide.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(slide.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .frame(height: 70)
                        .padding(.horizontal, 20)
                }
                .id(currentSlideIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentSlideIndex)
            
            // Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(currentSlideIndex == index ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeOut(duration: 0.2), value: currentSlideIndex)
                }
            }
            .padding(.bottom, 24)
            
            // Navigation Buttons
            HStack {
                if currentSlideIndex > 0 {
                    Button("Back") {
                        currentSlideIndex -= 1
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.body)
                } else {
                    Spacer()
                        .frame(width: 40)
                }
                
                Spacer()
                
                if currentSlideIndex < slides.count - 1 {
                    Button("Next") {
                        currentSlideIndex += 1
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                } else {
                    Button("Got It") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 400, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
