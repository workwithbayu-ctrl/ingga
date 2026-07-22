import Foundation
import FirebaseFirestore

// MARK: - Restore helpers (Firestore -> SwiftData)
private func nonEmpty(_ value: Any?) -> String? {
    guard let str = value as? String, !str.isEmpty else { return nil }
    return str
}

// MARK: - Wallet
extension Wallet {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "type": type,
            "bankCode": bankCode ?? "",
            "accountNumber": accountNumber ?? "",
            "balance": balance,
            "icon": icon,
            "color": color,
            "accountHolder": accountHolder ?? "",
            "sortOrder": sortOrder,
            "isArchived": isArchived,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "familyCode": familyCode ?? "",
            "firebaseUid": firebaseUid ?? ""
        ]
    }

    /// Rekonstruksi Wallet dari dokumen Firestore (dipakai saat restore data setelah install ulang / join keluarga)
    static func fromFirestoreData(_ data: [String: Any]) -> Wallet? {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let name = data["name"] as? String else { return nil }

        let typeString = data["type"] as? String ?? WalletType.cash.rawValue
        let wallet = Wallet(
            name: name,
            type: WalletType(rawValue: typeString) ?? .cash,
            bankCode: nonEmpty(data["bankCode"]),
            accountNumber: nonEmpty(data["accountNumber"]),
            balance: data["balance"] as? Double ?? 0,
            icon: data["icon"] as? String,
            colorHex: data["color"] as? String ?? "4A90E2",
            accountHolder: nonEmpty(data["accountHolder"]),
            sortOrder: data["sortOrder"] as? Int ?? 0,
            familyCode: nonEmpty(data["familyCode"]),
            firebaseUid: nonEmpty(data["firebaseUid"])
        )
        wallet.id = id
        wallet.isArchived = data["isArchived"] as? Bool ?? false
        if let ts = data["createdAt"] as? Timestamp { wallet.createdAt = ts.dateValue() }
        if let ts = data["updatedAt"] as? Timestamp { wallet.updatedAt = ts.dateValue() }
        return wallet
    }
}

// MARK: - Category
extension Category {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "type": type.rawValue,
            "icon": icon,
            "colorHex": colorHex,
            "isDefault": isDefault,
            "isSystem": isSystem,
            "sortOrder": sortOrder,
            "parentId": parentCategory?.id.uuidString ?? "",
            "createdAt": Timestamp(date: createdAt),
            "familyCode": familyCode ?? "",
            "firebaseUid": firebaseUid ?? ""
        ]
    }

    /// Rekonstruksi Category dari dokumen Firestore. parentCategory di-link belakangan
    /// (2-pass) karena parent-nya mungkin belum ter-restore saat kategori ini dibuat.
    static func fromFirestoreData(_ data: [String: Any]) -> Category? {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let typeString = data["type"] as? String,
              let type = TransactionType(rawValue: typeString) else { return nil }

        let category = Category(
            name: name,
            type: type,
            icon: data["icon"] as? String ?? "tag.fill",
            colorHex: data["colorHex"] as? String ?? "#8E8E93",
            isDefault: data["isDefault"] as? Bool ?? false,
            isSystem: data["isSystem"] as? Bool ?? false,
            sortOrder: data["sortOrder"] as? Int ?? 0,
            familyCode: nonEmpty(data["familyCode"]),
            firebaseUid: nonEmpty(data["firebaseUid"])
        )
        category.id = id
        if let ts = data["createdAt"] as? Timestamp { category.createdAt = ts.dateValue() }
        return category
    }
}

// MARK: - Pocket
extension Pocket {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "pocketType": pocketType.rawValue,
            "targetAmount": targetAmount,
            "balance": balance,
            "allocationPercentage": allocationPercentage,
            "icon": icon,
            "colorHex": colorHex,
            "walletID": walletID?.uuidString ?? "",
            "isDefault": isDefault,
            "createdAt": Timestamp(date: createdAt),
            "familyCode": familyCode ?? "",
            "firebaseUid": firebaseUid ?? ""
        ]
    }

    /// Rekonstruksi Pocket dari dokumen Firestore
    static func fromFirestoreData(_ data: [String: Any]) -> Pocket? {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let pocketTypeString = data["pocketType"] as? String,
              let pocketType = PocketType(rawValue: pocketTypeString) else { return nil }

        let walletID = (data["walletID"] as? String).flatMap { UUID(uuidString: $0) }

        let pocket = Pocket(
            name: name,
            pocketType: pocketType,
            targetAmount: data["targetAmount"] as? Double ?? 0,
            balance: data["balance"] as? Double ?? 0,
            allocationPercentage: data["allocationPercentage"] as? Double ?? 0,
            icon: data["icon"] as? String ?? pocketType.icon,
            colorHex: data["colorHex"] as? String ?? pocketType.color,
            walletID: walletID,
            isDefault: data["isDefault"] as? Bool ?? false,
            familyCode: nonEmpty(data["familyCode"]),
            firebaseUid: nonEmpty(data["firebaseUid"])
        )
        pocket.id = id
        if let ts = data["createdAt"] as? Timestamp { pocket.createdAt = ts.dateValue() }
        return pocket
    }
}

