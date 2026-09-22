import SwiftUI
import PencilKit

/// A UIViewRepresentable wrapping PKCanvasView with the standard Apple tool
/// picker. Handles: loading/saving drawing data, live sync between windows that
/// have the same page open, read-only mode (which also lets the Apple Pencil pan
/// the document), and Apple Pencil Pro features.
struct PencilCanvas: UIViewRepresentable {
    let pageID: UUID
    let itemID: UUID
    let template: PaperTemplate
    @Binding var isReadOnly: Bool
    /// When true the standard tool picker is shown and becomes first responder.
    var showsToolPicker: Bool

    @ObservedObject var store: NoteStore = .shared

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        canvas.alwaysBounceVertical = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        // The surrounding SwiftUI ScrollView handles scrolling; the canvas only
        // scrolls itself in read-only mode (so the Apple Pencil can pan).
        canvas.isScrollEnabled = false

        // Load existing drawing
        if let data = store.loadDrawingData(for: pageID),
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        context.coordinator.canvas = canvas
        context.coordinator.lastRevision = store.drawingRevisions[pageID] ?? 0

        // Apple Pencil Pro: allow the barrel-tap / squeeze to be handled by the
        // tool picker (system provides the tool palette interactions).
        if #available(iOS 17.5, *) {
            let interaction = UIPencilInteraction()
            interaction.delegate = context.coordinator
            canvas.addInteraction(interaction)
        }

        DispatchQueue.main.async {
            context.coordinator.setupToolPicker()
            context.coordinator.applyMode()
        }
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applyMode()

        // Live reload if another window changed this page's drawing.
        let currentRevision = store.drawingRevisions[pageID] ?? 0
        if currentRevision != context.coordinator.lastRevision && !context.coordinator.isSaving {
            context.coordinator.lastRevision = currentRevision
            if let data = store.loadDrawingData(for: pageID),
               let drawing = try? PKDrawing(data: data),
               drawing.dataRepresentation() != canvas.drawing.dataRepresentation() {
                canvas.drawing = drawing
            }
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate, UIPencilInteractionDelegate {
        var parent: PencilCanvas
        weak var canvas: PKCanvasView?
        var toolPicker: PKToolPicker?
        var lastRevision: Int = 0
        var isSaving = false
        private var saveWork: DispatchWorkItem?

        init(_ parent: PencilCanvas) { self.parent = parent }

        func setupToolPicker() {
            guard let canvas else { return }
            let picker: PKToolPicker
            if let existing = toolPicker {
                picker = existing
            } else {
                picker = PKToolPicker()
                toolPicker = picker
            }
            picker.setVisible(parent.showsToolPicker && !parent.isReadOnly, forFirstResponder: canvas)
            picker.addObserver(canvas)
            if parent.showsToolPicker && !parent.isReadOnly {
                canvas.becomeFirstResponder()
            }
        }

        func applyMode() {
            guard let canvas else { return }
            let readOnly = parent.isReadOnly
            // In read-only mode: disable drawing, allow panning/scrolling (also
            // via Apple Pencil), and hide the tool picker.
            canvas.drawingGestureRecognizer.isEnabled = !readOnly
            if readOnly {
                canvas.drawingPolicy = .pencilOnly // irrelevant while disabled
                canvas.isScrollEnabled = true
                canvas.panGestureRecognizer.minimumNumberOfTouches = 1
                // Allow the pencil to drag the canvas around in read-only mode.
                canvas.panGestureRecognizer.allowedTouchTypes = [
                    NSNumber(value: UITouch.TouchType.direct.rawValue),
                    NSNumber(value: UITouch.TouchType.pencil.rawValue)
                ]
                toolPicker?.setVisible(false, forFirstResponder: canvas)
            } else {
                canvas.drawingPolicy = .anyInput
                canvas.panGestureRecognizer.allowedTouchTypes = [
                    NSNumber(value: UITouch.TouchType.direct.rawValue)
                ]
                toolPicker?.setVisible(parent.showsToolPicker, forFirstResponder: canvas)
                if parent.showsToolPicker { canvas.becomeFirstResponder() }
            }
        }

        // MARK: PKCanvasViewDelegate

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !parent.isReadOnly else { return }
            scheduleSave()
        }

        private func scheduleSave() {
            saveWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self, let canvas = self.canvas else { return }
                self.isSaving = true
                let data = canvas.drawing.dataRepresentation()
                self.parent.store.saveDrawingData(data, for: self.parent.pageID, in: self.parent.itemID)
                self.lastRevision = self.parent.store.drawingRevisions[self.parent.pageID] ?? 0
                self.isSaving = false
            }
            saveWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
        }

        // MARK: UIPencilInteractionDelegate (Apple Pencil Pro / 2 tap)

        // Classic, widely-supported double-tap handler: toggle pen / eraser.
        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            guard let canvas, let picker = toolPicker, !parent.isReadOnly else { return }
            if picker.selectedTool is PKEraserTool {
                picker.selectedTool = PKInkingTool(.pen, color: .label, width: 4)
            } else {
                picker.selectedTool = PKEraserTool(.vector)
            }
            canvas.tool = picker.selectedTool
        }

        // Apple Pencil Pro squeeze: toggle the tool picker visibility.
        @available(iOS 17.5, *)
        func pencilInteraction(_ interaction: UIPencilInteraction,
                               didReceiveSqueeze squeeze: UIPencilInteraction.Squeeze) {
            guard let canvas, let picker = toolPicker, !parent.isReadOnly else { return }
            guard squeeze.phase == .ended else { return }
            let visible = picker.isVisible
            picker.setVisible(!visible, forFirstResponder: canvas)
            if !visible { canvas.becomeFirstResponder() }
        }
    }
}
