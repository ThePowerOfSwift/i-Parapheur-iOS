//
//	ReaderDemoController.m
//	Reader v2.8.6
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2015 Julius Oklamcak. All rights reserved.
//  Modified work : Copyright © 2016 Adullact-Projet
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ADLPDFViewController.h"
#import "ReaderContentView.h"
#import "ReaderContentPage.h"
#import "RGDossierDetailViewController.h"
#import "RGDocumentsView.h"
#import "ADLNotifications.h"
#import "ADLSingletonState.h"
#import "ADLRequester.h"
#import "ADLActionViewController.h"
#import "UIColor+CustomColors.h"
#import "ADLResponseAnnotation.h"
#import "DeviceUtils.h"
#import "StringUtils.h"


@interface ADLPDFViewController () <ReaderViewControllerDelegate>

@end


@implementation ADLPDFViewController


#pragma mark - UIViewController


- (void)viewDidLoad {

	[super viewDidLoad];
	NSLog(@"View loaded : ADLPDFViewController");

	[self deleteEveryBinFile];

	// Build UI

	self.navigationController.navigationBar.tintColor = [UIColor darkBlueColor];
	self.navigationItem.rightBarButtonItem = nil;

	if ([[[UIDevice currentDevice] systemVersion] floatValue] > 8.0) {
		UISplitViewController *uiSplitView = (UISplitViewController *) [UIApplication sharedApplication].delegate.window.rootViewController;
		UIBarButtonItem *backButton = uiSplitView.displayModeButtonItem;

		self.navigationItem.leftBarButtonItem = backButton;
		self.navigationItem.leftItemsSupplementBackButton = YES;

		@try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[backButton.target performSelector:backButton.action];
#pragma clang diagnostic pop
		}
		@catch (NSException *e) {}
	}

	_restClient = [ADLRestClient sharedManager];
}


- (void)viewWillAppear:(BOOL)animated {

	[super viewWillAppear:animated];
	
	// Notifications register
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(dossierSelected:)
												 name:kDossierSelected
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearDetail:)
												 name:kSelectBureauAppeared
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearDetail:)
												 name:kDossierActionComplete
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(clearDetail:)
												 name:kFilterChanged
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showDocumentWithIndex:)
												 name:kshowDocumentWithIndex
											   object:nil];
	
	//
	
	[self.navigationController setNavigationBarHidden:NO
	                                         animated:animated];
}


