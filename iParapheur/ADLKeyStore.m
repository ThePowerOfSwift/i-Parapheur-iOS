//
//  ADLKeyStore.m
//  LiberSignOpenSSL
//
//  Created by Emmanuel Peralta on 27/12/12.
//  Copyright (c) 2012 Emmanuel Peralta. All rights reserved.
//

#import "ADLKeyStore.h"
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/pkcs12.h>
#include <openssl/cms.h>

#import "PrivateKey.h"


@implementation ADLKeyStore

@synthesize managedObjectContext;


static int PKCS7_type_is_other(PKCS7* p7) {
	int isOther=1;
	
	int nid=OBJ_obj2nid(p7->type);
	
	switch( nid )
	{
		case NID_pkcs7_data:
		case NID_pkcs7_signed:
		case NID_pkcs7_enveloped:
		case NID_pkcs7_signedAndEnveloped:
		case NID_pkcs7_digest:
		case NID_pkcs7_encrypted:
			isOther=0;
			break;
		default:
			isOther=1;
	}
	
	return isOther;
	
}


static ASN1_OCTET_STRING *PKCS7_get_octet_string(PKCS7 *p7) {
	if ( PKCS7_type_is_data(p7))
		return p7->d.data;
	if ( PKCS7_type_is_other(p7) && p7->d.other
		&& (p7->d.other->type == V_ASN1_OCTET_STRING))
		return p7->d.other->value.octet_string;
	return NULL;
}


static int adl_do_pkcs7_signed_attrib(PKCS7_SIGNER_INFO *si, unsigned char *md_data, unsigned int md_len) {
	
	
	/* Add signing time if not already present */
	if (!PKCS7_get_signed_attribute(si, NID_pkcs9_signingTime))
	{
		if (!PKCS7_add0_attrib_signing_time(si, NULL))
		{
			PKCS7err(PKCS7_F_DO_PKCS7_SIGNED_ATTRIB,
					 ERR_R_MALLOC_FAILURE);
			return 0;
		}
	}
	
	if (!PKCS7_add1_attrib_digest(si, md_data, md_len))
	{
		PKCS7err(PKCS7_F_DO_PKCS7_SIGNED_ATTRIB, ERR_R_MALLOC_FAILURE);
		return 0;
	}
	
	/* Now sign the attributes */
	if (!PKCS7_SIGNER_INFO_sign(si))
		return 0;
	
	return 1;
}


int ADL_PKCS7_dataFinal(PKCS7 *p7, BIO *bio, unsigned char md_data [], unsigned int md_len) {
	int ret=0;
	int i;
	BIO *btmp;
	PKCS7_SIGNER_INFO *si;
	STACK_OF(X509_ATTRIBUTE) *sk;
	STACK_OF(PKCS7_SIGNER_INFO) *si_sk=NULL;
	ASN1_OCTET_STRING *os=NULL;
	
	i=OBJ_obj2nid(p7->type);
	p7->state=PKCS7_S_HEADER;
	
	switch (i)
	{
		case NID_pkcs7_data:
			os = p7->d.data;
			break;
		case NID_pkcs7_signedAndEnveloped:
			/* XXXXXXXXXXXXXXXX */
			si_sk=p7->d.signed_and_enveloped->signer_info;
			os = p7->d.signed_and_enveloped->enc_data->enc_data;
			if (!os)
			{
				os=M_ASN1_OCTET_STRING_new();
				if (!os)
				{
					PKCS7err(PKCS7_F_PKCS7_DATAFINAL,ERR_R_MALLOC_FAILURE);
					goto err;
				}
				p7->d.signed_and_enveloped->enc_data->enc_data=os;
			}
			break;
		case NID_pkcs7_enveloped:
			/* XXXXXXXXXXXXXXXX */
			os = p7->d.enveloped->enc_data->enc_data;
			if (!os)
			{
				os=M_ASN1_OCTET_STRING_new();
				if (!os)
				{
					PKCS7err(PKCS7_F_PKCS7_DATAFINAL,ERR_R_MALLOC_FAILURE);
					goto err;
				}
				p7->d.enveloped->enc_data->enc_data=os;
			}
			break;
		case NID_pkcs7_signed:
			si_sk=p7->d.sign->signer_info;
			os=PKCS7_get_octet_string(p7->d.sign->contents);
			/* If detached data then the content is excluded */
			if(PKCS7_type_is_data(p7->d.sign->contents) && p7->detached) {
				M_ASN1_OCTET_STRING_free(os);
				p7->d.sign->contents->d.data = NULL;
			}
			break;
			
		case NID_pkcs7_digest:
			os=PKCS7_get_octet_string(p7->d.digest->contents);
			/* If detached data then the content is excluded */
			if(PKCS7_type_is_data(p7->d.digest->contents) && p7->detached)
			{
				M_ASN1_OCTET_STRING_free(os);
				p7->d.digest->contents->d.data = NULL;
			}
			break;
			
		default:
			PKCS7err(PKCS7_F_PKCS7_DATAFINAL,PKCS7_R_UNSUPPORTED_CONTENT_TYPE);
			goto err;
	}
	
	if (si_sk != NULL)
	{
		for (i=0; i<sk_PKCS7_SIGNER_INFO_num(si_sk); i++)
		{
			si=sk_PKCS7_SIGNER_INFO_value(si_sk,i);
			if (si->pkey == NULL)
				continue;
			
			// j = OBJ_obj2nid(si->digest_alg->algorithm);
			// btmp=bio;
			
			sk=si->auth_attr;
			
			/* If there are attributes, we add the digest
			 * attribute and only sign the attributes */
			if (sk_X509_ATTRIBUTE_num(sk) > 0)
			{
				if (!adl_do_pkcs7_signed_attrib(si, md_data, md_len))
					goto err;
			}
		}
	}
	
	if (!PKCS7_is_detached(p7) && !(os->flags & ASN1_STRING_FLAG_NDEF))
	{
		char *cont;
		long contlen;
		btmp=BIO_find_type(bio,BIO_TYPE_MEM);
		if (btmp == NULL)
		{
			PKCS7err(PKCS7_F_PKCS7_DATAFINAL,PKCS7_R_UNABLE_TO_FIND_MEM_BIO);
			goto err;
		}
		contlen = BIO_get_mem_data(btmp, &cont);
		/* Mark the BIO read only then we can use its copy of the data
		 * instead of making an extra copy.
		 */
		BIO_set_flags(btmp, BIO_FLAGS_MEM_RDONLY);
		BIO_set_mem_eof_return(btmp, 0);
		ASN1_STRING_set0(os, (unsigned char *)cont, contlen);
	}
	ret=1;
err:
	return(ret);
}


