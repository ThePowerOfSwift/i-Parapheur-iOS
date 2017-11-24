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

@objc class Dossier : NSObject, Glossy {

    let id: String?
    let title: String?
    let bureauName: String?
    let banetteName: String?
    let visibility: String?
    let status: String?

    let type: String?
    let sousType: String?
    let protocole: String?
    let nomTdT: String?
    let xPathSignature: String?

    let actionDemandee: String?
    let actions: Array<String>?
    let documents: Array<Document>?
    let acteursVariables: Array<String>?
    let metadatas: Dictionary<String, AnyObject>?
    let dateEmission: NSNumber?
    let dateLimite: NSNumber?

    let hasRead: Bool?
    let includeAnnexes: Bool?
    let isRead: Bool?
    let isSent: Bool?
    let canAdd: Bool?
    let isLocked: Bool?
    let isSignPapier: Bool?
    let isXemEnabled: Bool?
    let isReadingMandatory: Bool?

    // MARK: - Glossy

    required init?(json: JSON) {

        id = ("id" <~~ json) ?? ""
        title = ("title" <~~ json) ?? "(vide)"
        bureauName = ("bureauName" <~~ json) ?? "(vide)"
        banetteName = ("banetteName" <~~ json) ?? ""
        visibility = ("visibility" <~~ json) ?? ""
        status = ("status" <~~ json) ?? ""

        type = ("type" <~~ json) ?? ""
        sousType = ("sousType" <~~ json) ?? ""
        protocole = ("protocole" <~~ json) ?? ""
        nomTdT = ("nomTdT" <~~ json) ?? ""
        xPathSignature = ("xPathSignature" <~~ json) ?? ""

        actionDemandee = ("actionDemandee" <~~ json) ?? "VISA"
        actions = ("actions" <~~ json) ?? []
        documents = ("documents" <~~ json) ?? []
        acteursVariables = ("acteursVariables" <~~ json) ?? []
        metadatas = ("metadatas" <~~ json) ?? [:]
        dateEmission = ("dateEmission" <~~ json) ?? -1
        dateLimite = ("dateLimite" <~~ json) ?? 0

        hasRead = ("hasRead" <~~ json) ?? false
        includeAnnexes = ("includeAnnexes" <~~ json) ?? false
        isRead = ("isRead" <~~ json) ?? false
        isSent = ("isSent" <~~ json) ?? false
        canAdd = ("canAdd" <~~ json) ?? false
        isLocked = ("locked" <~~ json) ?? false
        isSignPapier = ("isSignPapier" <~~ json) ?? false
        isXemEnabled = ("isXemEnabled" <~~ json) ?? false
        isReadingMandatory = ("readingMandatory" <~~ json) ?? false

		// Sometimes it happens
		if (!(actions!.contains(actionDemandee!))) {
			actions!.append(actionDemandee!)
		}
	}

    func toJSON() -> JSON? {
        return nil /* Not used */
    }

    // MARK: - ObjC accessors

    @objc func unwrappedId() -> NSString {
        return NSString(string: id!)
    }

    @objc func unwrappedDocuments() -> NSArray {
        return documents as NSArray!
    }

    @objc func unwrappedTitle() -> NSString {
        return title as NSString!
    }

    @objc func unwrappedActions() -> NSArray {
        return actions as NSArray!
    }

    @objc func unwrappedActionDemandee() -> NSString {
        return NSString(string: actionDemandee!)
    }

    @objc func unwrappedIsSignPapier() -> Bool {
        return isSignPapier!
    }

    @objc func unwrappedType() -> NSString {
        return NSString(string: type!)
    }

    @objc func unwrappedSubType() -> NSString {
        return NSString(string: sousType!)
    }

    @objc func unwrappedLimitDate() -> NSNumber {
        return dateLimite!
    }

    @objc func unwrappedIsLocked() -> Bool {
        return isLocked!
    }

    // MARK: - Static utils

    /**
    * Returns the main negative {@link Action} available, by coherent priority.
    */
    static func getPositiveAction(actions: NSArray) -> NSString! {

        if (actions.contains(NSString(string: "SIGNATURE"))) {
            return NSString(string: "SIGNATURE")
        }

        return NSString(string:"")
    }

    /**
     * Returns the main negative {@link Action} available, by coherent priority.
     */
    @objc static func getNegativeAction(actions: NSArray) -> NSString! {

        if (actions.contains(NSString(string: "REJET"))) {
            return NSString(string: "REJET")
        }

        return NSString(string: "")
    }

    @objc class func filterActions(dossierList: NSArray) -> NSMutableArray {

        let result: NSMutableArray = NSMutableArray()

        // Compute values

        var hasVisa: Bool = true
        var hasSignature: Bool = true
        var hasOnlyVisa: Bool = true
        var hasRejet: Bool = true
        var hasTDT: Bool = true

        for dossierItem in dossierList {
            if let dossier = dossierItem as? Dossier {
                hasVisa = hasVisa && dossier.actions!.contains("VISA")
                hasSignature = hasSignature && (dossier.actions!.contains("SIGNATURE") || dossier.actions!.contains("VISA"))
                hasOnlyVisa = hasOnlyVisa && !dossier.actions!.contains("SIGNATURE")
                hasRejet = hasRejet && dossier.actions!.contains("REJET")
                hasTDT = hasTDT && dossier.actions!.contains("TDT")
            }
        }

        hasSignature = hasSignature && !hasOnlyVisa

        // Build result

        if (hasSignature) {
            result.add(NSString(string: "SIGNATURE"))
        }
        else if (hasVisa) {
            result.add(NSString(string: "VISA"))
        }

        if (hasRejet) {
            result.add(NSString(string: "REJET"))
        }
        if (hasTDT) {
            result.add(NSString(string: "TDT"))
        }

        return result
    }
}
