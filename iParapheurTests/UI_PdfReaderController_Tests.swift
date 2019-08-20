/*
 * Copyright 2012-2019, Libriciel SCOP.
 *
 * contact@libriciel.coop
 *
 * This software is a computer program whose purpose is to manage and sign
 * digital documxents on an authorized iParapheur.
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

import XCTest
import os
import PDFKit
@testable import iParapheur


class UI_PdfReaderController_Tests: XCTestCase {


    func testTranslateToXXXAnnotation() {

        let annotation = Annotation(currentPage: 5)!
        annotation.text = "Text"
        annotation.identifier = "Id"
        annotation.author = "Author"
        annotation.fillColor = "red"
        annotation.date = Date(timeIntervalSince1970: 1546344000)

        let pdfAnnotation = PdfReaderController.translateToPdfAnnotation(annotation, pageHeight: 1080, pdfPage: PDFPage(image: UIImage())!)
        let parsedAnnotation = PdfReaderController.translateToAnnotation(pdfAnnotation, pageNumber: annotation.page, pageHeight: 1080)

        XCTAssertEqual(parsedAnnotation.text, "Text")
        XCTAssertEqual(parsedAnnotation.text, "Text")
        XCTAssertEqual(parsedAnnotation.author, "Author")
        XCTAssertEqual(parsedAnnotation.identifier, "Id")
        XCTAssertEqual(parsedAnnotation.page, 5)
        XCTAssertEqual(parsedAnnotation.date.timeIntervalSince1970, 1546344000)
    }

}
