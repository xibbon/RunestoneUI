 //
//  KeyboardTools.swift
//
//  The keyboard input accessor for a coding editor, wiring up for
//  GDSscript for now, can later be made extensible
//
//  Created by Miroslav Djukic on 4/11/24.
//

import Foundation
import SwiftUI
import UIKit
@_exported import Runestone

public final class KeyboardToolsView: UIInputView {

    private weak var textView: TextView?
    private let keyboardToolsObservable: KeyboardToolsObservable
    public init(textView: TextView) {
        self.textView = textView
        let operationButtons = [
            KeyboardAccessoryButton(title: "lessthan", icon: "lessthan", action: { [weak textView] in
                textView?.insertText("<")
            }),
            KeyboardAccessoryButton(title: "number", icon: "number", action: { [weak textView] in
                textView?.insertText("#")
            }),
            KeyboardAccessoryButton(title: "percent", icon: "percent", action: { [weak textView] in
                textView?.insertText("%")
            }),
            KeyboardAccessoryButton(title: "and", icon: "", action: { [weak textView] in
                textView?.insertText("and")
            }),
            KeyboardAccessoryButton(title: "or", icon: "", action: { [weak textView] in
                textView?.insertText("or")
            }),
            KeyboardAccessoryButton(title: "greaterthan", icon: "greaterthan", action: { [weak textView] in
                textView?.insertText(">")
            }),
            KeyboardAccessoryButton(title: "~", icon: "", action: { [weak textView] in
                textView?.insertText("~")
            }),
            KeyboardAccessoryButton(title: "minus", icon: "minus", action: { [weak textView] in
                textView?.insertText("-")
            }),
            KeyboardAccessoryButton(title: "plus", icon: "plus", action: { [weak textView] in
                textView?.insertText("+")
            }),
            KeyboardAccessoryButton(title: "*", icon: "", action: { [weak textView] in
                textView?.insertText("*")
            }),
            KeyboardAccessoryButton(title: "/", icon: "", action: { [weak textView] in
                textView?.insertText("/")
            }),
            KeyboardAccessoryButton(title: "^", icon: "", action: { [weak textView] in
                textView?.insertText("^")
            }),
        ]
        let buttons = [
            KeyboardAccessoryButton(
                title: "Tab Right",
                icon: "arrow.right.to.line",
                additionalOptions: [KeyboardAccessoryButton(title: "Tab Left", icon: "arrow.left.to.line", action: { [weak textView] in
                    textView?.shiftLeft()
                })],
                action: { [weak textView] in
                    textView?.indent()
                    
                })
            ,KeyboardAccessoryButton(
                title: "Undo",
                icon: "arrow.uturn.backward",
                action: { [weak textView] in
                    textView?.undoManager?.undo()
                }),
            KeyboardAccessoryButton(
                title: "Redo",
                icon: "arrow.uturn.forward",
                action: { [weak textView] in
                    textView?.undoManager?.redo()
                }),
//            KeyboardAccessoryButton(
//                title: "Reference",
//                icon: "eye",
//                action: {
//                    //TODO: missing implementation for reference
//                    
//                }),
            KeyboardAccessoryButton(
                title: "Operations",
                icon: "plus.forwardslash.minus",
                additionalOptions: operationButtons,
                action: {
                    return
                }),
            KeyboardAccessoryButton(
                title: "\u{201C}a\u{201D}",
                icon: "",
                action: { [weak textView] in
                    textView?.insertText("\"\"")
                    textView?.moveCursorLeft()
                }),
            KeyboardAccessoryButton(title: "leftright", icon: "", doubleButton: [
                KeyboardAccessoryButton(
                    title: "Move Left",
                    icon: "arrow.left",
                    action: { [weak textView] in
                        textView?.moveCursorLeft()
                        
                        
                    }),
                KeyboardAccessoryButton(title: "Move Right",
                                        icon: "arrow.right", action: { [weak textView] in
                    textView?.moveCursorRight()
                })
            ], action: {
                
            }),
            KeyboardAccessoryButton(
                title: "Copy",
                icon: "doc.on.doc",
                action: { [weak textView] in
                    if let range = textView?.selectedTextRange, let selectedText = textView?.text(in: range) {
                        UIPasteboard.general.string = selectedText
                    }
                }),
            KeyboardAccessoryButton(
                title: "Paste",
                icon: "document.on.clipboard",
                action: { [weak textView] in
                    if let str = UIPasteboard.general.string {
                        textView?.insertText(str)
                    }
                }),
            KeyboardAccessoryButton(
                title: "search",
                icon: "magnifyingglass",
                action: {
                    textView.findInteraction?.presentFindNavigator(showingReplace: false)
                }),
            KeyboardAccessoryButton(
                title: "_",
                icon: "",
                action: { [weak textView] in
                    textView?.insertText("_")
                }),
            KeyboardAccessoryButton(
                title: "()",
                icon: "",
                additionalOptions: [
                    KeyboardAccessoryButton(
                        title: "{}", icon: "", action: { [weak textView] in
                            textView?.insertText("{}")
                            textView?.moveCursorLeft()

                        }),
                    KeyboardAccessoryButton(
                        title: "[]", icon: "", action: { [weak textView] in
                            textView?.insertText("[]")
                            textView?.moveCursorLeft()
                        })],
                action: { [weak textView] in
                    textView?.insertText("()")
                    textView?.moveCursorLeft()
                }),
            KeyboardAccessoryButton(
                title: "Dismiss",
                icon: "keyboard.chevron.compact.down",
                action: { [weak textView] in
                    textView?.resignFirstResponder()
                })
            
        ]
        self.keyboardToolsObservable = KeyboardToolsObservable(buttons: buttons)
        super.init(frame: CGRect.zero, inputViewStyle: .keyboard)
        self.backgroundColor = .systemBackground
        self.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 64 + self.safeAreaInsets.bottom)
        setupView()
        //
        // Do not track the checkpoint one for our purposes, since it would be triggered when the undo/redo state is changed,
        // but that triggers updateUIView in the SwiftUI view, which would override the changes done when performing
        // a batched text replace
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoRedoButtonStates), name: .NSUndoManagerCheckpoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoRedoButtonStates), name: .NSUndoManagerDidUndoChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUndoRedoButtonStates), name: .NSUndoManagerDidRedoChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cleanup()
    }
    
    /// This is needed because UIKit retains inputAccessoryView
    /// it is bug on UIKit side and only option is to cleanup resources and leave empty objects hanging
    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        self.keyboardToolsObservable.buttons = []
    }
    
    private func setupView() {
        let c = UIHostingController(rootView: KeyboardToolsUI(keyboardToolsObservable: keyboardToolsObservable))
        let view = c.view!
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        updateUndoRedoButtonStates()
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            view.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}