- (void)viewDidAppear:(BOOL)animated {

	[super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated {

	[super viewDidDisappear:animated];
}


- (void)viewDidUnload {
	[super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
	else
		return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	// [_readerViewController updateScrollViewContentViews];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {

	if ([segue.identifier isEqualToString:@"dossierDetails"]) {

		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3)
			((RGDossierDetailViewController *) segue.destinationViewController).dossierRef = _dossierRef;
		else
			((RGDossierDetailViewController *) segue.destinationViewController).dossier = _document;
	}

	if ([segue.identifier isEqualToString:@"showDocumentPopover"]) {
		((RGDocumentsView *) segue.destinationViewController).documents = [_dossier getUnwrappedDocuments];
		if (_documentsPopover != nil)
			[_documentsPopover dismissPopoverAnimated:NO];

		_documentsPopover = ((UIStoryboardPopoverSegue *) segue).popoverController;
		_documentsPopover.delegate = self;
	}

	if ([segue.identifier isEqualToString:@"showActionPopover"]) {
		if (_actionPopover != nil) {
			[_actionPopover dismissPopoverAnimated:NO];
		}

		NSArray *actions;
		if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
			actions = [ADLAPIHelper actionsForADLResponseDossier:_dossier];
		}
		else {
			actions = [ADLAPIHelper actionsForDossier:_document];
		}

		_actionPopover = ((UIStoryboardPopoverSegue *) segue).popoverController;
		((ADLActionViewController *) _actionPopover.contentViewController).actions = actions.mutableCopy;

		// do something usefull there
		if ([_signatureFormat isEqualToString:@"CMS"]) {
			((ADLActionViewController *) _actionPopover.contentViewController).signatureEnabled = YES;
		}
		else if (_visaEnabled) {
			((ADLActionViewController *) _actionPopover.contentViewController).visaEnabled = YES;
		}

		[_actionPopover setDelegate:self];

	}
}


- (void)didReceiveMemoryWarning {

	[super didReceiveMemoryWarning];
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - ReaderViewControllerDelegate methods


- (void)dismissReaderViewController:(ReaderViewController *)viewController {

	_readerViewController.delegate = nil;
	_readerViewController.dataSource = nil;
	[_readerViewController willMoveToParentViewController:nil];
	[_readerViewController.view removeFromSuperview];
	[_readerViewController removeFromParentViewController];
	_readerViewController = nil;
}


#pragma mark - ADLDrawingViewDataSource
#define kActionButtonsWidth 300.0f
#define kActionButtonsHeight 100.0f


- (NSArray *)annotationsForPage:(NSInteger)page {

	NSMutableArray *annotsAtPage = [[NSMutableArray alloc] init];

	int i = 0; // etapeNumber

	if ([[[ADLRestClient sharedManager] getRestApiVersion] intValue] >= 3) {
		for (ADLResponseAnnotation *etape in _annotations) {
			NSArray *annotationsAtPageForEtape = etape.data[[NSString stringWithFormat:@"%ld",
			                                                                           (long) page]];

			if (_circuit && (_circuit.count > 0)) {
				ADLResponseCircuit *circuit = _circuit[0];

				for (NSDictionary *annot in annotationsAtPageForEtape) {

					NSMutableDictionary *modifiedAnnot = [NSMutableDictionary dictionaryWithDictionary:annot];
					modifiedAnnot[@"editable"] = @(![((NSDictionary *) circuit.etapes[i])[@"approved"] boolValue]);
					[annotsAtPage addObject:[NSDictionary dictionaryWithDictionary:modifiedAnnot]];
				}
			}

			i++;
		}
	}
	else {
		for (NSDictionary *etape in _annotations) {
			NSArray *annotationsAtPageForEtape = etape[[NSString stringWithFormat:@"%ld",
			                                                                      (long) page]];

			if (self.circuit) {
				for (NSDictionary *annot in annotationsAtPageForEtape) {

					NSMutableDictionary *modifiedAnnot = [NSMutableDictionary dictionaryWithDictionary:annot];
					modifiedAnnot[@"editable"] = @(![((NSDictionary *) self.circuit[i])[@"approved"] boolValue]);
					[annotsAtPage addObject:[NSDictionary dictionaryWithDictionary:modifiedAnnot]];
				}
			}

			i++;
		}
	}

	return annotsAtPage;
}


- (void)updateAnnotation:(ADLAnnotation *)annotation
                 forPage:(NSUInteger)page {

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		
		NSDictionary *annotationDictionary = annotation.dict;
		NSString *documentId = [_document getUnwrappedId];

		[_restClient updateAnnotation:annotationDictionary
		                      forPage:(int) page
			               forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
						  andDocument:documentId
			                  success:^(NSArray *result) {
			                      NSLog(@"updateAnnotation success");
			                  }
							  failure:^(NSError *error) {
								  [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
													 withTitle:@"Erreur à la sauvegarde de l'annotation"];
							  }];
	}
	else {
		NSDictionary *dict = [annotation dict];
		NSDictionary *req = @{
				@"page" : @(page),
				@"annotation" : dict,
				@"dossier" : [ADLSingletonState sharedSingletonState].dossierCourantReference
		};

		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:@"updateAnnotation"
		           andArgs:req
			      delegate:self];
	}
}


- (void)removeAnnotation:(ADLAnnotation *)annotation {

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		
		NSDictionary *annotationDictionary = annotation.dict;
		NSString *documentId = [_document getUnwrappedId];

		[_restClient removeAnnotation:annotationDictionary
		                   forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
						  andDocument:documentId
				              success:^(NSArray *result) {
				                  NSLog(@"deleteAnnotation success");
				              }
				              failure:^(NSError *error) {
				                  [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
													 withTitle:@"Erreur à la suppression de l'annotation"];
				              }];
	}
	else {
		NSDictionary *req = @{
				@"uuid" : [annotation uuid],
				@"page" : @10,
				@"dossier" : [ADLSingletonState sharedSingletonState].dossierCourantReference
		};

		ADLRequester *requester = [ADLRequester sharedRequester];

		[requester request:@"removeAnnotation"
		           andArgs:req
			      delegate:self];
	}
}


