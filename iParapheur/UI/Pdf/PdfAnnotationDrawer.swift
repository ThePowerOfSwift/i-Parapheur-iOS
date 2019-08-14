/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documents on an authorized iParapheur.
 *
 * This software is governed by the CeCILL license under French law and
 * abiding by the rules of distribution of free software.  You can  use,
 * modify and/ or redistribute the software under the terms of the CeCILL
 * license as circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and  rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty  and the software's author,  the holder of the
 * economic rights,  and the successive licensors  have only  limited
 * liability.
 *
 * In this respect, the user's attention is drawn to the risks associated
 * with loading,  using,  modifying and/or developing or reproducing the
 * software by the user in light of its specific status of free software,
 * that may mean  that it is complicated to manipulate,  and  that  also
 * therefore means  that it is reserved for developers  and  experienced
 * professionals having in-depth computer knowledge. Users are therefore
 * encouraged to load and test the software's suitability as regards their
 * requirements in conditions enabling the security of their systems and/or
 * data to be ensured and,  more generally, to use and operate it in the
 * same conditions as regards security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL license and that you accept its terms.
 */

import Foundation
import PDFKit
import os

/**
    Largely taken from this tutorial :
    https://medium.com/@artempoluektov/ios-pdfkit-ink-annotations-tutorial-4ba19b474dce
    The tutorial sets how read pencil drawing can be done with Bézier curves.
    I basically replace those with rectangles...
    ... But we might want to check those Bézier curves for a hand-written signature, some time.
 */
class PdfAnnotationDrawer: PdfAnnotationGestureRecognizerDelegate {

    // PDF 1.7 Standards
    static let FLAG_NORMAL = 0
    static let FLAG_LOCKED = 8


    weak var pdfView: PDFView!
    private var currentAnnotation: PDFAnnotation?
    private var rect: CGRect?
    private var currentPage: PDFPage?
    private var currentInsideHit: CGPoint?


    // <editor-fold desc="DrawingGestureRecognizerDelegate"> MARK: - DrawingGestureRecognizerDelegate


    func pressBegan(_ location: CGPoint) {

        guard let page = pdfView.page(for: location, nearest: true) else { return }
        currentPage = page
        let convertedPoint = pdfView.convert(location, to: currentPage!)

        // Actual logic

        if (currentAnnotation != nil) {
            rect = CGRect(origin: CGPoint(x: currentAnnotation!.bounds.origin.x,
                                          y: currentAnnotation!.bounds.origin.y + currentAnnotation!.bounds.height),
                          size: CGSize(width: currentAnnotation!.bounds.width,
                                       height: -currentAnnotation!.bounds.height))
        }
        else {
            rect = CGRect(origin: convertedPoint, size: CGSize(width: 0, height: 0))
        }
    }


    func longPressBegan() {
        currentAnnotation?.setValue(PDFAnnotationHighlightingMode.outline, forAnnotationKey: .highlightingMode)
        drawAnnotation(onPage: currentPage!)
    }


    func pressMoved(_ location: CGPoint, _ isLongPress: Bool) {

        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)

        // Actual logic

        if (isLongPress) {
            let newRect = computeMovedRectangle(location: convertedPoint, page: page)
            rect = newRect
        }
        else {
            let newSize = computeResizedRectangleSize(location: convertedPoint, page: page)
            rect?.size = newSize
        }