extension TextView {
    func moveCursorLeft () {
        if let selectedRange = self.selectedTextRange {
            if let newCursorPosition = self.position(from: selectedRange.start, offset: -1) {
                let newSelectedRange = self.textRange(from: newCursorPosition, to: newCursorPosition)
                self.selectedTextRange = newSelectedRange
            }
        }
    }
    
    func moveCursorRight() {
        if let selectedRange = self.selectedTextRange {
            if let newCursorPosition = self.position(from: selectedRange.end, offset: 1) {
                let newSelectedRange = self.textRange(from: newCursorPosition, to: newCursorPosition)
                self.selectedTextRange = newSelectedRange
            }
        }
        
    }
    
    func indent() {
        guard let cursorPosition = self.selectedTextRange?.start else { return }
        let beginning = self.beginningOfDocument

        // Calculate the current cursor offset
        let offset = self.offset(from: beginning, to: cursorPosition)

        // Check if the cursor is at the start of a line or the first character
        let isStartOfLine = isCursorAtStartOfLine(cursorPosition: cursorPosition)
        if !isStartOfLine && offset != 0 {
            handleNonStartOfLine(cursorPosition: cursorPosition)
        }
        
        if isStartOfLine {
            shiftRight()
        }
    }
    
    private func rangeOfLine(containing position: UITextPosition) -> UITextRange? {
        let text = self.text
        
        // Get the current offset from the beginning of the document
        let offset = self.offset(from: self.beginningOfDocument, to: position)
        
        // Find the start of the line
        var lineStartOffset = offset
        while lineStartOffset > 0 {
            
            let index = text.index(text.startIndex, offsetBy: lineStartOffset - 1)
            if text[index].isNewline {
                break
            }

            lineStartOffset -= 1
        }
    
        // Adjust to ignore leading whitespaces
        while lineStartOffset < text.count {
            
            let index = text.index(text.startIndex, offsetBy: lineStartOffset)
            // asciiValue == 10 was treated as white space wich made wrong canculation
            // about rangeOfLine so additional check was added
            if !(text[index].isWhitespace) || text[index].asciiValue == 10 {
                break
            }

            lineStartOffset += 1
        }

        // Find the end of the line
        var lineEndOffset = offset
        while lineEndOffset < text.count {
            let index = text.index(text.startIndex, offsetBy: lineEndOffset)
            if text[index].isNewline {
                break
            }
    
            lineEndOffset += 1
        }

        // Convert offsets to text positions
        let startPosition = self.position(from: self.beginningOfDocument, offset: lineStartOffset)
        let endPosition = self.position(from: self.beginningOfDocument, offset: lineEndOffset)

        if let startPosition = startPosition, let endPosition = endPosition {
            return self.textRange(from: startPosition, to: endPosition)
        }

        return nil
    }

