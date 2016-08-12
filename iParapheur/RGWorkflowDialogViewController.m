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
#import "RGWorkflowDialogViewController.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "RGAppDelegate.h"
#import "ADLCertificateAlertView.h"
#import "ADLRequester.h"
#import "ADLAPIHelper.h"
#import "LGViewHUD.h"
#import <NSData_Base64/NSData+Base64.h>
#import "DeviceUtils.h"
#import "StringUtils.h"


#define RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PAPER_SIGNATURE 1
#define RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PASSWORD_SIGNATURE 2


@interface RGWorkflowDialogViewController () {

	NSMutableDictionary *circuits;
}


@end


@implementation RGWorkflowDialogViewController


- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {

	self = [super initWithNibName:nibNameOrNil
	                       bundle:nibBundleOrNil];

	if (self) {
		// Custom initialization
	}

	return self;
}


#pragma mark - LifeCycle


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View Loaded : RGWorkflowDialogViewController");

	_restClient = [ADLRestClient sharedManager];
	circuits = [NSMutableDictionary new];
	_bureauCourant = [ADLSingletonState sharedSingletonState].bureauCourant;
}


- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	_navigationBar.topItem.title = [ADLAPIHelper actionNameForAction:_action
	                                                   withPaperSign:_isPaperSign];

	if ([_action isEqualToString:@"SIGNER" ] && !_isPaperSign) {
		_navigationBar.topItem.rightBarButtonItem.enabled = NO;
	}
	else {
		_certificateLabel.hidden = YES;
		_certificatesTableView.hidden = YES;

		if ([_action isEqualToString:@"REJETER"])
			_annotationPubliqueLabel.text = @"Motif de rejet (obligatoire)";
	}

	// Paper Signature

	BOOL isSignPapier = true;
	for (ADLResponseDossier *dossier in _dossiers) {
		isSignPapier = isSignPapier && dossier.isSignPapier;
	}

	[_paperSignatureButton addTarget:self
	                          action:@selector(onPaperSignatureButtonClicked:)
	                forControlEvents:UIControlEventTouchUpInside];

	//

	ADLKeyStore *keystore = ((RGAppDelegate *) [UIApplication sharedApplication].delegate).keyStore;
	_pkeys = keystore.listPrivateKeys;
}


- (void)viewDidAppear:(BOOL)animated {

	[self retrieveCircuitsForDossierAtIndex:0];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	return YES;
}


#pragma mark - Private methods