-(void)checkUpdates {
	
	// Previously, full p12 file path was keeped in the DB.
	// But the app data folder path changes on every update.
	// Here we have to check previous data stored, and patch it.

	NSArray* keys = [self listPrivateKeys];

	for (PrivateKey* oldKey in keys) {
		if ([oldKey.p12Filename pathComponents].count != 2) {
			
			NSString* relativePath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundleIdentifier], [oldKey.p12Filename lastPathComponent]];
			oldKey.p12Filename = relativePath;

			[self.managedObjectContext save:nil];
		}
	}
}


NSData* X509_to_NSData(X509 *cert) {
	unsigned char *cert_data = NULL;
	BIO * mem = BIO_new(BIO_s_mem());
	PEM_write_bio_X509(mem, cert);
	(void)BIO_flush(mem);
	int base64Length = BIO_get_mem_data(mem, &cert_data);
	NSData *retVal = [NSData dataWithBytes:cert_data length:base64Length];
	return retVal;
}


-(NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
						   inDomain:(NSSearchPathDomainMask)domainMask
				appendPathComponent:(NSString *)appendComponent
							  error:(NSError **)errorOut {
	
	// Search for the path
	NSArray* paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory,
														 domainMask,
														 YES);
	if ([paths count] == 0)
	{
		// *** creation and return of error object omitted for space
		return nil;
	}
	
	// Normally only need the first path
	NSString *resolvedPath = [paths objectAtIndex:0];
	
	if (appendComponent)
	{
		resolvedPath = [resolvedPath
						stringByAppendingPathComponent:appendComponent];
	}
	
	// Create the path if it doesn't exist
	NSError *error;
	BOOL success = [[NSFileManager defaultManager]
					createDirectoryAtPath:resolvedPath
					withIntermediateDirectories:YES
					attributes:nil
					error:&error];
	if (!success)
	{
		if (errorOut)
		{
			*errorOut = error;
		}
		return nil;
	}
	
	// If we've made it this far, we have a success
	if (errorOut)
	{
		*errorOut = nil;
	}
	return resolvedPath;
}

- (NSURL *)applicationDataDirectory {
	NSString *appBundleId = [[NSBundle mainBundle] bundleIdentifier];
	
	NSError *error;
	NSString *result =
	[self
	 findOrCreateDirectory:NSApplicationSupportDirectory
	 inDomain:NSUserDomainMask
	 appendPathComponent:appBundleId
	 error:&error];
	if (error)
	{
		NSLog(@"Unable to find or create application support directory:\n%@", error);
	}
	return [NSURL fileURLWithPath:result];
}


