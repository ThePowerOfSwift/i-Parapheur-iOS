//
//  ADLResponseDossier.m
//  iParapheur
//
//

#import "ADLResponseDossier.h"
#import "StringUtils.h"


@implementation ADLResponseDossier


+ (NSDictionary *)JSONKeyPathsByPropertyKey {

	return @{
			kRDTitle : kRDTitle,
			kRDNomTdT : kRDNomTdT,
			kRDIncludeAnnexes : kRDIncludeAnnexes,
			kRDLocked : kRDLocked,
			kRDReadingMandatory : kRDReadingMandatory,
			kRDDateEmission : kRDDateEmission,
			kRDVisibility : kRDVisibility,
			kRDIsRead : kRDIsRead,
			kRDActionDemandee : kRDActionDemandee,
			kRDStatus : kRDStatus,
			kRDDocuments : kRDDocuments,
			kRDIsSignPapier : kRDIsSignPapier,
			kRDDateLimite : kRDDateLimite,
			kRDHasRead : kRDHasRead,
			kRDIsXemEnabled : kRDIsXemEnabled,
			kRDActions : kRDActions,
			kRDBanetteName : kRDBanetteName,
			kRDType : kRDType,
			kRDCanAdd : kRDCanAdd,
			kRDProtocole : kRDProtocole,
			kRDMetadatas : kRDMetadatas,
			kRDXPathSignature : kRDXPathSignature,
			kRDSousType : kRDSousType,
			kRDBureauName : kRDBureauName,
			kRDIsSent : kRDIsSent,
			kRDIdentifier : @"id"
	};
}


+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {

	// Tests

	BOOL isStringKey = [StringUtils doesArray:@[kRDVisibility, kRDType, kRDXPathSignature, kRDBanetteName, kRDSousType, kRDActionDemandee, kRDIdentifier, kRDBureauName, kRDProtocole, kRDTitle, kRDStatus, kRDNomTdT]
	                           containsString:key];

	BOOL isBooleanKey = [StringUtils doesArray:@[kRDIncludeAnnexes, kRDLocked, kRDReadingMandatory, kRDIsRead, kRDIsSignPapier, kRDHasRead, kRDIsXemEnabled, kRDCanAdd, kRDIsSent]
	                            containsString:key];

	BOOL isArrayKey = [StringUtils doesArray:@[kRDDocuments, kRDActions]
	                          containsString:key];

	BOOL isIntegerKey = [StringUtils doesArray:@[kRDDateEmission, kRDDateLimite]
	                           containsString:key];

	BOOL isDictionaryKey = [key isEqualToString:kRDMetadatas];

	// Return proper Transformer

	if (isStringKey)
		return [StringUtils getNullToNilValueTransformer];
	else if (isBooleanKey)
		return [StringUtils getNullToFalseValueTransformer];
	else if (isIntegerKey)
		return [StringUtils getNullToZeroValueTransformer];
	else if (isDictionaryKey)
		return [StringUtils getNullToEmptyDictionaryValueTransformer];
	else if (isArrayKey)
		return [StringUtils getNullToEmptyArrayValueTransformer];

	NSLog(@"ADLResponseDossier, unknown parameter : %@", key);
	return nil;
}


@end
