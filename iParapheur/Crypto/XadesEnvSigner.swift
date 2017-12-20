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
import AEXML


/**
 * https://en.wikipedia.org/wiki/XML_Signature
 *
 * TL;DR : We have to build an XML, hashing a part of it and sign the result.
 * In the XML tree, we have to build the Object/SignedInfo/SignatureValue nodes, in that order.
 * Each elements are hashed, and the hash is used in the next one. KeyInfo is order-free.
 */
@objc class XadesEnvSigner: Signer {


    let mSignInfo: SignInfo
    let mPrivateKey: PrivateKey
    let mPublicKey: String

    var mSignedInfoNode: AEXMLElement?
    var mSignatureValueNode: AEXMLElement?
    var mKeyInfoNode: AEXMLElement?
    var mObjectNode: AEXMLElement?
    var mObjectSignedPropertiesNode: AEXMLElement?


    @objc init(signInfo: SignInfo,
               privateKey: PrivateKey) {

        mSignInfo = signInfo
        mPrivateKey = privateKey

        let pollutedPublicKey = String(data: mPrivateKey.publicKey, encoding: String.Encoding.utf8)
        mPublicKey = CryptoUtils.cleanupPublicKey(publicKey: pollutedPublicKey!)
    }


    // <editor-fold desc="Builders">


