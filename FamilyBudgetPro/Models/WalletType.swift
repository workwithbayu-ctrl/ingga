import Foundation

enum WalletType: String, Codable, CaseIterable {
    case bank = "Bank"
    case digitalBank = "Bank Digital"
    case cash = "Tunai"

    var icon: String {
        switch self {
        case .bank: return "building.columns.fill"
        case .digitalBank: return "iphone"
        case .cash: return "banknote.fill"
        }
    }

    var displayName: String {
        rawValue
    }
}

// MARK: - Indonesian Banks
enum IndonesianBank: String, CaseIterable {
    // Conventional Banks
    case bca = "BCA"
    case mandiri = "MANDIRI"
    case bni = "BNI"
    case bri = "BRI"
    case btn = "BTN"
    case cimb = "CIMB"
    case danamon = "DANAMON"
    case permata = "PERMATA"
    case bsi = "BSI"
    case ocbc = "OCBC"
    case uob = "UOB"
    case panin = "PANIN"
    case maybank = "MAYBANK"
    case mega = "MEGA"
    case bjb = "BJB"
    case bpdBali = "BPD_BALI"
    case bpdDiy = "BPD_DIY"
    case bniSyariah = "BNI_SYARIAH"
    case mandiriSyariah = "MANDIRI_SYARIAH"
    case bcaSyariah = "BCA_SYARIAH"

    // Digital Banks
    case jago = "JAGO"
    case seabank = "SEABANK"
    case blu = "BLU"
    case jenius = "JENIUS"
    case lineBank = "LINE_BANK"
    case neobank = "NEOBANK"
    case livin = "LIVIN"

    // Cash
    case cash = "CASH"

    var code: String {
        switch self {
        case .bca: return "014"
        case .mandiri: return "008"
        case .bni: return "009"
        case .bri: return "002"
        case .btn: return "200"
        case .cimb: return "022"
        case .danamon: return "011"
        case .permata: return "013"
        case .bsi: return "451"
        case .ocbc: return "028"
        case .uob: return "023"
        case .panin: return "019"
        case .maybank: return "016"
        case .mega: return "426"
        case .bjb: return "110"
        case .bpdBali: return "129"
        case .bpdDiy: return "112"
        case .bniSyariah: return "427"
        case .mandiriSyariah: return "451"
        case .bcaSyariah: return "536"
        case .jago: return "542"
        case .seabank: return "535"
        case .blu: return "946"
        case .jenius: return "213"
        case .lineBank: return "945"
        case .neobank: return "947"
        case .livin: return "008"
        case .cash: return "CASH"
        }
    }

    var name: String {
        switch self {
        case .bca: return "BCA"
        case .mandiri: return "Bank Mandiri"
        case .bni: return "BNI"
        case .bri: return "BRI"
        case .btn: return "BTN"
        case .cimb: return "CIMB Niaga"
        case .danamon: return "Bank Danamon"
        case .permata: return "Bank Permata"
        case .bsi: return "Bank Syariah Indonesia"
        case .ocbc: return "OCBC NISP"
        case .uob: return "UOB Indonesia"
        case .panin: return "Panin Bank"
        case .maybank: return "Maybank Indonesia"
        case .mega: return "Bank Mega"
        case .bjb: return "Bank BJB"
        case .bpdBali: return "BPD Bali"
        case .bpdDiy: return "BPD DIY"
        case .bniSyariah: return "BNI Syariah"
        case .mandiriSyariah: return "Mandiri Syariah"
        case .bcaSyariah: return "BCA Syariah"
        case .jago: return "Bank Jago"
        case .seabank: return "SeaBank"
        case .blu: return "blu by BCA Digital"
        case .jenius: return "Jenius"
        case .lineBank: return "LINE Bank"
        case .neobank: return "Neo Bank"
        case .livin: return "Livin' by Mandiri"
        case .cash: return "Tunai / Cash"
        }
    }

    var walletType: WalletType {
        switch self {
        case .cash: return .cash
        case .jago, .seabank, .blu, .jenius, .lineBank, .neobank, .livin:
            return .digitalBank
        default:
            return .bank
        }
    }

    static var allBanks: [IndonesianBank] {
        allCases.filter { $0 != .cash }
    }

    static var conventionalBanks: [IndonesianBank] {
        [.bca, .mandiri, .bni, .bri, .btn, .cimb, .danamon, .permata, .bsi, .ocbc, .uob, .panin, .maybank, .mega, .bjb, .bpdBali, .bpdDiy, .bniSyariah, .mandiriSyariah, .bcaSyariah]
    }

    static var digitalBanks: [IndonesianBank] {
        [.jago, .seabank, .blu, .jenius, .lineBank, .neobank, .livin]
    }
}
