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

import XCTest
@testable import iParapheur


class Crypto_ImprimerieNationale_InTokenData: XCTestCase {


    func testDecodeFull() {

        let jsonString = """
            {
                "result": {
                    "token": {
                        "label": "C Carte Pass-IN",
                        "manufacturerId": "Imprimerie Nationale",
                        "serialNumber": "6367610002000000898F"
                    },
                    "certificates": [{
                        "id": "E828BD080FA00000050450524F2002030101",
                        "value": "308205953082047DA00302010202121121835F80C7033E5B46FA9F3848ED5C284C300D06092A864886F70D01010B050030818A310B300906035504061302465231243022060355040A0C1B47726F75706520496D7072696D65726965204E6174696F6E616C65311C301A060355040B0C13303030322034313034393434393630303034363137303506035504030C2E414320496D7072696D65726965204E6174696F6E616C6520456CC3A96D656E746169726520506572736F6E6E656C301E170D3138303131313133343930335A170D3231303131303133343930335A308189310B300906035504061302465231183016060355040A0C0F50726F737065637420436C69656E74311C301A060355040B0C13303030322031323334353637383230303031303117301506035504030C0E5374C3A97068616E6520564153543129302706035504051320653637643134383863643937343530363866353038306636613064653733633330820122300D06092A864886F70D01010105000382010F003082010A0282010100ADF28D27D34AD1BF789B5D8A670A4A6CC1ECA9389727596D7EA2BC214EC51B2A2CD2B11E79D03D41073DFC39A09501414B784ADD2FB6C6C3C21DB5675F5C80E76B3979F01B98C9D2EDE8C397C4203FDC9DF010A467D9A6707E551AE6E3AD037D8AEF702A9C8000598C76A40F6001ED816BACAAEB592665850DA47D65117958221F741761F90E73CA50A5F2BD9F367D6647099DAE4E2CF0A2423C7590C5A413A15DFD4A40731585770FC2BD640303D11F206C091336F6D953B3CE257F7BB79360901207BD15239D61A2DD11E7383B3B7D445EDC12F4D1E0BE0C000A6C1343742E73A9F37A28B16421849FDC2A09F54AECA29A9193039B3AB3A4DBCC87C09B49190203010001A38201F2308201EE300C0603551D130101FF04023000300E0603551D0F0101FF04040302064030520603551D20044B30493047060D2A817A018227010102010166013036303406082B060105050702011628687474703A2F2F7777772E696D7072696D657269656E6174696F6E616C652E66722F47494E2F50433081850603551D1F047E307C307AA078A0768637687474703A2F2F63726C2E696D7072696D657269656E6174696F6E616C652E66722F47494E2F636572742F4143462D454C2D502E63726C863B687474703A2F2F7777772E696D7072696D657269656E6174696F6E616C652E66722F47494E2F43524C2F636572742F4143462D454C2D502E63726C30818806082B06010505070101047C307A303606082B06010505073001862A687474703A2F2F6F6373702D61632D656C2D702E696D7072696D657269656E6174696F6E616C652E6672304006082B060105050730028634687474703A2F2F7777772E696D7072696D657269656E6174696F6E616C652E66722F47494E2F41432F41432D454C2D502E70376230270603551D110420301E811C7374657068616E652E76617374406C696272696369656C2E636F6F70301D0603551D0E0416041485082FBA1ADD6792FF4CF7C27A0657AFBB3A354F301F0603551D230418301680141A5138A69A630E5CE4C8C78EA15EC5D02EDC85CA300D06092A864886F70D01010B05000382010100764E5650FC8FE9FEFEC7C3F0BF895BA0311A8E452771688909C7438E24A39BEFEAD7D2F6D071A40E652C6A21B2FA27CBCB5B32B613AE2CFB2C1C44BA474CE8DECBDDD08BA97C3C084C44646CD10FED66729AF82310A2CDDB5CC48C568CC7936C1C6D02E00DFE58154F9403E76F07C54C0D45AE0BFD331394F93D492FE0843D5A91D7A7EF84208190CD857B3B16D2D47BA296248FCB5B2F2287021435186759F1B313C28064629649DCE0C75A6A061AD74AB898321BFC67421DE1F52F119A5A31BB87B8954759F42612B18FA99F3494248265DCD9095E33712F7D1EBAA9284A4E21755A9959B2CFDDA1C145D14C24210307BA79349C7BE82FE4148B18D77C6D81"
                    }, {
                        "id": "E828BD080FA00000050450524F2002030108",
                        "value": "308205D7308204BFA003020102021211210FD18DB9E045AA05C34C7F0D20B1E978300D06092A864886F70D01010B050030818A310B300906035504061302465231243022060355040A0C1B47726F75706520496D7072696D65726965204E6174696F6E616C65311C301A060355040B0C13303030322034313034393434393630303034363137303506035504030C2E414320496D7072696D65726965204E6174696F6E616C6520456CC3A96D656E746169726520506572736F6E6E656C301E170D3138303131313133343832385A170D3231303131303133343832385A308189310B300906035504061302465231183016060355040A0C0F50726F737065637420436C69656E74311C301A060355040B0C13303030322031323334353637383230303031303117301506035504030C0E5374C3A97068616E6520564153543129302706035504051320653637643134383863643937343530363866353038306636613064653733633330820122300D06092A864886F70D01010105000382010F003082010A0282010100CE7EB28C8379129F4DB9DD50F5D272E5A89B908251EE66BF330696A5CEC52B1FA402810E33F0473F53E86B86694F2CC7C2D9E19A4404E72764C9F507BC8D2D2542417F6BE478C7E918BC8EE41FCD794FBD7FA843E470EC3A940D12270951B63FBB2DC67099316519D96A2D57DF99748C596E96AE8D0F9084264044174302227EBB997DA777F24E07073B50AF4DDA9A1FA439AD988583C11CB0C2A8B35E89BB633FEDB84A756D855A84DE40F4FF819A2EA8937355D0B693D0A286BB6666B949F9B45A8B98E9781D825F8C54AF6CCB7C8DCAABFC4C9206790E7D63023A1C5425ABBA00FCADB899B42B7A7050F62E7409192642CC44B870483243B0B9312ED9C1FF0203010001A382023430820230300C0603551D130101FF04023000300E0603551D0F0101FF0404030204B030290603551D250422302006082B06010505070302060A2B06010401823714020206082B0601050507030430520603551D20044B30493047060D2A817A018227010102010165013036303406082B060105050702011628687474703A2F2F7777772E696D7072696D657269656E6174696F6E616C652E66722F47494E2F50433081850603551D1F047E307C307AA078A0768637687474703A2F2F63726C2E696D7072696D657269656E6174696F6E616C652E66722F47494E2F636572742F4143462D454C2D502E63726C863B687474703A2F2F7777772E696D7072696D657269656E6174696F6E616C652E66722F47494E2F43524C2F636572742F4143462D454C2D502E63726C30818806082B06010505070101047C307A303606082B06010505073001862A687474703A2F2F6F6373702D61632D656C2D702E696D7072696D657269656E6174696F6E616C652E6672304006082B060105050730028634687474703A2F2F7777772E696D7072696D657269656E6174696F6E616C652E66722F47494E2F41432F41432D454C2D502E703762303E0603551D1104373035A015060A2B060104018237140203A0070C057376617374811C7374657068616E652E76617374406C696272696369656C2E636F6F70301D0603551D0E041604145D1FE7466143B0B6421F247837F8244FBCEECAC7301F0603551D230418301680141A5138A69A630E5CE4C8C78EA15EC5D02EDC85CA300D06092A864886F70D01010B05000382010100295A8165071931454168F9D0D48408E5AA60615D5DC34715DB77FD2DC6B2E3700063B047E7A8BB47A348AE0F5C23D8CC62AC659588D48A60801456764029122F07312293FD171775F7DEAE3098D44299D156971D2F8028CDA7A6B3081FA17F264F8381134B6BDEFEC03080DEEC06E5F1D36F787A89C9CCBC6051B0FC1E90AE44CFE96065AFD5CBB13D2F0BB02347F901A70F3C99036F0FFD75B4BA1D1C2C9CBBA047E2A82B1BD4C5F6BBE437C1F965B97603F26F5C04DC5E3F7CA74C08BEDC9F9A1DDC0CA924ADCCD051D75CE82E5056CA584400B91C1769B745B244B3841E631D6DABC449C9E8A71F8AD9E7440634F47B69EB78FE0D924C4A9105EDD606AEE2"
                    }],
                    "middleware": {
                        "description": "MW Mobile",
                        "version": "0.6.1",
                        "manufacturerId": "Imprimerie Nationale"
                    }
                },
                "status": {
                    "description": "OK",
                    "code": "00"
                }
            }
        """
        let jsonData = jsonString.data(using:.utf8)!

        let jsonDecoder = JSONDecoder()
        let tokenData = try! jsonDecoder.decode(InTokenData.self, from:jsonData)

        // Checks

        XCTAssertNotNil(tokenData)
        XCTAssertEqual(tokenData.label, "C Carte Pass-IN")
        XCTAssertEqual(tokenData.manufacturerId, "Imprimerie Nationale")
        XCTAssertEqual(tokenData.serialNumber, "6367610002000000898F")
        XCTAssertEqual(tokenData.certificates.count, 2)
        XCTAssertEqual(tokenData.description, "MW Mobile")
        XCTAssertEqual(tokenData.version, "0.6.1")
    }

}