- (void)addAnnotation:(ADLAnnotation *)annotation
              forPage:(NSUInteger)page {

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		
		NSString *documentId = [_document getUnwrappedId];
		NSString *login = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation][@"settings_login"];

		if (login == nil)
			login = @"bma";

		NSMutableDictionary *args = annotation.dict.mutableCopy;
		args[@"page"] = @(page);
		args[@"date"] = [NSDate date];
		args[@"type"] = @"rect";
		args[@"author"] = login;

		__weak typeof(self) weakSelf = self;
		[_restClient addAnnotations:args
		                 forDossier:[ADLSingletonState sharedSingletonState].dossierCourantReference
						andDocument:documentId
				            success:^(NSArray *result) {
				                __strong typeof(weakSelf) strongSelf = weakSelf;
				                if (strongSelf) {
					                [strongSelf requestAnnotations];
				                }
				            }
				            failure:^(NSError *error) {
				                [DeviceUtils logErrorMessage:[StringUtils getErrorMessage:error]
												   withTitle:@"Erreur à la sauvegarde de l'annotation"];
				            }];
	}
	else {
		NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:annotation.dict];

		[dict setValue:@(page)
		        forKey:@"page"];

		NSDictionary *args = @{
				@"annotations" : @[dict],
				@"dossier" : [ADLSingletonState sharedSingletonState].dossierCourantReference
		};

		ADLRequester *requester = [ADLRequester sharedRequester];
		[requester request:@"addAnnotation"
		           andArgs:args
			      delegate:self];
	}
}


#pragma mark - LGViewHUDDelegate


- (void)shallDismissHUD:(LGViewHUD *)hud {

	HIDE_HUD
}


#pragma mark - ADLParapheurWallDelegateProtocol


- (void)getDossierDidEndWithRequestAnswer:(Dossier *)dossier {

	_dossier = dossier;

	// Determine the first pdf file to display

	for (Document *document in [dossier getUnwrappedDocuments]) {
		if (document.isVisuelPdf) {
			_document = document;
			break;
		}
	}

	//

	[self displayDocumentAt:0];
	self.navigationController.navigationBar.topItem.title = [dossier getUnwrappedTitle];

	// Refresh buttons

	NSArray *buttons;

	if ([dossier getUnwrappedDocuments].count > 1)
		buttons = @[_actionButton, _documentsButton, _detailsButton];
	else
		buttons = @[_actionButton, _detailsButton];

	self.navigationItem.rightBarButtonItems = buttons;

	[self requestSignInfoForDossier:dossier];
}


/**
* Responses for API v2 requests.
*/
- (void)didEndWithRequestAnswer:(NSDictionary *)answer {

	NSString *s = answer[@"_req"];
	HIDE_HUD

	if ([s isEqual:GETDOSSIER_API]) {
//		_document = answer.copy;
		[self displayDocumentAt:0];

		self.navigationController.navigationBar.topItem.title = [_document getUnwrappedName];

		NSArray *buttons;

		if (_dossier.getUnwrappedDocuments.count > 1)
			buttons = @[_actionButton, _documentsButton, _detailsButton];
		else
			buttons = @[_actionButton, _detailsButton];

		self.navigationItem.rightBarButtonItems = buttons;

//		NSString *documentPrincipal = [[_document[@"documents"] objectAtIndex:0] objectForKey:@"downloadUrl"];
//		[[ADLSingletonState sharedSingletonState] setCurrentPrincipalDocPath:documentPrincipal];
//		NSLog(@"%@", _document[@"actions"]);
//
//		if ([[_document[@"actions"] objectForKey:@"sign"] isEqualToNumber:@YES]) {
//			if ([_document[@"actionDemandee"] isEqualToString:@"SIGNATURE"]) {
//				NSDictionary *signInfoArgs = @{@"dossiers" : @[_dossierRef]};
//				ADLRequester *requester = [ADLRequester sharedRequester];
//				[requester request:@"getSignInfo"
//				           andArgs:signInfoArgs
//					      delegate:self];
//			}
//			else {
//				_visaEnabled = YES;
//				_signatureFormat = nil;
//			}
//		}

		SHOW_HUD
	}
	else if ([s isEqualToString:@"getSignInfo"]) {
		_signatureFormat = [[answer[_dossierRef] objectForKey:@"format"] copy];
	}
	else if ([s isEqualToString:GETANNOTATIONS_API]) {
		NSArray *annotations = [answer[@"annotations"] copy];

		_annotations = annotations;

		for (NSNumber *contentViewIdx in [_readerViewController getContentViews]) {
			ReaderContentView *currentReaderContentView = [_readerViewController getContentViews][contentViewIdx];
			[[currentReaderContentView getContentPage] refreshAnnotations];
		}
	}
	else if ([s isEqualToString:@"addAnnotation"]) {
		API_GETANNOTATIONS(_dossierRef);
	}
	else if ([s isEqual:GETCIRCUIT_API]) {
		self.circuit = answer[@"circuit"];
		API_GETANNOTATIONS(_dossierRef);
	}
}