    private func isCursorAtStartOfLine(cursorPosition: UITextPosition) -> Bool {
        guard let lineRange = self.rangeOfLine(containing: cursorPosition) else { return false }
        let startOfLinePosition = lineRange.start
        let beginning = self.beginningOfDocument

        // Calculate the current cursor offset
        let offset = self.offset(from: beginning, to: startOfLinePosition)
        return self.compare(cursorPosition, to: startOfLinePosition) == .orderedSame
   }
    
    
    private func handleNonStartOfLine(cursorPosition: UITextPosition) {
        // Get the range of the current word
        let tokenizer = self.tokenizer
        let range = tokenizer.rangeEnclosingPosition(cursorPosition, with: .word, inDirection: UITextDirection.storage(.forward))
        
        if let range = range {
            let wordEndPosition = range.end
            let wordStartPosition = range.start
            if let selectedRange = self.selectedTextRange,
               self.compare(selectedRange.start, to: wordStartPosition) == .orderedSame,
               self.compare(selectedRange.end, to: wordEndPosition) == .orderedSame  {
                // If the word is selected, move the cursor to the end of the word
                self.selectedTextRange = self.textRange(from: wordEndPosition, to: wordEndPosition)
            } else if self.compare(cursorPosition, to: wordEndPosition) == .orderedSame || self.compare(cursorPosition, to: wordStartPosition) == .orderedDescending {
                // If the cursor is at the end of the word, select the next word
                moveToNextWord(from: wordEndPosition)
            } else {
                
                if let r = self.textRange(from: cursorPosition, to: wordEndPosition), isValidWordRange(r) {
                    // If no word is selected, move the cursor to the end of the word
                    self.selectedTextRange = r
                } else {
                    moveToNextWord(from: wordEndPosition)
                }
            }
        }
    }
   
    private func moveToNextWord(from position: UITextPosition) {
        let tokenizer = self.tokenizer
        var currentPosition = position
        while let nextWordRange = tokenizer.rangeEnclosingPosition(currentPosition, with: .word, inDirection: UITextDirection.storage(.forward)) {
            if isValidWordRange(nextWordRange) {
                // Select the next valid word
                self.selectedTextRange = nextWordRange
                return
            }
            // if we are at end and didn't find next word return
            if compare(currentPosition, to: nextWordRange.end) == .orderedSame {
                return
            }
            currentPosition = nextWordRange.end
        }
    }

    private func isValidWordRange(_ range: UITextRange) -> Bool {
        guard let text = self.text(in: range) else { return false }
        let trimmedText = text
        var validWordCharacters = CharacterSet.alphanumerics
            validWordCharacters.insert(charactersIn: "_")
        return !trimmedText.isEmpty && trimmedText.rangeOfCharacter(from: validWordCharacters.inverted) == nil
    }
}

extension UITextDirection {
    static func storage(_ direction: UITextStorageDirection) -> UITextDirection {
        return UITextDirection(rawValue: direction.rawValue)
    }
}

private extension KeyboardToolsView {
    @objc private func updateUndoRedoButtonStates() {
        let undoManager = textView?.undoManager
        self.keyboardToolsObservable.setUndo(isEnabled: undoManager?.canUndo ?? false)
        self.keyboardToolsObservable.setRedo(isEnabled: undoManager?.canRedo ?? false)
    }
}

@Observable
class KeyboardToolsObservable {
    var buttons: [KeyboardAccessoryButton] = []
    
    init(buttons: [KeyboardAccessoryButton]) {
        self.buttons = buttons
    }
    
    func setUndo(isEnabled: Bool) {
        if let undoIndex = self.buttons.firstIndex(where: { $0.title.lowercased() == "undo"}) {
            var undoButton = self.buttons[undoIndex]
            undoButton.isEnabled = isEnabled
            self.buttons[undoIndex] = undoButton
        }
    }
    
    func setRedo(isEnabled: Bool) {
        if let redoIndex = self.buttons.firstIndex(where: { $0.title.lowercased() == "redo"}) {
            var redoButton = self.buttons[redoIndex]
            redoButton.isEnabled = isEnabled
            self.buttons[redoIndex] = redoButton
        }
    }
}

