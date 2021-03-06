/*
 * Copyright 2012-2019, Libriciel SCOP.
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