- (void)didEndWithUnReachableNetwork {

	HIDE_HUD
}


- (void)didEndWithUnAuthorizedAccess {

	HIDE_HUD
}


#pragma mark - NotificationCenter selectors


- (void)dossierSelected:(NSNotification *)notification {

	NSString *dossierRef = [notification object];

	_dossierRef = dossierRef;

	SHOW_HUD

	__weak typeof(self) weakSelf = self;
	if ([[[ADLRestClient sharedManager] getRestApiVersion] intValue] >= 3) {
		[_restClient getDossier:[[ADLSingletonState sharedSingletonState] bureauCourant]
		                dossier:_dossierRef
			            success:^(Dossier *result) {
			                __strong typeof(weakSelf) strongSelf = weakSelf;
			                if (strongSelf) {
				                HIDE_HUD
				                [strongSelf getDossierDidEndWithRequestAnswer:result];
			                }
			            }
			            failure:^(NSError *error) {
			                NSLog(@"getBureau fail : %@", error.localizedDescription);
			            }];

		[_restClient getCircuit:_dossierRef
		                success:^(ADLResponseCircuit *circuit) {
		                    __strong typeof(weakSelf) strongSelf = weakSelf;
		                    if (strongSelf) {
			                    HIDE_HUD
			                    strongSelf.circuit = [@[circuit] mutableCopy];
			                    //[strongSelf requestAnnotations];
		                    }
		                }
			            failure:^(NSError *error) {
			                NSLog(@"getCircuit fail : %@", error.localizedDescription);
			            }];
	}
	else {
		API_GETDOSSIER(_dossierRef, [ADLSingletonState sharedSingletonState].bureauCourant);
		API_GETCIRCUIT(_dossierRef);
	}

	//[[self navigationController] popToRootViewControllerAnimated:YES];
}


- (void)showDocumentWithIndex:(NSNotification *)notification {

	NSNumber *docIndex = [notification object];
	[self displayDocumentAt:[docIndex integerValue]];
	[_documentsPopover dismissPopoverAnimated:YES];
	_documentsPopover = nil;
}


- (void)clearDetail:(NSNotification *)notification {

	[self dismissReaderViewController:_readerViewController];

	// Hide title

	self.navigationController.navigationBar.topItem.title = nil;

	// Hide Buttons

	NSArray *buttons = @[];
	self.navigationItem.rightBarButtonItems = buttons;

	// Hide popovers

	if (_documentsPopover != nil)
		[_documentsPopover dismissPopoverAnimated:NO];

	if (_actionPopover != nil)
		[_actionPopover dismissPopoverAnimated:NO];
}


#pragma mark - Split view


- (void)splitViewController:(UISplitViewController *)splitController
     willHideViewController:(UIViewController *)viewController
		  withBarButtonItem:(UIBarButtonItem *)barButtonItem
	   forPopoverController:(UIPopoverController *)popoverController {

	barButtonItem.title = @"Dossiers";
	barButtonItem.tintColor = [UIColor darkBlueColor];

//	[self.navigationItem setLeftBarButtonItem:barButtonItem
//									 animated:YES];
//	self.masterPopoverController = popoverController;
}