        drawAnnotation(onPage: page)
    }


    func pressEnded(_ location: CGPoint, _ isLongPress: Bool) {

        guard let page = currentPage else { return }
        let convertedPoint = pdfView.convert(location, to: page)

        // Actual logic

        if (isLongPress) {
            let newRect = computeMovedRectangle(location: convertedPoint, page: page)
            rect = newRect
        }
        else {
            let newSize = computeResizedRectangleSize(location: convertedPoint, page: page)
            rect?.size = newSize
        }

        currentAnnotation?.setValue(PDFAnnotationHighlightingMode.none, forAnnotationKey: .highlightingMode)

        drawAnnotation(onPage: page)
        currentAnnotation = nil
        currentInsideHit = nil
        rect = nil
    }


    func enterInEditMode(_ location: CGPoint) -> Bool {

        guard let page = pdfView.page(for: location, nearest: true) else { return false }
        let convertedPoint = pdfView.convert(location, to: page)

        guard let targetAnnotation = page.annotation(at: convertedPoint) else { return false }
        currentAnnotation = targetAnnotation

        // Actual logic

        currentAnnotation = targetAnnotation
        currentInsideHit = CGPoint(x: convertedPoint.x - targetAnnotation.bounds.origin.x,
                                   y: convertedPoint.y - targetAnnotation.bounds.origin.y)

        return true
    }


    func getCurrentAnnotation() -> PDFAnnotation? {
        return currentAnnotation
    }


    // </editor-fold desc="DrawingGestureRecognizerDelegate">


    class func createAnnotation(rect: CGRect, page: PDFPage, recycledAnnotation: PDFAnnotation?) -> PDFAnnotation {

        let border = PDFBorder()
        border.lineWidth = 2.0

        let annotation = PDFAnnotation(bounds: rect,
                                       forType: .square,
                                       withProperties: nil)

        // Passing metadata

        let highlightMode: PDFAnnotationHighlightingMode = recycledAnnotation?.value(forAnnotationKey: .highlightingMode) as? PDFAnnotationHighlightingMode ?? .none
        annotation.setValue(highlightMode, forAnnotationKey: .highlightingMode)

        let color: UIColor = recycledAnnotation?.value(forAnnotationKey: .color) as? UIColor ?? ColorUtils.DarkBlue
        annotation.setValue(color, forAnnotationKey: .color)

        let author: String = recycledAnnotation?.value(forAnnotationKey: .name) as? String ?? ""
        annotation.setValue(author, forAnnotationKey: .name)

        let flags: Int = recycledAnnotation?.value(forAnnotationKey: .flags) as? Int ?? PdfAnnotationDrawer.FLAG_NORMAL
        annotation.setValue(flags, forAnnotationKey: .flags)

        // Setting view's attributes

        annotation.color = color.withAlphaComponent(0.6)
        annotation.interiorColor = color.withAlphaComponent((highlightMode == .outline) ? 0.4 : 0.1)
        annotation.border = border

        return annotation
    }


    private func computeResizedRectangleSize(location: CGPoint, page: PDFPage) -> CGSize {

        let pageBounds = page.bounds(for: pdfView.displayBox)

        // Bounds into the PDF page size

        var xWithBoundaries = location.x
        xWithBoundaries = max(pageBounds.origin.x, xWithBoundaries)
        xWithBoundaries = min(pageBounds.origin.x + pageBounds.size.width, xWithBoundaries)

        var yWithBoundaries = location.y
        yWithBoundaries = max(pageBounds.origin.y, yWithBoundaries)
        yWithBoundaries = min(pageBounds.origin.y + pageBounds.size.height, yWithBoundaries)

        // Setting calculated values

        let width = xWithBoundaries - rect!.origin.x
        let height = yWithBoundaries - rect!.origin.y

        return CGSize(width: width, height: height)
    }


    private func computeMovedRectangle(location: CGPoint, page: PDFPage) -> CGRect {

        let insideHit = currentInsideHit!
        let currentRect = rect!
        let pageBounds = page.bounds(for: pdfView.displayBox)

        // Bounds into the PDF page size

        var xWithBoundaries = location.x - insideHit.x
        xWithBoundaries = max(pageBounds.origin.x, xWithBoundaries)
        xWithBoundaries = min(pageBounds.origin.x + pageBounds.size.width - currentRect.width, xWithBoundaries)

        var yWithBoundaries = location.y - insideHit.y
        yWithBoundaries = max(pageBounds.origin.y, yWithBoundaries)
        yWithBoundaries = min(pageBounds.origin.y + pageBounds.size.height - currentRect.height, yWithBoundaries)

        // Setting calculated values

        return CGRect(x: xWithBoundaries, y: yWithBoundaries, width: currentRect.width, height: currentRect.height)
    }

    /**
        Due to a nasty bug (https://stackoverflow.com/a/46911395/9122113),
        we have to remove and replace a new annotation to render it properly.
     */
    private func drawAnnotation(onPage: PDFPage) {

        guard let rect = rect else { return }
        let annotation = PdfAnnotationDrawer.createAnnotation(rect: rect.standardized,
                                                              page: onPage,
                                                              recycledAnnotation: currentAnnotation)

        if let _ = currentAnnotation {
            currentAnnotation!.page?.removeAnnotation(currentAnnotation!)
        }

        onPage.addAnnotation(annotation)
        currentAnnotation = annotation
    }

}