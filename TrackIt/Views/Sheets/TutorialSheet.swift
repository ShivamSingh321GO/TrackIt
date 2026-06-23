import SwiftUI

struct TutorialSlide: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
    var imageName: String? = nil
    let color: Color
}

struct TutorialSheet: View {
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
            title: "Two Ways to Work",
            description: "TrackIt adapts to your workflow. Plan ahead by creating Projects and scheduling Sessions in the Workspace, or simply start a quick timer and assign it to a project when you're done.",
            icon: "arrow.triangle.branch",
            color: .purple
        ),
        TutorialSlide(
            id: 2,
            title: "Workflow 1: Plan Ahead",
            description: "Open the Workspace view to create a new Project. Inside the project, you can organize your work into Groups and schedule Sessions in advance. When you're ready, simply click Start on any planned session.",
            icon: "calendar.badge.plus",
            color: .green
        ),
        TutorialSlide(
            id: 3,
            title: "Organize Your Work",
            description: "Go to the Workspace to create Projects and organize your tasks into Groups. Use tags to make searching easy.",
            icon: "folder.fill.badge.plus",
            imageName: "CreateGrpForm",
            color: .orange
        ),
        TutorialSlide(
            id: 4,
            title: "Schedule & Start",
            description: "Schedule sessions inside your groups. When you're ready to begin, simply click the start button.",
            icon: "calendar.badge.clock",
            imageName: "StartTimer",
            color: .teal
        ),
        TutorialSlide(
            id: 5,
            title: "Workflow 2: Dive Right In",
            description: "You don't always need to plan ahead. You can immediately start a timer from the floating widget. Once your session finishes, you can save it as a standalone session, or effortlessly assign it to a new or existing project.",
            icon: "bolt.fill",
            color: .yellow
        ),
        TutorialSlide(
            id: 6,
            title: "Start & Focus",
            description: "Just start the timer, position it anywhere on your screen, and focus on your work until the session ends.",
            icon: "timer",
            imageName: "TimerActive",
            color: .blue
        ),
        TutorialSlide(
            id: 7,
            title: "Add Notes Quickly",
            description: "Need to write something down? You can add notes directly from the floating timer without opening the workspace, and they'll be saved automatically.",
            icon: "square.and.pencil",
            imageName: "addNotes",
            color: .indigo
        ),
        TutorialSlide(
            id: 8,
            title: "Wrap Up & Save",
            description: "When you are done, review your session. You can append any final thoughts to your notes and save it securely.",
            icon: "checkmark.seal",
            imageName: "saveSessionunplanned",
            color: .green
        ),
        TutorialSlide(
            id: 9,
            title: "Review & Edit",
            description: "After saving, you'll see your completed sessions in the workspace. Tap on any session to view your notes or edit details.",
            icon: "eye",
            imageName: "SessonNotes",
            color: .purple
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Let's have some guidance about this app")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
            // Slide Content with transition
            ZStack {
                let slide = slides[currentSlideIndex]
                VStack(spacing: 20) {
                    if slide.id == 0 {
                        Image(nsImage: NSApplication.shared.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    } else if let imgName = slide.imageName {
                        Image(imgName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 20)
                    } else {
                        Image(systemName: slide.icon)
                            .font(.system(size: 64))
                            .foregroundColor(slide.color)
                            .padding()
                            .background(slide.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: slide.color.opacity(0.15), radius: 8, x: 0, y: 4)
                    }
                    
                    Text(slide.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(slide.description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                }
                .id(currentSlideIndex)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 30)
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
            HStack(spacing: 16) {
                if currentSlideIndex > 0 {
                    Button("Back") {
                        currentSlideIndex -= 1
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.body)
                } else {
                    Button("Skip") {
                        TutorialWindowManager.shared.closeTutorial()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.body)
                }
                
                if currentSlideIndex < slides.count - 1 {
                    Button("Next") {
                        currentSlideIndex += 1
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                } else {
                    Button("Got It") {
                        TutorialWindowManager.shared.closeTutorial()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .keyboardShortcut(.defaultAction)
                }
                
                Spacer() // Forces buttons to the left
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 1000, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