-(void)recursiveCopyURL:(NSURL*)from
				  toUrl:(NSURL*)to {
	
	NSFileManager* fileManager = [NSFileManager defaultManager]
	;
	NSArray *fileList = [fileManager contentsOfDirectoryAtPath:[from path] error:nil];
	for (NSString *s in fileList) {
		NSURL *newFileURL = [to URLByAppendingPathComponent:s];
		NSURL *oldFileURL = [from URLByAppendingPathComponent:s];
		if (![fileManager fileExistsAtPath:[newFileURL path]]) {
			//File does not exist, copy it
			[fileManager copyItemAtPath:[oldFileURL path] toPath:[newFileURL path] error:nil];
		} else {
			// NSLog(@"File exists: %@", [newFileURL path]);
		}
	}
}


-(NSString*) UUID {
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	NSString *uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
	CFRelease(uuidObj);
	return uuidString;
}


#pragma mark - Public API


-(void) resetKeyStore {
	NSArray *pkeys = [self listPrivateKeys];
	for (PrivateKey *key in pkeys) {
		NSError *error = nil;
		if ([[NSFileManager defaultManager] removeItemAtPath:[key p12Filename] error:&error] != YES)
			NSLog(@"Unable to delete file: %@", [error localizedDescription]);
		[self.managedObjectContext deleteObject:key];
	}
	NSError *error;
	if (![self.managedObjectContext save:&error]) {
		// Something's gone seriously wrong
		NSLog(@"Error clearing KeyStore: %@", [error localizedDescription]);
		
	}
}


-(NSArray*)listPrivateKeys {
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PrivateKey" inManagedObjectContext:self.managedObjectContext];
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:entity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"commonName" ascending:YES];
	NSArray *sortDescriptors = @[sortDescriptor];
	[request setSortDescriptors:sortDescriptors];
	// Fetch the records and handle an error
	NSError *error;
	NSArray *pkeys = [self.managedObjectContext executeFetchRequest:request error:&error];
	return pkeys;
}


