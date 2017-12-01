/*
 * Copyright 2012-2017, Libriciel SCOP.
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
import Gloss

@objc class Annotation: NSObject, Glossy {

    var author: String?
    var id: String?
    @objc var text: String?
    let date: NSDate?
    let secretaire: Int?
    var rect: NSValue?

    let fillColor: String?
    let penColor: String?
    let type: String?

    var step: Int?
    var page: Int?
    var documentId: String?
    var editable: Bool?

    // MARK: - Glossy

    required init?(json: JSON) {

        author = ("author" <~~ json) ?? "(vide)"
        id = ("id" <~~ json) ?? ""
        text = ("text" <~~ json) ?? ""

        fillColor = ("fillColor" <~~ json) ?? "undefined"
        penColor = ("penColor" <~~ json) ?? "undefined"
        type = ("type" <~~ json) ?? "rect"

        date = NSDate(timeIntervalSince1970: (("date" <~~ json) ?? -1))
        secretaire = ("secretaire" <~~ json) ?? 0

        if let jsonRect: Dictionary<String, AnyObject>? = "rect" <~~ json {

            let jsonRectTopLeft: Dictionary<String, AnyObject>? = jsonRect!["topLeft"] as! Dictionary<String, AnyObject>?
            let jsonRectBottomRight: Dictionary<String, AnyObject>? = jsonRect!["bottomRight"] as! Dictionary<String, AnyObject>?


            let tempRect = CGRect(origin: CGPoint(x: jsonRectTopLeft!["x"] as! CGFloat,
                                                  y: jsonRectTopLeft!["y"] as! CGFloat),
                                  size: CGSize(width: (jsonRectBottomRight!["x"] as! CGFloat) - (jsonRectTopLeft!["x"] as! CGFloat),
                                               height: (jsonRectBottomRight!["y"] as! CGFloat) - (jsonRectTopLeft!["y"] as! CGFloat)))
			
			rect = NSValue(cgRect: DeviceUtils.translateDpiRect(tempRect,
				                                                oldDpi: 150,
				                                                newDpi: 72))
        }
		
        step = 0
    }

    @objc init?(currentPage: NSNumber) {

        author = ""
        id = "_new"
        text = ""

        fillColor = "undefined"
        penColor = "undefined"
        type = "rect"

        date = NSDate()
        secretaire = 0
		rect = NSValue(cgRect: DeviceUtils.translateDpiRect(CGRect(origin: .zero,
		                                                           size: CGSize(width: 150, height: 150)),
                                                            oldDpi:150,
                                                            newDpi:72))
        step = 0
        editable = false
        documentId = ""
        page = currentPage.intValue
    }

    func toJSON() -> JSON? {
        return nil /* Not used */
    }

    // MARK: - ObjC accessors

    @objc func unwrappedId() -> NSString {
        return NSString(string: id!)
    }

    @objc func unwrappedPage() -> NSNumber {
        return page as NSNumber!
    }

    @objc func setUnwrappedPage(i: NSNumber) {
		page = Int(truncating: i)
    }

    @objc func unwrappedRect() -> NSValue {
        return rect!
    }

    @objc func setUnwrappedRect(rct: NSValue) {
        rect = rct
    }

    @objc func unwrappedText() -> NSString {
        return NSString(string: text!)
    }

    @objc func setUnwrappedText(txt: NSString) {
        text = String(txt)
    }

    @objc func setUnwrappedAuthor(txt: NSString) {
		author = String(txt)
    }

    @objc func unwrappedAuthor() -> NSString {
        return NSString(string: author!)
    }

    @objc func unwrappedDocumentId() -> NSString {
        return NSString(string: documentId!)
    }

    @objc func setUnwrappedDocumentId(txt: NSString) {
        documentId = String(txt)
    }

    @objc func unwrappedDate() -> NSString {

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"

        return dateFormatter.string(from: date! as Date) as NSString
    }

    @objc func unwrappedStep() -> NSNumber {
        return step! as NSNumber
    }

    @objc func unwrappedEditable() -> NSNumber {
        return editable as NSNumber!
    }

    @objc func setUnwrappedEditable(value: NSNumber) {
        editable = value.boolValue
    }

    @objc func unwrappedType() -> NSString {
        return NSString(string: type!)
    }
	
}