    private func buildSignedInfo() {

        // Compute values

        let signaturePropertiesString = mObjectSignedPropertiesNode!.xmlCompact
        print("Adrien :: signaturePropertiesString :: \(signaturePropertiesString)")
        let signaturePropertiesHash = CryptoUtils.sha1Base64(string: signaturePropertiesString)
        print("Adrien :: signaturePropertiesHash   :: \(signaturePropertiesHash)")

        let base64hashData = CryptoUtils.dataWithHexString(hex: mSignInfo.hashToSign!)
        let base64Hash = base64hashData.base64EncodedString()

        // Build XML

        let currentRootDocument = AEXMLDocument()

        let currentSignedInfo = currentRootDocument.addChild(name: "ds:SignedInfo")
        currentSignedInfo.addChild(name: "ds:CanonicalizationMethod",
                                   attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])
        currentSignedInfo.addChild(name: "ds:SignatureMethod",
                                   attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#rsa-sha1"])

        let reference1 = currentSignedInfo.addChild(name: "ds:Reference",
                                                    attributes: ["URI": "#\(mSignInfo.pesId!)"])

        let transforms1 = reference1.addChild(name: "ds:Transforms")
        transforms1.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#enveloped-signature"])
        transforms1.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])

        reference1.addChild(name: "ds:DigestMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        reference1.addChild(name: "ds:DigestValue",
                            value: base64Hash)

        let reference2 = currentSignedInfo.addChild(name: "ds:Reference",
                                                    attributes: ["Type": "http://uri.etsi.org/01903/v1.1.1#SignedProperties",
                                                                 "URI": "#\(mSignInfo.pesId!)_SIG_1_SP"])

        let transforms2 = reference2.addChild(name: "ds:Transforms")
        transforms2.addChild(name: "ds:Transform",
                             attributes: ["Algorithm": "http://www.w3.org/2001/10/xml-exc-c14n#"])
        reference2.addChild(name: "ds:DigestMethod",
                            attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        reference2.addChild(name: "ds:DigestValue",
                            value: signaturePropertiesHash)

        mSignedInfoNode = currentRootDocument.root
    }


    private func buildSignatureValue(signedHash: String) {

        let currentRootDocument = AEXMLDocument()

        currentRootDocument.addChild(name: "ds:SignatureValue",
                                     value: signedHash,
                                     attributes: ["Id": "\(mSignInfo.pesId!)_SIG_1_SV"])

        mSignatureValueNode = currentRootDocument.root
    }


    private func buildKeyInfo() {

        // Build XML

        let currentRootDocument = AEXMLDocument()

        let currentKeyInfo = currentRootDocument.addChild(name: "ds:KeyInfo")
        let currentX509data = currentKeyInfo.addChild(name: "ds:X509Data")
        currentX509data.addChild(name: "ds:X509Certificate", value: mPublicKey)

        mKeyInfoNode = currentRootDocument.root
    }


    private func buildObject() {

        let currentRootDocument = AEXMLDocument()

        let currentObjectNode = currentRootDocument.addChild(name: "ds:Object")
        let currentQualifyingProperties = currentObjectNode.addChild(name: "xad:QualifyingProperties",
                                                                     attributes: ["xmlns:xad": "http://uri.etsi.org/01903/v1.1.1#",
                                                                                  "xmlns": "http://uri.etsi.org/01903/v1.1.1#",
                                                                                  "Target": "#\(mSignInfo.pesId!)_SIG_1"])

        currentQualifyingProperties.addChild(mObjectSignedPropertiesNode!)

        mObjectNode = currentRootDocument.root
    }


    private func buildObjectSignedSignatureProperties() {

        // Compute values

        print("Adrien :: publicKey                 :: \(mPublicKey)")
        let cleanedPublicKeySha1 = CryptoUtils.sha1Base64(string: mPublicKey)

        print("Adrien :: publicKeySha1             :: \(cleanedPublicKeySha1)")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        let currentDateIso8601 = dateFormatter.string(from: Date())

        // Build XML

        let currentRootDocument = AEXMLDocument()
        let currentSignedProperties = currentRootDocument.addChild(name: "xad:SignedProperties",
                                                                   attributes: ["Id": "\(mSignInfo.pesId!)_SIG_1_SP"])

        let currentSignedSignatureProperties = currentSignedProperties.addChild(name: "xad:SignedSignatureProperties")
        currentSignedSignatureProperties.addChild(name: "xad:SigningTime", value: currentDateIso8601)

        let currentSigningCertificate = currentSignedSignatureProperties.addChild(name: "xad:SigningCertificate")
        let curretCert = currentSigningCertificate.addChild(name: "xad:Cert")

        let currentCertDigest = curretCert.addChild(name: "xad:CertDigest")
        currentCertDigest.addChild(name: "xad:DigestMethod", attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        currentCertDigest.addChild(name: "xad:DigestValue", value: cleanedPublicKeySha1)

        let currentIssuerSerial = curretCert.addChild(name: "xad:IssuerSerial")
        currentIssuerSerial.addChild(name: "ds:X509IssuerName", value: mPrivateKey.caName)
        currentIssuerSerial.addChild(name: "ds:X509SerialNumber", value: mPrivateKey.serialNumber)

        let currentSignaturePolicyIdentifier = currentSignedSignatureProperties.addChild(name: "xad:SignaturePolicyIdentifier")
        let currentSignaturePolicyId = currentSignaturePolicyIdentifier.addChild(name: "xad:SignaturePolicyId")

        let currentSigPolicyId = currentSignaturePolicyId.addChild(name: "xad:SigPolicyId")
        currentSigPolicyId.addChild(name: "xad:Identifier", value: mSignInfo.pesPolicyId)
        currentSigPolicyId.addChild(name: "xad:Description", value: mSignInfo.pesPolicyDesc)

        let currentSigPolicyHash = currentSignaturePolicyId.addChild(name: "xad:SigPolicyHash")
        currentSigPolicyHash.addChild(name: "xad:DigestMethod", attributes: ["Algorithm": "http://www.w3.org/2000/09/xmldsig#sha1"])
        currentSigPolicyHash.addChild(name: "xad:DigestValue", value: mSignInfo.pesPolicyHash)

        let currentSigPolicyQualifiers = currentSignaturePolicyId.addChild(name: "xad:SigPolicyQualifiers")
        let currentSigPolicyQualifier = currentSigPolicyQualifiers.addChild(name: "xad:SigPolicyQualifier")
        currentSigPolicyQualifier.addChild(name: "xad:SPURI", value: "http://www.s2low.org/PolitiqueSignature-Agent")

        let currentSignatureProductionPlace = currentSignedSignatureProperties.addChild(name: "xad:SignatureProductionPlace")
        currentSignatureProductionPlace.addChild(name: "xad:City", value: mSignInfo.pesCity)
        currentSignatureProductionPlace.addChild(name: "xad:PostalCode", value: mSignInfo.pesPostalCode)
        currentSignatureProductionPlace.addChild(name: "xad:CountryName", value: mSignInfo.pesCountryName)

        let currentSignerRole = currentSignedSignatureProperties.addChild(name: "xad:SignerRole")
        let currentClaimedRoles = currentSignerRole.addChild(name: "xad:ClaimedRoles")
        currentClaimedRoles.addChild(name: "xad:ClaimedRole", value: mSignInfo.pesClaimedRole)

        mObjectSignedPropertiesNode = currentRootDocument.root
    }


    // </editor-fold desc="Builders">

    // <editor-fold desc="Signer">


    override func generateHashToSign() -> String {

        buildObjectSignedSignatureProperties()
        buildSignedInfo()

        let hashToSign = CryptoUtils.sha1Base64(string: mSignedInfoNode!.xmlCompact)
        print("Adrien :: hashToSign                :: \(hashToSign)")

        return hashToSign
    }


    override func buildDataToReturn(signedHash: String) -> String {

        // Compute the rest of the XML wrapper

        buildKeyInfo()
        buildObject()
        buildSignatureValue(signedHash: signedHash)

        // Wrap-up everything

        let rootDocument = AEXMLDocument()
        let documentDetachedExternalSignature = rootDocument.addChild(name: "DocumentDetachedExternalSignature")
        let signature = documentDetachedExternalSignature.addChild(name: "ds:Signature",
                                                                   attributes: [
                                                                       "xmlns:ds": "http://www.w3.org/2000/09/xmldsig#",
                                                                       "Id": "IDF2017-05-17T08-29-45.35_SIG_1"
                                                                   ])

        signature.addChild(mSignedInfoNode!)
        signature.addChild(mSignatureValueNode!)
        signature.addChild(mKeyInfoNode!)
        signature.addChild(mObjectNode!)

        // Return value

        let finalXml = rootDocument.xmlCompact
        print("Adrien - finalXml    = \(finalXml)")
        let finalXmlData = finalXml.data(using: .utf8)
        print("Adrien - finalXmlB64 = \(finalXmlData!.base64EncodedString())")
        return finalXmlData!.base64EncodedString()
    }


    // </editor-fold desc="Signer">

}