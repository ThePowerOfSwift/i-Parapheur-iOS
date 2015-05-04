
#import "ADLRestClient.h"


@implementation ADLRestClient


static NSNumber *PARAPHEUR_API_VERSION;


+ (id)sharedManager {
	static ADLRestClient *sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}


+(NSNumber *)getRestApiVersion {
	return PARAPHEUR_API_VERSION;
}


+(void)setRestApiVersion:(NSNumber *)apiVersion {
	PARAPHEUR_API_VERSION = apiVersion;
}


- (id)init {
	[self resetClient];
	return self;
}


- (void)resetClient{
	_restClientApi3 = [[ADLRestClientApi3 alloc] init];
}


-(NSString *)getDownloadUrl:(NSString *)dossierId
					 forPdf:(bool)isPdf{
	
	return [_restClientApi3 getDownloadUrl:dossierId
									forPdf:isPdf];
}


-(void)downloadDocument:(NSString*)documentId
                  isPdf:(bool)isPdf
	             atPath:(NSURL*)filePath
	            success:(void (^)(NSString *))success
	            failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 downloadDocument:documentId
	                            isPdf:isPdf
		                       atPath:filePath
	                            success:^(NSString *string) {
	                                success(string);
	                            }
		                        failure:^(NSError *error) {
			                        failure(error);
		                        }];
}


-(NSString *)fixBureauId:(NSString *)dossierId {
	
	NSString *prefixToRemove = @"workspace://SpacesStore/";
	
	if ([dossierId hasPrefix:prefixToRemove])
		return [dossierId substringFromIndex:prefixToRemove.length];
	else
		return dossierId;
}


#pragma mark API calls


- (void)getApiLevel:(void (^)(NSNumber *versionNumber))success
			failure:(void (^)(NSError *error))failure {
	
	[_restClientApi3 getApiLevel:^(NSNumber *versionNumber) {
							success(versionNumber);
						 }
						 failure:^(NSError *error) {
 							failure(error);
						 }];
}


- (void)getBureaux:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getBureaux:^(NSArray *bureaux) { success(bureaux); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getDossiers:(NSString*)bureau
			  page:(int)page
			  size:(int)size
			filter:(NSString*)filterJson
		   success:(void (^)(NSArray *))success
		   failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getDossiers:[self fixBureauId:bureau]
							page:page
							size:size
	 					  filter:(NSString*)filterJson
						 success:^(NSArray *dossiers) { success(dossiers); }
						 failure:^(NSError *error) { failure(error); }];
}


-(void)getDossier:(NSString*)bureauId
		  dossier:(NSString*)dossierId
		  success:(void (^)(ADLResponseDossier *))success
		  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getDossier:[self fixBureauId:bureauId]
						dossier:dossierId
						success:^(ADLResponseDossier *dossier) { success(dossier); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getCircuit:(NSString*)dossier
		  success:(void (^)(ADLResponseCircuit *))success
		  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getCircuit:dossier
						success:^(ADLResponseCircuit *circuits) { success(circuits); }
						failure:^(NSError *error) { failure(error); }];
}


-(void)getAnnotations:(NSString*)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getAnnotations:dossier
							success:^(NSArray *annotations) { success(annotations); }
							failure:^(NSError *error) { failure(error); }];
}


-(void)addAnnotations:(NSDictionary*)annotation
		   forDossier:(NSString *)dossier
			  success:(void (^)(NSArray *))success
			  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionAddAnnotation:annotation
							  forDossier:dossier
								 success:^(NSArray *annotations) { success(annotations); }
								 failure:^(NSError *error) { failure(error); }];
}


-(void)updateAnnotation:(NSDictionary*)annotation
				forPage:(int)page
			 forDossier:(NSString *)dossier
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionUpdateAnnotation:annotation
									forPage:page
								 forDossier:dossier
									success:^(NSArray *annotations) { success(annotations); }
									failure:^(NSError *error) { failure(error); }];
}


-(void)removeAnnotation:(NSDictionary*)annotation
			 forDossier:(NSString *)dossier
				success:(void (^)(NSArray *))success
				failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionRemoveAnnotation:annotation
								 forDossier:dossier
									success:^(NSArray *annotations) { success(annotations); }
									failure:^(NSError *error) { failure(error); }];
}

-(void)getSignInfoForDossier:(NSString *)dossierId
				   andBureau:(NSString *)bureauId
					 success:(void (^)(ADLResponseSignInfo *))success
					 failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 getSignInfoForDossier:dossierId
								 andBureau:[self fixBureauId:bureauId]
								   success:^(ADLResponseSignInfo *signInfo) { success(signInfo); }
								   failure:^(NSError *error) { failure(error); }];
}


-(void)actionViserForDossier:(NSString *)dossierId
				   forBureau:(NSString *)bureauId
		withPublicAnnotation:(NSString *)publicAnnotation
	   withPrivateAnnotation:(NSString *)privateAnnotation
					 success:(void (^)(NSArray *))success
					 failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionViserForDossier:dossierId
								 forBureau:[self fixBureauId:bureauId]
					  withPublicAnnotation:publicAnnotation
					 withPrivateAnnotation:privateAnnotation
								   success:^(NSArray *result) {
									   success(result);
								   }
								   failure:^(NSError *error) {
									   failure(error);
								   }];
}


-(void)actionSignerForDossier:(NSString *)dossierId
					forBureau:(NSString *)bureauId
		 withPublicAnnotation:(NSString *)publicAnnotation
		withPrivateAnnotation:(NSString *)privateAnnotation
				withSignature:(NSString *)signature
					  success:(void (^)(NSArray *))success
					  failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionSignerForDossier:dossierId
								  forBureau:[self fixBureauId:bureauId]
					   withPublicAnnotation:publicAnnotation
					  withPrivateAnnotation:privateAnnotation
							  withSignature:(NSString *)signature
									success:^(NSArray *result) {
										success(result);
									}
									failure:^(NSError *error) {
										failure(error);
									}];
}


-(void)actionRejeterForDossier:(NSString *)dossierId
					 forBureau:(NSString *)bureauId
		  withPublicAnnotation:(NSString *)publicAnnotation
		 withPrivateAnnotation:(NSString *)privateAnnotation
					   success:(void (^)(NSArray *))success
					   failure:(void (^)(NSError *))failure {
	
	[_restClientApi3 actionRejeterForDossier:dossierId
								   forBureau:[self fixBureauId:bureauId]
						withPublicAnnotation:publicAnnotation
					   withPrivateAnnotation:privateAnnotation
									 success:^(NSArray *result) {
										 success(result);
									 }
									 failure:^(NSError *error) {
										 failure(error);
									 }];
}


@end