struct KeyboardToolsUI: View {
    @State private var globalWidth: CGFloat = 0
    @State private var buttonWidth: CGFloat = 150.0
    var keyboardToolsObservable: KeyboardToolsObservable
    var body: some View {
        HStack {
            ForEach(keyboardToolsObservable.buttons) { button in
                KeyboardToolsButton(buttonModel: button, buttonWidth: buttonWidth)
            }
        }
        .environment(\.globalWidth, globalWidth)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            GeometryReader { geometry in
                Color.clear
                .onAppear {
                    // Calculate width of whole app view, derive button width from that value and button count
                    globalWidth = geometry.size.width
                    let buttonCount = keyboardToolsObservable.buttons.count
                    let totalSpacing = CGFloat((buttonCount * 16) + 16)
                    buttonWidth = min(150.0, (globalWidth - totalSpacing) / CGFloat(keyboardToolsObservable.buttons.count))
                }
                .onChange(of: geometry.size, { old, new in
                    // Update on change width of whole app view, derive button width from that value and button count
                    globalWidth = new.width
                    let buttonCount = keyboardToolsObservable.buttons.count
                    let totalSpacing = CGFloat((buttonCount * 16) + 16)
                    buttonWidth = min(150.0, (globalWidth - totalSpacing) / CGFloat(keyboardToolsObservable.buttons.count))
                })
            }
        }
    }
}


struct KeyboardToolsButton: View {
    @Environment(\.globalWidth) var globalWidth
    @State var showextraOptions: Bool = false
    @State var dragLocation: CGPoint?
    @State var selected: KeyboardAccessoryButton? = nil
    @State var frame: CGRect? = nil
    
    let buttonModel: KeyboardAccessoryButton
    var isSelected: Bool = false
    let buttonWidth: CGFloat
    
    var additionalOptionsCount: Int {
        return buttonModel.additionalOptions.count
    }
    // just some value to set so that it doesn't try to fill whole width
    // changing this value will have effect on additional options grid layout
    let maxAdditionalOptionsCols = 4
    
    // calculates rows number for additional options grid
    var additionalOptionsRows: Int {
        return (additionalOptionsCount - 1) / maxAdditionalOptionsCols + 1
    }
    
    // calculates columns number for additional options grid
    var additionalOptionsCols: Int {
        return additionalOptionsCount > maxAdditionalOptionsCols ? maxAdditionalOptionsCols : additionalOptionsCount
    }
    
    // calculates whole grid height based on button height, row number and spacing
    var gridHeight: CGFloat {
        return CGFloat(additionalOptionsRows) * KeyboardToolsButton.buttonHeight + CGFloat(additionalOptionsRows + 1) *  AdditionalOptionsGrid.spacing
    }
    
    // calculates whole grid width based on button width, columns number and spacing
    var gridWidth: CGFloat {
        return CGFloat(additionalOptionsCols)  * buttonWidth + CGFloat(additionalOptionsCols + 1) *  AdditionalOptionsGrid.spacing
    }
    
    // calculates additional options grid offset based on source button position
    var xOffset: CGFloat {
        guard let frame else { return 0.0 }
        let additionalOptionsXMin = frame.minX - gridWidth / 2
        let additionalOptionsXMax = frame.maxX + gridWidth / 2
        
        if additionalOptionsXMin < 0 {
            return abs(frame.minX - gridWidth / 2) - buttonWidth / 2 + (16 - AdditionalOptionsGrid.spacing)
        } else if (additionalOptionsXMax > globalWidth) {
            return -(additionalOptionsXMax - globalWidth) + buttonWidth / 2 - (16 - AdditionalOptionsGrid.spacing)
        } else {
            return 0.0
        }
    }
    
    static var buttonHeight: CGFloat = 35.0
    