- (void)splitViewController:(UISplitViewController *)splitController
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {

	// Called when the view is shown again in the split view, invalidating the button and popover controller.
//	[self.navigationItem setLeftBarButtonItem:nil
//									 animated:YES];

//	self.masterPopoverController = nil;
}


#pragma mark - Private methods


- (void)deleteEveryBinFile {

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    //here everything you want to perform in background

	    // The preferred way to get the apps documents directory

	    NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	    NSString *docDirectory = documentsPaths[0];

	    // Grab all the files in the documents dir

	    NSFileManager *fileManager = [NSFileManager defaultManager];
	    NSArray *allFiles = [fileManager contentsOfDirectoryAtPath:docDirectory
	                                                         error:nil];

	    // Filter the array for only bin files

	    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.bin'"];
	    NSArray *binFiles = [allFiles filteredArrayUsingPredicate:fltr];

	    // Use fast enumeration to iterate the array and delete the files

	    for (NSString *binFile in binFiles) {
		    NSError *error = nil;
		    [fileManager removeItemAtPath:[docDirectory stringByAppendingPathComponent:binFile]
		                            error:&error];
	    }
	});
}


- (NSString *)getFilePathWithDossierRef:(NSString *)dossierRef {

	// The preferred way to get the apps documents directory

	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *docDirectory = documentsPaths[0];

	// Grab all the files in the documents dir

	NSString *fileName = [NSString stringWithFormat:@"%@.bin", _dossierRef];
	NSString *filePath = [docDirectory stringByAppendingPathComponent:fileName];

	return filePath;
}


-(NSURL *)getFileUrlWithDossierRef:(NSString *)dossierRef {

	NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
	                                                                      inDomain:NSUserDomainMask
			                                                     appropriateForURL:nil
			                                                                create:YES
			                                                                 error:nil];

	NSString *fileName = [NSString stringWithFormat:@"%@.bin", dossierRef];
	documentsDirectoryURL = [documentsDirectoryURL URLByAppendingPathComponent:fileName];

	return documentsDirectoryURL;
}


- (void)requestAnnotations {

	if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
		NSString *documentId = [_document getUnwrappedId];
		
		__weak typeof(self) weakSelf = self;
		[_restClient getAnnotations:_dossierRef
						   document:documentId
		                    success:^(NSArray *annotations) {
		                        __strong typeof(weakSelf) strongSelf = weakSelf;
		                        if (strongSelf) {
			                        strongSelf.annotations = annotations;

			                        for (NSNumber *contentViewIdx in strongSelf.readerViewController.getContentViews) {
				                        ReaderContentView *currentReaderContentView = strongSelf.readerViewController.getContentViews[contentViewIdx];
				                        [[currentReaderContentView getContentPage] refreshAnnotations];
			                        }
		                        }
		                    }
			                failure:^(NSError *error) {
			                    NSLog(@"getAnnotations error");
			                }];
	}
	else {
		ADLRequester *requester = [ADLRequester sharedRequester];
		NSDictionary *args = @{@"dossier" : _dossierRef};
		[requester request:GETANNOTATIONS_API
		           andArgs:args
			      delegate:self];
	}
}


