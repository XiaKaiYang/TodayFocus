import XCTest

final class TextContrastAuditTests: XCTestCase {
    func testUISourcesAvoidWhiteTextAndSystemSegmentedPickers() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let appRoot = root.appendingPathComponent("Apps/FocusSessionApp")

        let forbiddenPatterns = [
            #"foreground(?:Style|Color)\([^\n]*?(?:Color\.)?white"#,
            #"pickerStyle\(\.segmented\)"#
        ]
        let regexes = try forbiddenPatterns.map {
            try NSRegularExpression(pattern: $0, options: [])
        }

        let enumerator = FileManager.default.enumerator(
            at: appRoot,
            includingPropertiesForKeys: nil
        )

        var violations: [String] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }

            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)

            for (index, line) in lines.enumerated() {
                for regex in regexes {
                    let range = NSRange(line.startIndex..<line.endIndex, in: line)
                    if regex.firstMatch(in: line, options: [], range: range) != nil {
                        violations.append("\(fileURL.lastPathComponent):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
                    }
                }
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            "Found white text or system segmented pickers:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testTasksAndBlockerFormsAvoidDefaultPromptAndToggleStyling() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let guardedFiles = [
            root.appendingPathComponent("Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift"),
            root.appendingPathComponent("Apps/FocusSessionApp/UI/Blocker/BlockerSettingsView.swift")
        ]

        var violations: [String] = []
        for fileURL in guardedFiles {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let lines = contents.components(separatedBy: .newlines)

            for (index, line) in lines.enumerated() {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("TextField(") || trimmed.hasPrefix(#"Toggle(""#) {
                    violations.append("\(fileURL.lastPathComponent):\(index + 1): \(trimmed)")
                }
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            "Found default TextField prompt or Toggle label styling in guarded forms:\n\(violations.joined(separator: "\n"))"
        )
    }

    func testCurrentSessionTaskSelectorAvoidsDisabledEmptyStateStyling() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertFalse(
            contents.contains(".disabled(!viewModel.canConfigureSession || viewModel.availableTaskSelections.isEmpty)"),
            "Task selector should not use disabled styling for the empty-task state because it washes the label into low-contrast text."
        )
        XCTAssertTrue(
            contents.contains("viewModel.canConfigureSession && !viewModel.availableTaskSelections.isEmpty"),
            "Task selector should branch between interactive and non-interactive empty states without relying on disabled tinting."
        )
        XCTAssertTrue(
            contents.contains("AppSurfaceTheme.taskSelectorWarmGlyph"),
            "Task selector should use the custom warm glyph color instead of the generic neutral text colors."
        )
        XCTAssertTrue(
            contents.contains("AppSurfaceTheme.taskSelectorWarmBorder"),
            "Task selector should use the custom warm border color so the field matches the dial palette."
        )
    }

    func testSettingsAndCurrentSessionSelectorsAvoidSystemMenuControls() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let guardedFiles = [
            root.appendingPathComponent("Apps/FocusSessionApp/UI/Settings/SettingsDashboardView.swift"),
            root.appendingPathComponent("Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift")
        ]

        var violations: [String] = []
        for fileURL in guardedFiles {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)

            if contents.contains("Picker(") || contents.contains("Menu {") {
                violations.append(fileURL.lastPathComponent)
            }
        }

        XCTAssertTrue(
            violations.isEmpty,
            "Selectors should use custom dropdown components instead of system Picker/Menu controls in: \(violations.joined(separator: ", "))"
        )
    }

    func testCurrentSessionNotesUseCustomPromptedTextEditor() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/CurrentSession/CurrentSessionView.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("AppPromptedTextEditor("),
            "Current Session note surfaces should use the shared custom prompted text editor so placeholder and caret insets stay aligned."
        )
        XCTAssertFalse(
            contents.contains("TextEditor(text: $viewModel.sessionNotes)"),
            "Current Session note surfaces should avoid raw TextEditor because macOS default insets drift away from the placeholder."
        )
    }

    func testCustomPromptedTextEditorDoesNotForcefullyResignFirstResponderDuringUpdates() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppSurfaceTheme.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertFalse(
            contents.contains("makeFirstResponder(nil)"),
            "The custom prompted text editor should not forcefully resign first responder inside updateNSView because TimelineView refreshes will kick the caret out of the note box."
        )
    }

    func testCustomPromptedTextEditorSetsDarkTypingAttributes() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/AppSurfaceTheme.swift")
        let contents = try String(contentsOf: fileURL, encoding: .utf8)

        XCTAssertTrue(
            contents.contains("fixedTypingAttributes"),
            "The custom prompted text editor should explicitly set typingAttributes so newly typed text does not fall back to the system default white ink."
        )
        XCTAssertTrue(
            contents.contains(".foregroundColor"),
            "The custom prompted text editor should include a foreground color in typingAttributes."
        )
        XCTAssertFalse(
            contents.contains("NSColor.labelColor"),
            "The custom prompted text editor should avoid semantic AppKit label colors here because they can resolve to white inside the current appearance stack."
        )
    }

    func testTasksPageUsesPrioritySectionsAndPriorityComposer() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let viewFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift")
        let modelFileURL = root.appendingPathComponent("Apps/FocusSessionApp/Tasks/FocusTask.swift")
        let viewContents = try String(contentsOf: viewFileURL, encoding: .utf8)
        let modelContents = try String(contentsOf: modelFileURL, encoding: .utf8)

        XCTAssertTrue(modelContents.contains("高优先级"))
        XCTAssertTrue(modelContents.contains("中优先级"))
        XCTAssertTrue(modelContents.contains("低优先级"))
        XCTAssertTrue(modelContents.contains("无优先级"))
        XCTAssertTrue(viewContents.contains("TaskPriority.allCases"))
        XCTAssertTrue(viewContents.contains("AppSegmentedControl("))
        XCTAssertFalse(viewContents.contains("Next Up"))
        XCTAssertFalse(viewContents.contains(#"Text("Completed")"#))
    }

    func testTaskCompletionCheckboxUsesExplicitContentShape() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let viewFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift")
        let viewContents = try String(contentsOf: viewFileURL, encoding: .utf8)

        XCTAssertTrue(
            viewContents.contains(".contentShape(Rectangle())"),
            "The task completion checkbox should define an explicit hit area so clicking the hollow center still completes the task."
        )
    }

    func testTodayTasksRemoveTimeRangeUI() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let viewFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift")
        let viewContents = try String(contentsOf: viewFileURL, encoding: .utf8)

        XCTAssertFalse(
            viewContents.contains(#"Text("Time range")"#),
            "Today tasks should no longer show time range controls in the shared composer."
        )
        XCTAssertFalse(
            viewContents.contains(#"Text("Start time")"#),
            "Today tasks should no longer show schedule start fields."
        )
        XCTAssertFalse(
            viewContents.contains(#"Text("End time")"#),
            "Today tasks should no longer show schedule end fields."
        )
        XCTAssertFalse(
            viewContents.contains("Text(Self.scheduleText(startAt: startAt, endAt: endAt))"),
            "Today task rows should no longer render schedule summaries."
        )
        XCTAssertTrue(
            viewContents.contains(#"Text("Repeat")"#),
            "The shared Today task composer should expose repeat controls."
        )
        XCTAssertTrue(
            viewContents.contains("TaskRepeatRule.allCases"),
            "Repeat cadence should use the shared segmented control options."
        )
        XCTAssertTrue(
            viewContents.contains(#"Text("Repeat day")"#),
            "Weekly repeats should allow picking a weekday."
        )
    }

    func testTodayTaskSubtaskParentsUseHierarchySymbolAndEditOnlySubtaskComposer() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let viewFileURL = root.appendingPathComponent("Apps/FocusSessionApp/UI/Tasks/TasksDashboardView.swift")
        let viewContents = try String(contentsOf: viewFileURL, encoding: .utf8)

        XCTAssertTrue(
            viewContents.contains(#""list.bullet.indent""#),
            "Parent tasks with subtasks should use the hierarchy symbol instead of a normal completion checkbox."
        )
        XCTAssertTrue(
            viewContents.contains("if viewModel.isEditingTask"),
            "The shared task composer should gate the subtask editor behind edit mode only."
        )
        XCTAssertTrue(
            viewContents.contains(#"Text("Subtasks")"#),
            "The edit composer should label the embedded checklist editor clearly."
        )
        XCTAssertTrue(
            viewContents.contains(#"Button("Add subtask")"#),
            "The edit composer should provide an explicit action to append checklist rows."
        )
    }
}
