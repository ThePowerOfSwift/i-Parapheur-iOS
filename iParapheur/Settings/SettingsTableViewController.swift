/*
* Copyright 2012-2016, Adullact-Projet.
* Contributors : SKROBS (2012)
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

import Foundation
import UIKit.UITableViewController

class SettingsTableViewController: UITableViewController {

    @IBOutlet var backButton: UIBarButtonItem!

    let menuElements: [(title:String, elements:[(name:String, segue:String, icon:String)])] = [
            ("Général", [("Comptes", "accountsSegue", "ic_account_outline_white_24dp.png"),
                         ("Certificats", "certificatesSegue", "ic_verified_user_outline_white_24dp.png"),
                         ("Filtres", "filtersSegue", "ic_filter_outline_white_24dp.png")]),
            ("À propos", [("Informations légales", "aboutSegue", "ic_info_outline_white_24dp.png"),
                          ("Licences tierces", "licencesSegue", "ic_copyright_outline_white_24dp.png")])
    ]

    // MARK: LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("View loaded : SettingsTableViewController")

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        backButton.target = self
        backButton.action = #selector(SettingsTableViewController.onBackButtonClicked)
    }

    // TODO: why ?
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//if ([[segue identifier] isEqualToString:@"detail1"]) {
//    DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
//    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
//    controller.navigationItem.leftItemsSupplementBackButton = YES;
//    return;
//}
//if ([[segue identifier] isEqualToString:@"detail2"]) {
//    DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
//    controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
//    controller.navigationItem.leftItemsSupplementBackButton = YES;
//    return;
//}
//}

    // MARK: Listeners

    func onBackButtonClicked() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: UITableViewController

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return menuElements.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return menuElements[section].title
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier("SettingsMenuHeader")

        return header
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuElements[section].elements.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsMenuCell", forIndexPath: indexPath)

        if let iconView = cell.viewWithTag(101) as? UIImageView {
            iconView.image = UIImage(named: menuElements[indexPath.section].elements[indexPath.row].icon)?.imageWithRenderingMode(.AlwaysTemplate)
        }

        if let textLabel = cell.viewWithTag(102) as? UILabel {
            print("here textLabel \(textLabel)")
            textLabel.text = menuElements[indexPath.section].elements[indexPath.row].name
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier(menuElements[indexPath.section].elements[indexPath.row].segue, sender: self)
    }

}