-(NSData*)bytesFromHexString:(NSString *)aString; {
	NSString *theString = [[aString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:nil];
	
	NSMutableData* data = [NSMutableData data];
	int idx;
	for (idx = 0; idx+2 <= theString.length; idx+=2) {
		NSRange range = NSMakeRange(idx, 2);
		NSString* hexStr = [theString substringWithRange:range];
		NSScanner* scanner = [NSScanner scannerWithString:hexStr];
		unsigned int intValue;
		if ([scanner scanHexInt:&intValue])
			[data appendBytes:&intValue length:1];
	}
	return data;
}


-(NSDictionary*)PKCS7BatchSign:(NSString*)p12Path
				  withPassword:(NSString*)password
					 andHashes:(NSDictionary *)hashes
						 error:(NSError**) error {
	return nil;
}


-(NSData*)PKCS7Sign:(NSString*)p12Path
	   withPassword:(NSString*)password
			andData:(NSData*)data
			  error:(NSError**)error {
	
	/* Read PKCS12 */
	FILE *fp;
	EVP_PKEY *pkey;
	X509 *cert;
	STACK_OF(X509) *ca = NULL;
	PKCS12 *p12;
	// int i = 0;
	//unsigned char *alias = NULL;
	
	const char *p12_file_path = [p12Path cStringUsingEncoding:NSUTF8StringEncoding];
	const char *p12_password = [password cStringUsingEncoding:NSUTF8StringEncoding];
	
	OpenSSL_add_all_algorithms();
	ERR_load_crypto_strings();
	EVP_add_digest(EVP_sha1());
	NSData *retVal = nil;
	
	if (!(fp = fopen(p12_file_path, "rb"))) {
		NSString* localizedDescritpion = [NSString stringWithFormat:@"Le fichier %@ n'a pas pu être ouvert", [p12Path lastPathComponent]];
		perror("Opening p12 file error : ");
		
		[self emitFileIOError:error
		 localizedDescritpion:localizedDescritpion];
	}
	else {
		p12 = d2i_PKCS12_fp(fp, NULL);
		fclose(fp);
		if (!p12) {
			NSString* localizedDescritpion = [NSString stringWithFormat:@"Impossible de lire %@", [p12Path lastPathComponent]];
			[self emitFileIOError:error localizedDescritpion:localizedDescritpion];
		}
		else {
			if (!PKCS12_parse(p12, p12_password, &pkey, &cert, &ca)) {
				NSString *localizedDescription = [NSString stringWithFormat:@"Impossible de d'ouvrir %@ verifiez le mot de passe", [p12Path lastPathComponent]];
				[self emitError:error localizedDescription:localizedDescription domain:P12ErrorDomain code:P12OpenErrorCode];
			}
			else {
				retVal = [self signData:data pkey:pkey cert:cert];
			}
		}
		PKCS12_free(p12);
	}
	
	return retVal;
}


-(void)emitFileIOError:(NSError **)error
  localizedDescritpion:(NSString *)localizedDescritpion {
	
	[self emitError:error localizedDescription:localizedDescritpion domain:NSPOSIXErrorDomain code:ENOENT];
}


-(void)emitError:(NSError **)error
localizedDescription:(NSString *)localizedDescription
		  domain:(NSString *)domain code:(int)code {
	
#ifdef DEBUG_KEYSTORE
	ERR_print_errors_fp(stderr);
#endif
	if (error) {
		NSDictionary *userInfo = @{NSLocalizedDescriptionKey : localizedDescription};
		*error = [NSError errorWithDomain:domain
		                             code:code
		                         userInfo:userInfo];
	}
}


-(NSData *)signData:(NSData *)data pkey:(EVP_PKEY *)pkey cert:(X509 *)cert {
	
	BIO * bio_data = BIO_new(BIO_s_mem());
	
	BIO_write(bio_data, [data bytes], [data length]);
	
	
	PKCS7 *p7 = PKCS7_new();
	PKCS7_set_type(p7,NID_pkcs7_signed);
	
	PKCS7_SIGNER_INFO *si=PKCS7_add_signature(p7,cert,pkey,EVP_sha1());
	
	if (si == NULL) return nil;
	
	/* If you do this then you get signing time automatically added */
	PKCS7_add_signed_attribute(si, NID_pkcs9_contentType, V_ASN1_OBJECT,
							   OBJ_nid2obj(NID_pkcs7_data));
	
	/* we may want to add more */
	PKCS7_add_certificate(p7, cert);
	
	/* Set the content of the signed to 'data' */
	PKCS7_content_new(p7, NID_pkcs7_data);
	
	PKCS7_set_detached(p7,1);
	BIO* p7bio;
	
	if ((p7bio = PKCS7_dataInit(p7, NULL)) == NULL) {
		return nil;
	}
	
	int i = 0;
	char buf[255];
	for (;;)
	{
		i=BIO_read(bio_data,buf,sizeof(buf));
		if (i <= 0) break;
		BIO_write(p7bio,buf,i);
	}
	
	if (!ADL_PKCS7_dataFinal(p7, p7bio, (unsigned char *)[data bytes], [data length])) {
		return nil;
	}
	BIO_free(p7bio);
	
	BIO *signature_bio = BIO_new(BIO_s_mem());
	
	PEM_write_bio_PKCS7(signature_bio, p7);
	
	(void) BIO_flush(signature_bio);
	
	char *outputBuffer;
	long outputLength = BIO_get_mem_data(signature_bio, &outputBuffer);
	
	NSData *retVal = [NSData dataWithBytes:outputBuffer length:(NSUInteger)outputLength];
	
	
#ifdef DEBUG
	PEM_write_PKCS7(stdout, p7);
#endif
	
	PKCS7_free(p7);
	BIO_free_all(signature_bio);
	
	return retVal;
}


-(BOOL) addKey:(NSString *)p12Path
  withPassword:(NSString *)password
		 error:(NSError**)error {
		
	/* Read PKCS12 */
	FILE *fp;
	EVP_PKEY *pkey;
	X509 *cert;
	STACK_OF(X509) *ca = NULL;
	PKCS12 *p12;
	// int i = 0;
	unsigned char *alias = NULL;
	
	const char *p12_file_path = [p12Path cStringUsingEncoding:NSUTF8StringEncoding];
	const char *p12_password = [password cStringUsingEncoding:NSUTF8StringEncoding];
	
	OpenSSL_add_all_algorithms();
	ERR_load_crypto_strings();
	EVP_add_digest(EVP_sha1());
	
	if (!(fp = fopen(p12_file_path, "rb"))) {
		fprintf(stderr, "Error opening file %s\n", p12_file_path);
		if (error) {
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain
			                             code:ENOENT
			                         userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Le fichier %@ n'a pas pu être ouvert", p12Path.lastPathComponent]}];
		}
		return NO;
	}
	p12 = d2i_PKCS12_fp(fp, NULL);
	fclose (fp);
	if (!p12) {
		fprintf(stderr, "Error reading PKCS#12 file\n");
		ERR_print_errors_fp(stderr);
		if (error) {
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain
			                             code:ENOENT
			                         userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Impossible de lire %@", p12Path.lastPathComponent]}];
			PKCS12_free(p12);
		}
		return NO;
	}
	if (!PKCS12_parse(p12, p12_password, &pkey, &cert, &ca)) {
		fprintf(stderr, "Error parsing PKCS#12 file\n");
		ERR_print_errors_fp(stderr);
		if (error) {
			*error = [NSError errorWithDomain:P12ErrorDomain
			                             code:P12OpenErrorCode
			                         userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Impossible de d'ouvrir %@ verifiez le mot de passe", p12Path.lastPathComponent]}];
		}
		PKCS12_free(p12);
		
		return NO;
	}
	PKCS12_free(p12);
	/*if (!(fp = fopen(argv[3], "w"))) {
	 fprintf(stderr, "Error opening file %s\n", argv[1]);
	 exit(1);
	 }*/
	if (pkey) {
		//  fprintf(stdout, "***Private Key***\n");
		// PEM_write_PrivateKey(stdout, pkey, NULL, NULL, 0, NULL, NULL);
	}
	if (cert) {
		// fprintf(stdout, "***User Certificate***\n");
		// PEM_write_X509_AUX(stdout, cert);
		int len = 0;
		alias = X509_alias_get0(cert, &len);
	}
	if (ca && sk_X509_num(ca)) {
		// fprintf(stdout, "***Other Certificates***\n");
		//for (i = 0; i < sk_X509_num(ca); i++) {
		//PEM_write_X509_AUX(stdout, sk_X509_value(ca, i));
		// int len = 0;
		
		//  unsigned char *alias = X509_alias_get0(sk_X509_value(ca, i), &len);
		//  printf("%s", alias);
		
		//}
	}
	
	// TODO : if (alias == null), error message
	
	// prepare data for the PrivateKey Entity
	NSData *cert_data_to_store = X509_to_NSData(cert);
	
	X509_NAME *issuer_name = X509_get_issuer_name(cert);
	ASN1_INTEGER* cert_serial_number = X509_get_serialNumber(cert);
	BIGNUM *bnser = ASN1_INTEGER_to_BN(cert_serial_number, NULL);
	
	char* big_number_serial_str = BN_bn2hex(bnser);
	
	char issuer_name_str[256];
	
	X509_NAME_oneline(issuer_name, issuer_name_str, 256);
	
	NSEntityDescription *entityDescription = [NSEntityDescription
											  entityForName:@"PrivateKey"
											  inManagedObjectContext:self.managedObjectContext];
	
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:entityDescription];
	
	NSString *commonName_to_find = [NSString stringWithCString:(const char*)alias encoding:NSUTF8StringEncoding];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"commonName=%@ AND caName=%@ AND serialNumber=%@",
							  commonName_to_find,
							  [NSString stringWithCString:(const char*)issuer_name_str encoding:NSUTF8StringEncoding],
							  [NSString stringWithCString:(const char*)big_number_serial_str encoding:NSUTF8StringEncoding]];
	
	[request setPredicate:predicate];
	
	if (error)
		*error = nil;
	NSArray *array = [self.managedObjectContext executeFetchRequest:request error:error];
	
//	if (*error) {
//		NSLog(@"Error fetching keys: %@", [*error localizedDescription]);
//		return NO;
//	}
	
	if ([array count] == 0) {
		
		NSString *newPath = [[[self applicationDataDirectory] path]
							 stringByAppendingPathComponent:[self UUID]];
		
		// move the file to applicationDataDirectory
		[[NSFileManager defaultManager] moveItemAtPath:p12Path
												toPath:newPath
												 error:error];
		
		
		// generate an entry for the new Key
		PrivateKey *new_pk = [NSEntityDescription insertNewObjectForEntityForName:@"PrivateKey" inManagedObjectContext:self.managedObjectContext];
		new_pk.p12Filename = newPath;
		new_pk.publicKey = cert_data_to_store;
		new_pk.commonName = [NSString stringWithCString:(const char*)alias encoding:NSUTF8StringEncoding];
		new_pk.caName = [NSString stringWithCString:(const char*)issuer_name_str encoding:NSUTF8StringEncoding];
		new_pk.serialNumber = [NSString stringWithCString:(const char*)big_number_serial_str encoding:NSUTF8StringEncoding];
		
		*error = nil;
		if (![self.managedObjectContext save:error]) {
			// Something's gone seriously wrong
			NSLog(@"Error saving new PrivateKey: %@", [*error localizedDescription]);
			
		}
	}
	else {
		NSLog(@"Object already in KeyStore %@", [array[0] commonName]);
	}
	
	return YES;
	
	
	
}

@end
