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
            title: "Step 1",
            description: "Go to the Workspace to create a project and add groups to schedule your sessions, or simply add new groups and sessions to an existing project.",
            icon: "square.grid.2x2.fill",
            imageName: "GoToWorkspace",
            color: .orange
        ),
        TutorialSlide(
            id: 4,
            title: "Step 2",
            description: "Create a new project before creating a group or session.",
            icon: "plus.app.fill",
            imageName: "CreateProj",
            color: .teal
        ),
        TutorialSlide(
            id: 5,
            title: "Step 3",
            description: "Create a project using a good name that justifies your work.",
            icon: "text.cursor",
            imageName: "CreateProjForm",
            color: .indigo
        ),
        TutorialSlide(
            id: 6,
            title: "Step 4",
            description: "Now create a group inside the project to organize and group related sessions together.",
            icon: "folder.fill.badge.plus",
            imageName: "CreateGrpButton",
            color: .yellow
        ),
        TutorialSlide(
            id: 7,
            title: "Step 5",
            description: "Choose a clear name for your group and assign relevant tags. Tags make it easy to search related sessions and track analytics across different projects.",
            icon: "tag.fill",
            imageName: "CreateGrpForm",
            color: .red
        ),
        TutorialSlide(
            id: 8,
            title: "Step 6",
            description: "Schedule your sessions inside the group. Set a duration, pick tags, and define your goals to stay focused.",
            icon: "calendar.badge.clock",
            imageName: "plansession",
            color: .cyan
        ),
        TutorialSlide(
            id: 9,
            title: "Step 7",
            description: "Give your session a descriptive name, select its target group, and apply tags to help with search optimization later.",
            icon: "list.bullet.rectangle.fill",
            imageName: "PlanSessionForm",
            color: .mint
        ),
        TutorialSlide(
            id: 10,
            title: "Step 8",
            description: "Finally, click the start button to launch your timer whenever you are ready to begin your session.",
            icon: "play.circle.fill",
            imageName: "StartTimer",
            color: .green
        ),
        TutorialSlide(
            id: 11,
            title: "Workflow 2: Dive Right In",
            description: "You don't always need to plan ahead. You can immediately start a timer from the floating widget. Once your session finishes, you can save it as a standalone session, or effortlessly assign it to a new or existing project.",
            icon: "bolt.fill",
            color: .yellow
        ),
        TutorialSlide(
            id: 12,
            title: "Start & Focus",
            description: "Just start the timer, position it anywhere on your screen, and focus on your work until the session ends.",
            icon: "timer",
            imageName: "TimerActive",
            color: .blue
        ),
        TutorialSlide(
            id: 13,
            title: "Add Notes Quickly",
            description: "Need to write something down? You can add notes directly from the floating timer without opening the workspace, and they'll be saved automatically.",
            icon: "square.and.pencil",
            imageName: "addNotes",
            color: .indigo
        ),
        TutorialSlide(
            id: 14,
            title: "Wrap Up & Save",
            description: "When you are done, review your session. You can append any final thoughts to your notes and save it securely.",
            icon: "checkmark.seal",
            imageName: "saveSessionunplanned",
            color: .green
        ),
        TutorialSlide(
            id: 15,
            title: "Review & Edit",
            description: "After saving the session, you'll be redirected to the workspace where you can see your completed session and edit any details if needed.",
            icon: "eye",
            imageName: "seeSession",
            color: .purple
        ),
        TutorialSlide(
            id: 16,
            title: "View Your Notes",
            description: "Simply tap on any completed session in the list to instantly view the notes you jotted down while working.",
            icon: "text.alignleft",
            imageName: "seeSession",
            color: .teal
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
                    // Placeholder for spacing when Back is hidden
                    Color.clear.frame(width: 32, height: 20)
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
        .frame(width: 700, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
