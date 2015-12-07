/*
 * Version 1.1
 * CeCILL Copyright (c) 2012, SKROBS, ADULLACT-projet
 * Initiated by ADULLACT-projet S.A.
 * Developped by SKROBS
 *
 * contact@adullact-projet.coop
 *
 * Ce logiciel est un programme informatique servant à faire circuler des
 * documents au travers d'un circuit de validation, où chaque acteur vise
 * le dossier, jusqu'à l'étape finale de signature.
 *
 * Ce logiciel est régi par la licence CeCILL soumise au droit français et
 * respectant les principes de diffusion des logiciels libres. Vous pouvez
 * utiliser, modifier et/ou redistribuer ce programme sous les conditions
 * de la licence CeCILL telle que diffusée par le CEA, le CNRS et l'INRIA
 * sur le site "http://www.cecill.info".
 *
 * En contrepartie de l'accessibilité au code source et des droits de copie,
 * de modification et de redistribution accordés par cette licence, il n'est
 * offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,
 * seule une responsabilité restreinte pèse sur l'auteur du programme,  le
 * titulaire des droits patrimoniaux et les concédants successifs.
 *
 * A cet égard  l'attention de l'utilisateur est attirée sur les risques
 * associés au chargement,  à l'utilisation,  à la modification et/ou au
 * développement et à la reproduction du logiciel par l'utilisateur étant
 * donné sa spécificité de logiciel libre, qui peut le rendre complexe à
 * manipuler et qui le réserve donc à des développeurs et des professionnels
 * avertis possédant  des  connaissances  informatiques approfondies.  Les
 * utilisateurs sont donc invités à charger  et  tester  l'adéquation  du
 * logiciel à leurs besoins dans des conditions permettant d'assurer la
 * sécurité de leurs systèmes et ou de leurs données et, plus généralement,
 * à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.
 *
 * Le fait que vous puissiez accéder à cet en-tête signifie que vous avez
 * pris connaissance de la licence CeCILL, et que vous en avez accepté les
 * termes.
 */

//
//  RGAppDelegate.m
//  iParapheur
//
//

#import "RGAppDelegate.h"
#import "ADLCredentialVault.h"
#import "PrivateKey.h"
#import "ADLCertificateAlertView.h"
#import "ADLAPIRequests.h"
#import "ADLRestClient.h"
#import "DeviceUtils.h"

#define RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT 1
#define RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_DELETE 2

@implementation RGAppDelegate

@synthesize window = _window;
@synthesize splitViewController = _splitViewController;

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize keyStore = _keyStore;


#pragma mark - Life cycle


- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	[self checkP12FilesInLocalDirectory];

	// Override point for customization after application launch.
//	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//		UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//		UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//		splitViewController.delegate = (id)navigationController.topViewController;
//		NSLog(@"delegate : %@", [(id)navigationController.topViewController description]);
//	}

	NSArray *keys = self.keyStore.listPrivateKeys;
	for (PrivateKey *pkey in keys) {
		NSLog(@"commonName %@", pkey.commonName);
		NSLog(@"caName %@", pkey.caName);
		NSLog(@"p12Filename %@", pkey.p12Filename);
		NSString *cert = [[NSString alloc] initWithData:pkey.publicKey
		                                       encoding:NSUTF8StringEncoding];
		NSLog(@"certData %@", cert);
	}


	// UI overrode parameters

	[[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:[UIColor lightGrayColor]];

	//

	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	//  API_LOGIN([[NSUserDefaults standardUserDefaults] stringForKey:@"settings_login"], [[NSUserDefaults standardUserDefaults] stringForKey:@"settings_password"]);

}


- (void)applicationWillTerminate:(UIApplication *)application {
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)saveContext {

	NSError *error = nil;
	NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
	if (managedObjectContext != nil) {
		if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
}


#pragma mark - Core Data stack


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext {

	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}

	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil) {
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return _managedObjectContext;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel {

	if (_managedObjectModel != nil) {
		return _managedObjectModel;
	}
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"KeyStore"
	                                          withExtension:@"momd"];
	NSLog(@"%@", modelURL);
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return _managedObjectModel;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {

	if (_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}

	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"keystore.sqlite"];

	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
	                                               configuration:nil
	                                                         URL:storeURL
	                                                     options:nil
	                                                       error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible;
		 * The schema for the persistent store is incompatible with current managed object model.
		 Check the error message to determine what the actual problem was.
		 
		 
		 If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
		 
		 If you encounter schema incompatibility errors during development, you can reduce their frequency by:
		 * Simply deleting the existing store:
		 [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
		 
		 * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
		 @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
		 
		 Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
		 
		 */
		NSLog(@"%@", storeURL);
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}

	return _persistentStoreCoordinator;
}


