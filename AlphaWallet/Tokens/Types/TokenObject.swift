// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import RealmSwift
import BigInt

class TokenObject: Object {
    static func generatePrimaryKey(fromContract contract: AlphaWallet.Address, server: RPCServer) -> String {
        return "\(contract.eip55String)-\(server.chainID)"
    }

    @objc dynamic var primaryKey: String = ""
    @objc dynamic var chainId: Int = 0
    @objc dynamic var contract: String = Constants.nullAddress.eip55String
    @objc dynamic var name: String = ""
    @objc dynamic var symbol: String = ""
    @objc dynamic var decimals: Int = 0
    @objc dynamic var value: String = ""
    @objc dynamic var isDisabled: Bool = false
    @objc dynamic var rawType: String = TokenType.erc20.rawValue
    @objc dynamic var shouldDisplay: Bool = true
    var sortIndex = RealmOptional<Int>()
    //NOTE: Refactor with renaming to nft balance or something similar
    let balance = List<TokenBalance>()

    var nonZeroBalance: [TokenBalance] {
        return Array(balance.filter { isNonZeroBalance($0.balance, tokenType: self.type) })
    }

    var type: TokenType {
        get {
            return TokenType(rawValue: rawType)!
        }
        set {
            rawType = newValue.rawValue
        }
    }

    convenience init(
            contract: AlphaWallet.Address = Constants.nullAddress,
            server: RPCServer,
            name: String = "",
            symbol: String = "",
            decimals: Int = 0,
            value: String,
            isCustom: Bool = false,
            isDisabled: Bool = false,
            type: TokenType
    ) {
        self.init()
        self.primaryKey = TokenObject.generatePrimaryKey(fromContract: contract, server: server)
        self.contract = contract.eip55String
        self.chainId = server.chainID
        self.name = name
        self.symbol = symbol
        self.decimals = decimals
        self.value = value
        self.isDisabled = isDisabled
        self.type = type
    }

    var optionalDecimalValue: NSDecimalNumber? {
        return EtherNumberFormatter.plain.string(from: valueBigInt, decimals: decimals).optionalDecimalValue
    }

    var contractAddress: AlphaWallet.Address {
        return AlphaWallet.Address(uncheckedAgainstNullAddress: contract)!
    }

    var valueBigInt: BigInt {
        return BigInt(value) ?? BigInt()
    }

    override static func primaryKey() -> String? {
        return "primaryKey"
    }

    override static func ignoredProperties() -> [String] {
        return ["type"]
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? TokenObject else { return false }
        //NOTE: to improve perfomance seems like we can use check for primary key instead of checking contracts
        return object.contractAddress.sameContract(as: contractAddress)
    }

    var isERC721Or1155AndNotForTickets: Bool {
        switch type {
        case .erc721, .erc1155:
            return true
        case .nativeCryptocurrency, .erc20, .erc875, .erc721ForTickets:
            return false
        }
    }

    var server: RPCServer {
        return .init(chainID: chainId)
    }
}