- (IBAction)finish:(id)sender {

	ADLRequester *requester = [ADLRequester sharedRequester];

	NSMutableArray *dossierIds = [NSMutableArray new];
	for (ADLResponseDossier *dossier in _dossiers)
		[dossierIds addObject:dossier.identifier];

	NSMutableDictionary *args = @{
			@"dossiers" : dossierIds,
			@"annotPub" : _annotationPublique.text,
			@"annotPriv" : _annotationPrivee.text,
			@"bureauCourant" : _bureauCourant}.mutableCopy;

	if ([_action isEqualToString:@"VISER"] || ([_action isEqualToString:@"SIGNER"] && _isPaperSign)) {
		[self showHud];

		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
			for (ADLResponseDossier *dossier in _dossiers) {
				__weak typeof(self) weakSelf = self;
				[_restClient actionViserForDossier:dossier.identifier
				                         forBureau:_bureauCourant
				              withPublicAnnotation:_annotationPublique.text
				             withPrivateAnnotation:_annotationPrivee.text
				                           success:^(NSArray *result) {
					                           __strong typeof(weakSelf) strongSelf = weakSelf;
					                           if (strongSelf) {
						                           [strongSelf dismissDialogView];
					                           }
				                           }
				                           failure:^(NSError *error) {
					                           __strong typeof(weakSelf) strongSelf = weakSelf;
					                           if (strongSelf) {
						                           NSLog(@"actionViser error : %@", error.localizedDescription);
						                           [strongSelf didEndWithUnReachableNetwork];
					                           }
				                           }];
			}
		}
		else {
			[requester request:@"visa"
			           andArgs:args
			          delegate:self];
		}
	}
	else if ([self.action isEqualToString:@"SECRETARIAT"]) {
		[self showHud];

		// TODO Adrien : switch
		[requester request:@"secretariat"
		           andArgs:args
		          delegate:self];
	}
	else if ([self.action isEqualToString:@"REJETER"]) {
		if (self.annotationPublique.text && (self.annotationPublique.text.length > 0)) {
			[self showHud];

			if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
				for (ADLResponseDossier *dossier in _dossiers) {
					__weak typeof(self) weakSelf = self;
					[_restClient actionRejeterForDossier:dossier.identifier
					                           forBureau:_bureauCourant
					                withPublicAnnotation:_annotationPublique.text
					               withPrivateAnnotation:_annotationPrivee.text
					                             success:^(NSArray *success) {
						                             __strong typeof(weakSelf) strongSelf = weakSelf;
						                             if (strongSelf) {
							                             [strongSelf dismissDialogView];
						                             }
					                             }
					                             failure:^(NSError *error) {
						                             __strong typeof(weakSelf) strongSelf = weakSelf;
						                             if (strongSelf) {
							                             NSLog(@"Action reject error : %@", error.localizedDescription);
							                             [strongSelf didEndWithUnReachableNetwork];
						                             }
					                             }];
				}
			}
			else {
				[requester request:@"reject"
				           andArgs:args
				          delegate:self];
			}
		}
		else {
			[[[UIAlertView alloc] initWithTitle:@"Attention"
			                            message:@"Veuillez saisir le motif de votre rejet"
			                           delegate:nil
			                  cancelButtonTitle:@"Fermer"
			                  otherButtonTitles:nil] show];
		}

	}
	else if ([self.action isEqualToString:@"SIGNER"]) {
		// create signatures array
		PrivateKey *pkey = _currentPKey;

		/* Ask for pkey password */

		ADLCertificateAlertView *alertView =
				[[ADLCertificateAlertView alloc] initWithTitle:@"Déverrouillage de la clef privée"
				                                       message:[NSString stringWithFormat:@"Entrez le mot de passe pour %@", pkey.p12Filename.lastPathComponent]
				                                      delegate:self
				                             cancelButtonTitle:@"Annuler"
				                             otherButtonTitles:@"Confirmer", nil];

		alertView.p12Path = pkey.p12Filename;
		alertView.tag = RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PASSWORD_SIGNATURE;
		[alertView show];
	}

	// [args release];
}


- (IBAction)cancel:(id)sender {

	[self dismissViewControllerAnimated:YES
	                         completion:nil];
}


- (void)showHud {

	LGViewHUD *hud = [LGViewHUD defaultHUD];
	hud.image = [UIImage imageNamed:@"rounded-checkmark.png"];
	hud.topText = @"";
	hud.bottomText = @"Chargement ...";
	hud.activityIndicatorOn = YES;
	[hud showInView:self.view];
}


- (void)hideHud {

	LGViewHUD *hud = [LGViewHUD defaultHUD];
	[hud hideWithAnimation:HUDAnimationHideFadeOut];
}


- (void)dismissDialogView {

	[self hideHud];
	[self dismissViewControllerAnimated:YES
	                         completion:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kDossierActionComplete
	                                                    object:nil];
}


- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSLog(@"MIKAF %@", answer);

	if ([answer[@"_req"] isEqualToString:@"getSignInfo"]) {
		// get selected dossiers for some sign info action :)

		NSMutableArray *hashes = [NSMutableArray new];
		NSMutableArray *dossiers = [NSMutableArray new];
		NSMutableArray *signatures = [NSMutableArray new];

		for (ADLResponseDossier *dossier in _dossiers) {
			NSDictionary *signInfo = answer[dossier.identifier];

			if ([signInfo[@"format"] isEqualToString:@"CMS"]) {
				[dossiers addObject:dossier.identifier];
				[hashes addObject:signInfo[@"hash"]];
			}

		}

		ADLKeyStore *keystore = ((RGAppDelegate *) [UIApplication sharedApplication].delegate).keyStore;
		PrivateKey *pkey = _currentPKey;
		NSError *error = nil;

		for (NSString *hash in hashes) {
			NSData *hash_data = [keystore bytesFromHexString:hash];

			NSFileManager *fileManager = [NSFileManager new];
			NSURL *pathURL = [fileManager URLForDirectory:NSApplicationSupportDirectory
			                                     inDomain:NSUserDomainMask
			                            appropriateForURL:nil
			                                       create:YES
			                                        error:NULL];

			NSString *p12AbsolutePath = [pathURL.path stringByAppendingPathComponent:pkey.p12Filename];

			NSData *signature = [keystore PKCS7Sign:p12AbsolutePath
			                           withPassword:_p12password
			                                andData:hash_data
			                                  error:&error];

			if (signature == nil && error != nil) {
				[DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
				                   withTitle:@"Une erreur s'est produite lors de la signature"
				            inViewController:self];
				break;
			}
			else {
				NSString *b64EncodedSignature = signature.base64EncodedString;
				[signatures addObject:b64EncodedSignature];
			}

		}

		if ((signatures.count > 0) && (signatures.count == hashes.count) && (dossiers.count == hashes.count)) {
			NSMutableDictionary *args = @{
					@"dossiers" : dossiers,
					@"annotPub" : _annotationPublique.text,
					@"annotPriv" : _annotationPrivee.text,
					@"bureauCourant" : _bureauCourant,
					@"signatures" : signatures}.mutableCopy;

			NSLog(@"%@", args);
			ADLRequester *requester = [ADLRequester sharedRequester];

			[self showHud];

			[requester request:@"signature"
			           andArgs:args
			          delegate:self];
		}
	}
	else {
		[self dismissDialogView];
	}

}


- (void)didEndWithUnReachableNetwork {

	[[[UIAlertView alloc] initWithTitle:@"Erreur"
	                            message:@"Une erreur est survenue lors de l'envoi de la requête"
	                           delegate:nil
	                  cancelButtonTitle:@"Fermer"
	                  otherButtonTitles:nil] show];
}


/**
* APIv3 response
*/
- (void)getSignInfoDidEndWithSuccess:(ADLResponseSignInfo *)responseSignInfo {

	NSMutableArray *hashes = [NSMutableArray new];
	NSMutableArray *dossiers = [NSMutableArray new];
	NSMutableArray *signatures = [NSMutableArray new];

	for (ADLResponseDossier *dossier in _dossiers) {
		NSDictionary *signInfo = responseSignInfo.signatureInformations;

		if ([signInfo[@"format"] isEqualToString:@"CMS"]) {
			[dossiers addObject:dossier.identifier];
			[hashes addObject:signInfo[@"hash"]];
		} else {
			[DeviceUtils logWarningMessage:@"Seules les signatures PKCS#7 sont supportées"
			                     withTitle:@"Signature impossible"];
		}
	}

	ADLKeyStore *keystore = ((RGAppDelegate *) [UIApplication sharedApplication].delegate).keyStore;
	PrivateKey *pkey = _currentPKey;

	// Retrieving signature certificate

	NSFileManager *fileManager = [NSFileManager new];
	NSURL *pathURL = [fileManager URLForDirectory:NSApplicationSupportDirectory
	                                     inDomain:NSUserDomainMask
	                            appropriateForURL:nil
	                                       create:YES
	                                        error:NULL];

	NSString *p12AbsolutePath = [pathURL.path stringByAppendingPathComponent:pkey.p12Filename];

	// Building signature response

	for (NSString *hash in hashes) {
		NSMutableString *signedHash;

		// Signing hashes, multi-doc way if needed

		if ([StringUtils doesString:hash
		          containsSubString:@","]) {

			NSArray *subHashes = [hash componentsSeparatedByString:@","];
			for (NSString *subHash in subHashes) {

				NSString *subSignedHash = [self signData:subHash
				                            withKeystore:keystore
				                                 withP12:p12AbsolutePath];

				if (subHash == subHashes.firstObject) {
					signedHash = subSignedHash.mutableCopy;
				} else {
					[signedHash appendString:@","];
					[signedHash appendString:subSignedHash];
				}
			}

		} else {

			signedHash = [self signData:hash
			               withKeystore:keystore
			                    withP12:p12AbsolutePath].mutableCopy;
		}

		// Add result, or cancel on error

		if (signedHash == nil)
			break;

		signedHash = [signedHash stringByReplacingOccurrencesOfString:@"\n"
		                                                   withString:@""].mutableCopy;

		[signatures addObject:signedHash];
	}

	// Checking and sending back result

	if ((signatures.count > 0) && (signatures.count == hashes.count) && (dossiers.count == hashes.count)) {

		for (int i = 0; i < signatures.count; i++) {

			NSLog(@"Send signature dossier=%@, signSize=%lu", dossiers[(NSUInteger) i], sizeof(signatures[(NSUInteger) i]));
			[self showHud];

			__weak typeof(self) weakSelf = self;
			[_restClient actionSignerForDossier:dossiers[(NSUInteger) i]
			                          forBureau:_bureauCourant
			               withPublicAnnotation:_annotationPublique.text
			              withPrivateAnnotation:_annotationPrivee.text
			                      withSignature:signatures[(NSUInteger) i]
			                            success:^(NSArray *array) {
				                            __strong typeof(weakSelf) strongSelf = weakSelf;
				                            if (strongSelf) {
					                            NSLog(@"Signature success");
					                            [strongSelf dismissDialogView];
				                            }
			                            }
			                            failure:^(NSError *restError) {
				                            __strong typeof(weakSelf) strongSelf = weakSelf;
				                            if (strongSelf) {
					                            NSLog(@"Signature fail");
					                            [strongSelf didEndWithUnReachableNetwork];
				                            }
			                            }];
		}
	}
}