#pragma mark - Scheme link


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

	NSDictionary *importCertifArguments = [self parseImportCertificateArgumentsFromUrl:url];
	if (importCertifArguments) {

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		ADLRestClient *restClient = [ADLRestClient sharedManager];
		NSString *certifUrl = importCertifArguments[@"iOsUrl"];
		NSString *certifPwd = importCertifArguments[@"iOsPwd"];

		NSError *downloadError = [restClient downloadCertificateUrlWithUrl:certifUrl
		                                                            onPath:paths[0]];

		if (!downloadError) {
			if (certifPwd) {
				NSArray *p12Docs = [self importableP12Stores];

				for (NSString *p12store in p12Docs)
					if ([p12store.lastPathComponent isEqualToString:certifUrl.lastPathComponent])
						[self importCertificate:p12store
						           withPassword:certifPwd];
			}
			else {
				[self checkP12FilesInLocalDirectory];
			}
		}
		else {
			[DeviceUtils logErrorMessage:downloadError.localizedDescription
			                   withTitle:@"Erreur au téléchargement du certificat"];
		}

		return NO;
	}
}


/**
 * Parsing the given parameters
 * Waiting arguments like :
 *
 * iparapheur://importCertificate?iOsUrl=https://url/certif.p12             (mandatory)
 *                                &iOsPwd=pwd                               (optional)
 *                                &AndroidUrl=https://url/certif.bks        (ignored)
 *                                &AndroidPassword=pwd                      (ignored)
 */
- (NSDictionary *)parseImportCertificateArgumentsFromUrl:(NSURL *)url {

	NSString *urlString = url.absoluteString;

	// Regex :	- should start with iparapheur://					                 ^iparapheur:\/\/
	//			- followed with action name, and a ?	    				         importCertificate\?
	//			- then, catching first group, non greedy						     ([^&]*)=(.*?)
	//          - then, any other group, if exists, till the end of line (max 3)     (?:&([^&]*)=(.*?))?    => 3 times

	NSString *importCertifPattern = @"^iparapheur:\\/\\/importCertificate\\?([^&]*)=(.*?)(?:&([^&]*)=(.*?))?(?:&([^&]*)=(.*?))?(?:&([^&]*)=(.*?))?$";

	NSRegularExpression *isImportCertifRegex = [NSRegularExpression regularExpressionWithPattern:importCertifPattern
	                                                                                     options:NSRegularExpressionCaseInsensitive
	                                                                                       error:nil];

	NSArray *matches = [isImportCertifRegex matchesInString:urlString
	                                                options:0
	                                                  range:NSMakeRange(0, urlString.length)];

	// Default case

	if (!matches.count) {
		NSLog(@"Pattern \"%@\" doesn't match string \"%@\"", importCertifPattern, urlString);
		return nil;
	}

	// Parsing arguments

	NSString *certificateUrl;
	NSString *certificatePassword;
	NSTextCheckingResult *firstMatch = matches[0];

	// Careful there, there is a (i+2) loop.
	// That's weird, but we need to parse couples of key/values, and it ease things with the crappy iOS regex system.
	for (NSUInteger i = 1; i < (firstMatch.numberOfRanges - 1); i = i+2) {
		NSRange range = [firstMatch rangeAtIndex:i];

		// iOS 9.1 poor regex system returns wrong values/length on variable groups catched.
		// If the regex can catch 6 groups, but only capture 4, the remaining 2 will make the entire OS crash on rangeAtIndex.
		if ((range.length > urlString.length) || (range.location > urlString.length))
			break;

		NSString *subString = [urlString substringWithRange:range];
		NSRange nextRange = [firstMatch rangeAtIndex:(i + 1)];
		NSString *nextSubString = [urlString substringWithRange:nextRange];

		if ([subString isEqualToString:@"iOsUrl"])
			certificateUrl = nextSubString;
		else if ([subString isEqualToString:@"iOsPwd"])
			certificatePassword = nextSubString;
	}

	// Build result

	NSMutableDictionary *result = [NSMutableDictionary new];

	if (certificateUrl)
		result[@"iOsUrl"] = certificateUrl;
	if (certificatePassword)
		result[@"iOsPwd"] = certificatePassword;

	return result;
}


#pragma mark - Application's Documents directory


// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {

	return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
	                                               inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Private methods


- (void)checkP12FilesInLocalDirectory {

	NSArray *p12Docs = [self importableP12Stores];

	for (NSString *p12Path in p12Docs) {
		NSLog(@"p12Path :%@", p12Docs);

		NSString *message = [NSString stringWithFormat:@"Entrez le mot de passe pour %@", p12Path.lastPathComponent];
		ADLCertificateAlertView *alertView = [[ADLCertificateAlertView alloc] initWithTitle:@"Importer le certificat"
		                                                                            message:message
		                                                                           delegate:self
		                                                                  cancelButtonTitle:@"Annuler"
		                                                                  otherButtonTitles:@"Confirmer", nil];

		alertView.p12Path = p12Path;
		alertView.tag = RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT;
		[alertView show];
	}
}