    var body: some View {
        GeometryReader { gr in
            Group {
                if buttonModel.doubleButton.count < 2 {
                    Button {
                        self.buttonModel.action()
                        showextraOptions = false
                    } label: {
                        Group {
                            if !buttonModel.icon.isEmpty {
                                Image(systemName: buttonModel.icon)
                            } else {
                                Text(buttonModel.title)
                            }
                        }
                        .frame(width: buttonWidth,
                               height: KeyboardToolsButton.buttonHeight)
                        .background(isSelected ? Color(uiColor: .systemGray2) : Color(uiColor: .systemGray5))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)

                    
                } else {
                    HStack {
                        let button1 = buttonModel.doubleButton[0]
                        let button2 = buttonModel.doubleButton[1]
                        
                        HStack(spacing: 2) {
                            Button {
                                button1.action()
                            } label: {
                                Group {
                                    if !button1.icon.isEmpty {
                                        Image(systemName: button1.icon)
                                    } else {
                                        Text(button1.title)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(isSelected ? Color(uiColor: .systemGray2) : Color(uiColor: .systemGray5))
                            }
                            .buttonStyle(.plain)
                        
                            Button {
                                button2.action()
                            } label: {
                                Group {
                                    if !button2.icon.isEmpty {
                                        Image(systemName: button2.icon)
                                    } else {
                                        Text(button2.title)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(isSelected ? Color(uiColor: .systemGray2) : Color(uiColor: .systemGray5))
                            }
                            .buttonStyle(.plain)
                            
                        }
                        .frame(width: buttonWidth,
                               height: KeyboardToolsButton.buttonHeight)
                        .cornerRadius(5)
                    }
                }
            }
            .overlay(alignment: .topTrailing, content: {
                if additionalOptionsCount > 0 {
                    Circle()
                        .foregroundColor(Color(uiColor: .systemGray))
                        .frame(width: 6, height: 6)
                        .padding(6)
                }
            })
            .onChange(of: gr.size, { oldValue, newValue in
                self.frame = gr.frame(in: .global)
            })
            .ifCond(additionalOptionsCount > 0, transform: { view in
                view
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged({ value in
                                self.dragLocation = value.location
                            })
                            .onEnded({ _ in
                                // this is selected additional button action
                                // gets triggerd when releasing finger upon drag selection
                                self.selected?.action()
                                showextraOptions = false
                                self.selected = nil
                            })
                        
                    )
                    .simultaneousGesture(LongPressGesture (minimumDuration: 0.6).onEnded ( { isEnded in
                        // shows extra options on button hold
                        showextraOptions = true
                    }))
                    .overlay(
                        AdditionalOptionsGrid(buttons: buttonModel.additionalOptions,
                                              location: dragLocation,
                                              buttonWidth: buttonWidth,
                                              gridSize: CGSize(width: gridWidth,
                                                               height: gridHeight),
                                              selected: $selected)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(5)
                            .frame(width: gridWidth,
                                   height: gridHeight)
                            .offset(x: xOffset, y: -(gridHeight))
                            .opacity(showextraOptions ? 1 : 0)
                        ,
                        alignment: .top)
                   
            })
            .coordinateSpace(name: "Custom")
            .opacity(buttonModel.isEnabled ? 1 : 0.4)
            .allowsHitTesting(buttonModel.isEnabled ? true : false)
        }
        .frame(width: buttonWidth)
    }
}

struct AdditionalOptionsGrid: View {
    let buttons: [KeyboardAccessoryButton]
    let location: CGPoint?
    static let spacing: CGFloat =  8
    let buttonWidth: CGFloat
    var gridSize: CGSize
    @Binding var selected: KeyboardAccessoryButton?
    var body: some View {
        Grid {
            ForEach(0..<rows) { row in
                GridRow {
                    ForEach(0..<cols(row: row)) { col in
                        let button = getButton(col: col, row: row)
                        GeometryReader { gr in
                            KeyboardToolsButton(buttonModel: button, isSelected: button.id == selected?.id, buttonWidth: buttonWidth)
                                .onChange(of: location) { oldValue, newValue in
                                    guard let location else { return }
                                    // checks weather drag gesture is over current button
                                    let targetFrame = gr.frame(in: .named("Custom"))
                                    if targetFrame.contains(location) {
                                        self.selected = button
                                    }
                                }
                        }
                        .frame(height: KeyboardToolsButton.buttonHeight)
                    }
                }
            }
        }
        .padding(AdditionalOptionsGrid.spacing)
    }
    
    func getButton(col: Int, row: Int) -> KeyboardAccessoryButton {
        return buttons[Int(buttons.count / rows) * row + col]
    }
    
    var rows: Int {
        let r = Int(gridSize.height / KeyboardToolsButton.buttonHeight)
        return r
    }
    
    func cols(row: Int) -> Int {
        let wholeRowColumnCount = Int(buttons.count / rows)
        if row == rows - 1 {
            // this is number of elements if row is incomplete
            let rest = buttons.count % rows
            if rest != 0 {
                return rest
            } else {
                return wholeRowColumnCount
            }
        } else {
            return wholeRowColumnCount
        }
    }
}

struct KeyboardAccessoryButton: Identifiable {
    var id: String {
        return title
    }
    let title: String
    let icon: String
    var additionalOptions: [KeyboardAccessoryButton] = []
    var isEnabled: Bool = true
    var doubleButton: [KeyboardAccessoryButton] = []
    let action: () ->()
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func ifCond<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