// MARK: - Transaction
extension Transaction {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "amount": amount,
            "type": type.rawValue,
            "categoryId": category?.id.uuidString ?? "",
            "walletId": wallet?.id.uuidString ?? "",
            "note": note,
            "date": Timestamp(date: date),
            "createdAt": Timestamp(date: createdAt),
            "isTransfer": isTransfer,
            "sourceWalletId": sourceWallet?.id.uuidString ?? "",
            "destinationWalletId": destinationWallet?.id.uuidString ?? "",
            "allocatedPocketID": allocatedPocketID?.uuidString ?? "",
            "allocatedAmount": allocatedAmount,
            "familyCode": familyCode ?? "",
            "firebaseUid": firebaseUid ?? ""
        ]
    }

    /// Rekonstruksi Transaction dari dokumen Firestore. `walletsByID`/`categoriesByID`
    /// adalah lookup dari record yang SUDAH di-restore lebih dulu di sesi pull yang sama,
    /// supaya relasi (wallet, category, sourceWallet, destinationWallet) tersambung dengan benar.
    static func fromFirestoreData(
        _ data: [String: Any],
        walletsByID: [UUID: Wallet],
        categoriesByID: [UUID: Category]
    ) -> Transaction? {
        guard let idString = data["id"] as? String, let id = UUID(uuidString: idString),
              let typeString = data["type"] as? String,
              let type = TransactionType(rawValue: typeString),
              let dateTs = data["date"] as? Timestamp else { return nil }

        let categoryID = (data["categoryId"] as? String).flatMap { UUID(uuidString: $0) }
        let walletID = (data["walletId"] as? String).flatMap { UUID(uuidString: $0) }
        let sourceWalletID = (data["sourceWalletId"] as? String).flatMap { UUID(uuidString: $0) }
        let destWalletID = (data["destinationWalletId"] as? String).flatMap { UUID(uuidString: $0) }

        let transaction = Transaction(
            amount: data["amount"] as? Double ?? 0,
            note: data["note"] as? String ?? "",
            date: dateTs.dateValue(),
            type: type,
            category: categoryID.flatMap { categoriesByID[$0] },
            wallet: walletID.flatMap { walletsByID[$0] },
            allocatedPocketID: (data["allocatedPocketID"] as? String).flatMap { UUID(uuidString: $0) },
            allocatedAmount: data["allocatedAmount"] as? Double ?? 0,
            sourceWallet: sourceWalletID.flatMap { walletsByID[$0] },
            destinationWallet: destWalletID.flatMap { walletsByID[$0] },
            isTransfer: data["isTransfer"] as? Bool ?? false,
            familyCode: nonEmpty(data["familyCode"]),
            firebaseUid: nonEmpty(data["firebaseUid"])
        )
        transaction.id = id
        if let ts = data["createdAt"] as? Timestamp { transaction.createdAt = ts.dateValue() }
        return transaction
    }
}

// MARK: - UserProfile
extension UserProfile {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "firebaseUid": firebaseUid ?? "",
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL ?? "",
            "authProvider": authProvider,
            "createdAt": Timestamp(date: createdAt),
            "lastSyncAt": lastSyncAt != nil ? Timestamp(date: lastSyncAt!) : NSNull(),
            "isLoggedIn": isLoggedIn,
            "familyCode": familyCode ?? "",
            "familyRole": familyRole ?? ""
        ]
    }
}

// MARK: - SyncRecord
extension SyncRecord {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id.uuidString,
            "entityType": entityType,
            "entityId": entityId.uuidString,
            "action": action,
            "timestamp": Timestamp(date: timestamp),
            "syncedToFirebase": syncedToFirebase,
            "firebaseUserId": firebaseUserId ?? ""
        ]
    }
}