- (NSMutableArray *)importableP12Stores {

	NSMutableArray *retval = [NSMutableArray array];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *publicDocumentsDir = paths[0];

	NSError *error;
	NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:publicDocumentsDir
	                                                                     error:&error];
	if (files == nil) {
		NSLog(@"Error reading contents of documents directory: %@", [error localizedDescription]);
		return retval;
	}

	for (NSString *file in files) {
		if (([file.pathExtension compare:@"p12"
		                         options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
				([file.pathExtension compare:@"pfx"
				                     options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
			NSString *fullPath = [publicDocumentsDir stringByAppendingPathComponent:file];
			[retval addObject:fullPath];
		}
	}

	return retval;

}


- (void)importCertificate:(NSString *)certificatePath
			 withPassword:(NSString *)password {

	NSError *error = nil;

	BOOL success = [_keyStore addKey:certificatePath
	                    withPassword:password
	                           error:&error];

	if (!success && error != nil) {

		// Retry on error
		if (error.code == P12OpenErrorCode) {
			NSString *message = [NSString stringWithFormat:@"Entrez le mot de passe pour %@", certificatePath.lastPathComponent];

			ADLCertificateAlertView *realert = [[ADLCertificateAlertView alloc] initWithTitle:@"Erreur de mot de passe"
			                                                                          message:message
			                                                                         delegate:self
			                                                                cancelButtonTitle:@"Annuler"
			                                                                otherButtonTitles:@"Confirmer", nil];

			realert.p12Path = certificatePath;
			realert.tag = RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT;
			[realert show];
		}
		else if (error.code == P12AlreadyImported) {

			[DeviceUtils logWarningMessage:certificatePath.lastPathComponent
			                     withTitle:@"Ce fichier de certificat a déjà été importé."];

			[self deleteCertificate:certificatePath];
		}

		NSLog(@"error %@", error.localizedDescription);
	}
	else {
		[DeviceUtils logSuccessMessage:@"Ce certificat a bien été importé."
		                     withTitle:certificatePath.lastPathComponent];
	}
}


- (void)deleteCertificate:(NSString *)certificatePath {

	NSError *error;
	NSFileManager *fileManager = [NSFileManager defaultManager];

	[fileManager removeItemAtPath:certificatePath
	                        error:&error];

	if (!error) {
		[DeviceUtils logInfoMessage:certificatePath.lastPathComponent
		                  withTitle:@"Ce fichier de certificat a été supprimé."];
	}
	else {
		[DeviceUtils logErrorMessage:error.localizedDescription
		                   withTitle:@"Erreur à la suppression du fichier"];
	}
}


#pragma mark - Api requests delegate


- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSString *s = answer[@"_req"];

	if ([s isEqual:LOGIN_API]) {

		ADLCredentialVault *vault = [ADLCredentialVault sharedCredentialVault];
		ADLCollectivityDef *def = [ADLCollectivityDef copyDefaultCollectity];

		[vault addCredentialForHost:[def host]
		                   andLogin:[def username]
		                 withTicket:API_LOGIN_GET_TICKET(answer)];
	}

}


#pragma mark - KeyStore


- (ADLKeyStore *)keyStore {

	if (_keyStore == nil) {
		_keyStore = [[ADLKeyStore alloc] init];
		_keyStore.managedObjectContext = self.managedObjectContext;
		[_keyStore checkUpdates];
	}

	return _keyStore;
}


#pragma mark - Button listener


- (void)   alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {

	ADLCertificateAlertView *pwdAlertView = (ADLCertificateAlertView *) alertView;

	if (alertView.tag == RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_IMPORT) {

		if (buttonIndex == 1) {
			UITextField *passwordTextField = [alertView textFieldAtIndex:0];

			[self importCertificate:pwdAlertView.p12Path
			           withPassword:passwordTextField.text];
		}
		else {

			ADLCertificateAlertView *realert = [[ADLCertificateAlertView alloc] initWithTitle:@"Voulez-vous supprimer ce certificat ?"
			                                                                          message:pwdAlertView.p12Path.lastPathComponent
			                                                                         delegate:self
			                                                                cancelButtonTitle:@"Annuler"
			                                                                otherButtonTitles:@"Confirmer", nil];

			realert.tag = RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_DELETE;
			realert.p12Path = pwdAlertView.p12Path;
			realert.alertViewStyle = UIAlertViewStyleDefault;
			[realert show];

		}
	}
	else if (alertView.tag == RGAPPDELEGATE_POPUP_TAG_CERTIFICATE_DELETE) {

		if (buttonIndex == 1) {
			[self deleteCertificate:pwdAlertView.p12Path];
		}
	}
}


@end