/**
 * Retrieve every circuit, to fetch isDigitalSignatureMandatory value.
 * We can't launch every request at the same time, a new one will cancel the previous.
 * That's why we have to reccursively call this method, with incremented index, to fetch every circuit.
 */
- (void)retrieveCircuitsForDossierAtIndex:(NSUInteger)index {

	if (index >= _dossiers.count)
		return;

	__weak typeof(self) weakSelf = self;
	[_restClient getCircuit:((ADLResponseDossier *) _dossiers[index]).identifier
	                success:^(ADLResponseCircuit *circuit) {
		                __strong typeof(weakSelf) strongSelf = weakSelf;
		                if (strongSelf) {
			                circuits[((ADLResponseDossier *) _dossiers[index]).identifier] = circuit;
			                [strongSelf checkSignPapierButtonVisibility];
			                [strongSelf retrieveCircuitsForDossierAtIndex:(index + 1)];
		                }
	                }
	                failure:^(NSError *error) {
		                __strong typeof(weakSelf) strongSelf = weakSelf;
		                if (strongSelf) {
			                circuits[((ADLResponseDossier *) _dossiers[index]).identifier] = nil;
			                [strongSelf checkSignPapierButtonVisibility];
			                [strongSelf retrieveCircuitsForDossierAtIndex:(index + 1)];
		                }
	                }];
}


/**
 * Switch every Dossier to paper signature.
 * We can't launch every request at the same time, a new one will cancel the previous.
 * That's why we have to reccursively call this method, with incremented index, to fetch every circuit.
 */
- (void)switchToPaperSigntureForDocumentAtIndex:(NSUInteger)index {

	if (index >= _dossiers.count) {
		[self dismissDialogView];
		return;
	}

	__weak typeof(self) weakSelf = self;
	[_restClient actionSwitchToPaperSignatureForDossier:((ADLResponseDossier *) _dossiers[index]).identifier
	                                          forBureau:_bureauCourant
	                                            success:^(NSArray *success) {
		                                            __strong typeof(weakSelf) strongSelf = weakSelf;
		                                            if (strongSelf)
			                                            [strongSelf switchToPaperSigntureForDocumentAtIndex:(index + 1)];
	                                            }
	                                            failure:^(NSError *error) {
		                                            __strong typeof(weakSelf) strongSelf = weakSelf;
		                                            if (strongSelf)
			                                            [strongSelf switchToPaperSigntureForDocumentAtIndex:(index + 1)];
	                                            }];
}