- (void)requestSignInfoForDossier:(Dossier *)dossier {

	if ([[dossier getUnwrappedActions] containsObject:@"SIGNATURE"]) {
		if ([[dossier getUnwrappedActionDemandee] isEqualToString:@"SIGNATURE"]) {
			if ([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) {
				__weak typeof(self) weakSelf = self;
				[_restClient getSignInfoForDossier:_dossierRef
				                         andBureau:[ADLSingletonState sharedSingletonState].bureauCourant
						                   success:^(ADLResponseSignInfo *signInfo) {
						                       __strong typeof(weakSelf) strongSelf = weakSelf;
						                       if (strongSelf) {
							                       strongSelf.signatureFormat = signInfo.signatureInformations[@"format"];
						                       }
						                   }
						                   failure:^(NSError *error) {
						                       NSLog(@"getSignInfo %@", error.localizedDescription);
						                   }];
			}
			else {
				SHOW_HUD
				NSDictionary *signInfoArgs = @{@"dossiers" : @[_dossierRef]};
				ADLRequester *requester = [ADLRequester sharedRequester];
				[requester request:@"getSignInfo"
				           andArgs:signInfoArgs
					      delegate:self];
			}
		}
		else {
			_visaEnabled = YES;
			_signatureFormat = nil;
		}
	}
}


- (void)loadPdfAt:(NSString *)filePath {

	_readerDocument = [ReaderDocument withDocumentFilePath:filePath
	                                              password:nil];

	if (_readerDocument != nil) // Must have a valid ReaderDocument object in order to proceed with things
	{
		// Deleting previous child controller

		_readerViewController.delegate = nil;
		_readerViewController.dataSource = nil;
		[_readerViewController willMoveToParentViewController:nil];
		[_readerViewController.view removeFromSuperview];
		[_readerViewController removeFromParentViewController];
		_readerViewController = nil;

		// Creating new child controller

		_readerViewController = [[ReaderViewController alloc] initWithReaderDocument:_readerDocument];
		_readerViewController.delegate = self;
		_readerViewController.dataSource = self;
		_readerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
		_readerViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		[self.view setAutoresizesSubviews:YES];
		[self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

		[self addChildViewController:_readerViewController];
		[self.view addSubview:_readerViewController.view];
	}
	else // Log an error so that we know that something went wrong
	{
		NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:nil] failed.", __FUNCTION__, filePath);
	}
}


- (void)displayDocumentAt:(NSInteger)index {

	_isDocumentPrincipal = (index == 0);
	_document = [_dossier getUnwrappedDocuments][(NSUInteger) index];
	NSString *documentId = [_document getUnwrappedId];
	
	// File cache
	
	NSString *filePath = [self getFileUrlWithDossierRef:documentId].path;
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {

		NSLog(@"PDF : Cached data");

		[self loadPdfAt:filePath];
		[self requestAnnotations];

		return;
	}

	// Downloading files

	NSLog(@"PDF : Download data");

	SHOW_HUD
	ADLRequester *requester = [ADLRequester sharedRequester];
	
	if (([[ADLRestClient sharedManager] getRestApiVersion].intValue >= 3) && [_dossier getUnwrappedDocuments]) {
		bool isPdf = (bool) _document.isVisuelPdf;

		[_restClient downloadDocument:documentId
		                        isPdf:isPdf
			                   atPath:[self getFileUrlWithDossierRef:documentId]
			                  success:^(NSString *string) {
			                      HIDE_HUD
			                      [self loadPdfAt:string];
			                      [self requestAnnotations];
			                  }
			                  failure:^(NSError *error) {
			                      HIDE_HUD
				                  [DeviceUtils logError:error];
			                  }];
	}
	else if (_document) {
//		NSDictionary *document = [_document[@"documents"] objectAtIndex:(NSUInteger) index];
//
//		// Si le document n'a pas de visuelPdf on suppose que le document est en PDF
//		if (document[@"visuelPdfUrl"] != nil) {
//			[requester downloadDocumentAt:document[@"visuelPdfUrl"]
//			                     delegate:self];
//		}
//		else if (document[@"downloadUrl"] != nil) {
//			[requester downloadDocumentAt:document[@"downloadUrl"]
//			                     delegate:self];
//		}
	}
}


- (void)didEndWithDocument:(ADLDocument *)document {

	HIDE_HUD
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    //here everything you want to perform in background

	    NSFileManager *fileManager = [NSFileManager defaultManager];
	    NSFileHandle *file;

	    NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

	    NSString *docPath = documentsPaths[0];
	    NSString *filePath = [NSString stringWithFormat:@"%@/%@.bin",
	                                                    docPath,
	                                                    _dossierRef];
	    [fileManager createFileAtPath:filePath
	                         contents:nil
			               attributes:nil];

	    file = [NSFileHandle fileHandleForWritingAtPath:filePath];
		[file writeData:document.documentData];


	    dispatch_async(dispatch_get_main_queue(), ^{
	        //call back to main queue to update user interface
	        [self loadPdfAt:filePath];
	        [self requestAnnotations];
	    });
	});
}


@end
