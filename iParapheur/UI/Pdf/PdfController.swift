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


class PdfController: UIViewController, PdfAnnotationEventsDelegate {


    @IBOutlet var pdfView: PDFView!
    private let pdfDrawer = PdfAnnotationDrawer()
    private let pdfAnnotationGestureRecognizer = PdfAnnotationGestureRecognizer()


    // <editor-fold desc="LifeCycle"> MARK: - LifeCycle


    override func viewDidLoad() {
        super.viewDidLoad()

        pdfView.displayMode = .singlePage
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 3
        pdfView.usePageViewController(true)

        pdfAnnotationGestureRecognizer.drawingDelegate = pdfDrawer
        pdfAnnotationGestureRecognizer.eventsDelegate = self
        pdfView.addGestureRecognizer(pdfAnnotationGestureRecognizer)
        pdfDrawer.pdfView = pdfView
    }

    /**
        Proper scale on rotation.
        Bug defined here : https://stackoverflow.com/a/51106199/9122113
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        pdfView.autoScales = true
    }


    // </editor-fold desc="LifeCycle">


    // <editor-fold desc="PdfAnnotationEventsDelegate"> MARK: - PdfAnnotationEventsDelegate


    func onAnnotationMoved(_ annotation: PDFAnnotation?) {
        preconditionFailure("This method must be overridden")
    }


    func onAnnotationSelected(_ annotation: PDFAnnotation?) {
        preconditionFailure("This method must be overridden")
    }


    // </editor-fold desc="PdfAnnotationEventsDelegate">


    func loadPdf(pdfUrl: URL) {
        if let pdfDocument = PDFDocument(url: pdfUrl) {
            pdfView.document = pdfDocument
        }
    }


    func isInCreateAnnotationMode() -> Bool {
        return pdfAnnotationGestureRecognizer.isInCreateAnnotationMode
    }


    func setCreateAnnotationMode(value: Bool) {
        pdfAnnotationGestureRecognizer.isInCreateAnnotationMode = value
    }

}