- (void)checkSignPapierButtonVisibility {

	BOOL isSignMandatory = false;

	for (ADLResponseDossier *dossier in _dossiers)
		if ((circuits[dossier.identifier] == nil) || (((ADLResponseCircuit *) circuits[dossier.identifier]).isDigitalSignatureMandatory))
			isSignMandatory = true;

	if ([_action isEqualToString:@"SIGNER"] && (!_isPaperSign))
		_paperSignatureButton.hidden = isSignMandatory;
}


- (NSString *)signData:(NSString *)hash
          withKeystore:(ADLKeyStore *)keystore
               withP12:(NSString *)p12AbsolutePath {

	NSData *hash_data = [keystore bytesFromHexString:hash];

	NSError *error = nil;
	NSData *signature = [keystore PKCS7Sign:p12AbsolutePath
	                           withPassword:_p12password
	                                andData:hash_data
	                                  error:&error];

	if (signature == nil && error != nil) {

		[DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
		                   withTitle:@"Une erreur s'est produite lors de la signature"
		            inViewController:self];

		return nil;
	}
	else {
		return [signature base64EncodedString];
	}
}


#pragma mark - UIButton delegate


- (void)onPaperSignatureButtonClicked:(id)sender {

	UIAlertView *signPapierConfirm =
			[[UIAlertView alloc] initWithTitle:@"Voulez vous réellement changer le mode de signature de ce dossier vers le mode signature papier ?"
			                           message:@"Vous devrez imprimer et signer le document manuellement."
			                          delegate:self
			                 cancelButtonTitle:@"Annuler"
			                 otherButtonTitles:@"Confirmer", nil];

	signPapierConfirm.tag = RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PAPER_SIGNATURE;
	[signPapierConfirm show];
}


#pragma mark - UITableView Datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

	return _pkeys.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PKeyCell"];

	if (cell == nil)
		cell = [UITableViewCell new];

	PrivateKey *pkey = _pkeys[(NSUInteger) indexPath.row];
	cell.textLabel.text = pkey.commonName;

	return cell;
}


#pragma mark - UITableView delegate


- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// we selected a private key now fetching it

	_currentPKey = _pkeys[(NSUInteger) indexPath.row];

	// now we have a pkey we can activate Sign Button
	_navigationBar.topItem.rightBarButtonItem.enabled = YES;
}


#pragma mark - UIAlertView delegate


- (void)   alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {

	if (alertView.tag == RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PASSWORD_SIGNATURE) {
		if (buttonIndex == 1) {
			UITextField *passwordTextField = [alertView textFieldAtIndex:0];
			_p12password = passwordTextField.text;

			if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
				for (ADLResponseDossier *dossier in _dossiers) {
					__weak typeof(self) weakSelf = self;
					[_restClient getSignInfoForDossier:dossier.identifier
					                         andBureau:_bureauCourant
					                           success:^(ADLResponseSignInfo *signInfo) {
						                           __strong typeof(weakSelf) strongSelf = weakSelf;
						                           if (strongSelf)
							                           [strongSelf getSignInfoDidEndWithSuccess:signInfo];
					                           }
					                           failure:^(NSError *error) {
						                           NSLog(@"Error on getSignInfo %@", error.localizedDescription);
					                           }];
				}
			}
			else {
				ADLRequester *requester = [ADLRequester sharedRequester];
				NSMutableArray *dossierIds = [NSMutableArray new];

				for (ADLResponseDossier *dossier in _dossiers)
					[dossierIds addObject:dossier.identifier];

				NSDictionary *signInfoArgs = @{@"dossiers" : dossierIds};

				[requester request:@"getSignInfo"
				           andArgs:signInfoArgs
				          delegate:self];
			}
		}
	}
	else if (alertView.tag == RGWORKFLOWDIALOGVIEWCONTROLLER_POPUP_TAG_PAPER_SIGNATURE) {

		if (buttonIndex == 1)
			[self switchToPaperSigntureForDocumentAtIndex:0];
	}
}


@end
