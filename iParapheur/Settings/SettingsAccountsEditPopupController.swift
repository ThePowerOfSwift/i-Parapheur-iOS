/*
* Copyright 2012-2016, Adullact-Projet.
*
* contact@adullact-projet.coop
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

import UIKit
import CoreData
import Foundation


@objc class SettingsAccountsEditPopupController: UIViewController {

    static let NotifDocumentSaved: String! = "SettingsAccountsEditPopupControllerNotifDocumentSaved"
    static let Segue: String! = "EditAccountSegue"

    static let PreferredWidth: CGFloat = 500
    static let PreferredHeight: CGFloat = 252

	@IBOutlet var cancelButton: UIButton!
    @IBOutlet var testButton: UIButton!
	@IBOutlet var saveButton: UIButton!	
	
	@IBOutlet var titleTextView: UITextField!
	@IBOutlet var urlTextView: UITextField!
	@IBOutlet var loginTextView: UITextField!
	@IBOutlet var passwordTextView: UITextField!

    var currentAccount: Account?
    var currentRestClient: RestClientApiV3?

	// MARK: - Life cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
        print("View loaded : SettingsAccountsEditPopupController")

		self.preferredContentSize = CGSize(width: SettingsAccountsEditPopupController.PreferredWidth,
		                                   height : SettingsAccountsEditPopupController.PreferredHeight);

        // Values

        if (currentAccount != nil) {
            titleTextView.text = currentAccount!.title
            urlTextView.text = currentAccount!.url
            loginTextView.text = currentAccount!.login
            passwordTextView.text = currentAccount!.password
        }

        // Listeners

		cancelButton.addTarget(self,
		                       action: #selector(onCancelButtonClicked),
		                       for: .touchUpInside)

		testButton.addTarget(self,
		                     action: #selector(onTestButtonClicked),
		                     for: .touchUpInside)

		saveButton.addTarget(self,
		                     action: #selector(onSaveButtonClicked),
		                     for: .touchUpInside)
    }

    // MARK: - Listeners

    func onCancelButtonClicked(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    func onTestButtonClicked(sender: UIButton) {

        // Cleanup

        urlTextView.text = StringUtils.cleanupServerName(urlTextView.text!)

        //

        if (currentRestClient != nil) {
            currentRestClient!.manager.invalidateSessionCancelingTasks(true)
        }

        currentRestClient = RestClientApiV3(baseUrl: NSString(string: urlTextView.text!),
                                            login: NSString(string: loginTextView.text!),
                                            password: NSString(string: passwordTextView.text!))

		currentRestClient!.getApiVersion(onResponse: {
                                            (result: NSNumber) in
                                            ViewUtils.logSuccessMessage(message: "Connexion réussie",
                                                                        title: nil,
                                                                        viewController: self)
                                         },
                                         onError: {
                                             (error: NSError) in
                                             ViewUtils.logErrorMessage(message: StringUtils.getErrorMessage(error),
                                                                       title: nil,
                                                                       viewController: self)
                                         })
    }

    func onSaveButtonClicked(sender: UIButton) {

        // Cleanup

        urlTextView.text = StringUtils.cleanupServerName(urlTextView.text!)

        // Update model

        if (currentAccount == nil) {
			currentAccount = NSEntityDescription.insertNewObject(forEntityName: Account.EntityName,
			                                                     into:ModelsDataController.Context!) as! Account

            currentAccount!.id = NSUUID().uuidString
            currentAccount!.isVisible = true
        }

        currentAccount!.title = titleTextView.text
        currentAccount!.url = urlTextView.text
        currentAccount!.login = loginTextView.text
        currentAccount!.password = passwordTextView.text

        // Callback and dismiss

        NotificationCenter.defaultCenter.postNotificationName(SettingsAccountsEditPopupController.NotifDocumentSaved,
                                                                  object: currentAccount!)

        dismiss(animated: true, completion: nil)
    }

}
