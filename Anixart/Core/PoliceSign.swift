import Foundation
import Security

/// 1:1 port of com.swiftsoft.anixartd.utils.Police (Anixart 8.5.2).
/// Verified against the production API (see tools/sign_reference.py).
enum PoliceSign {

    /// MD5 of the APK signing certificate (CERT.RSA), precomputed constant.
    private static let certMD5Hex = "9aa5c7af74e8cd70c86f7f9587bde23d"
    private static let packageName = "com.swiftsoft.anixartd"
    /// Android 14; Police only uses the last digit of SDK_INT.
    private static let sdkInt = 34

    private static let alphabet = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")

    // MARK: Pools (verified against Police.smali)

    private static let pool1 = Array(65...70) + Array(117...122) + Array(48...50) + [43, 33, 38, 60, 41]
    private static let pool2 = Array(78...90) + Array(97...109) + Array(53...57) + [43, 33, 38, 60, 41]
    private static let pool3 = Array(71...76) + Array(111...116) + Array(51...52) + [63, 94, 40, 46, 47]
    private static let pool4 = Array(77...82) + Array(105...110) + Array(53...54) + [36, 92, 37, 125, 64]
    private static let pool5 = Array(83...90) + Array(97...104) + Array(55...57) + [43, 93, 62, 123, 63]
    private static let pool6 = Array(54...57) + [94, 62, 126, 47]
    private static let pool7 = Array(49...53) + [37, 60, 38, 63]
    private static let gI5One = [60, 123, 93, 35, 64]
    private static let gI5Two = [37, 125, 91, 36, 94]

    // MARK: Entry

    static func make() -> String {
        let strA = randomAlphaNumeric(4)   // strD2
        let strA2 = randomAlphaNumeric(8)  // strD
        let iH = Int.random(in: 1...9)

        let strD3 = randomChars(6, pool1)

        // Long.parseLong("1" + reverse(tsSeconds)) + 2112
        let ts = String(Int(Date().timeIntervalSince1970))
        let head = Int64("1" + String(ts.reversed()))! + 2112
        var sb = Array(String(head))
        let length = sb.count
        if length >= 1 {
            var i3 = 1
            var i4 = 0
            while true {
                let pos = i3 + i4
                sb.insert(Character(randomChars(1, pool2)), at: pos)
                i4 += 1
                if i3 == length { break }
                i3 += 1
            }
        }
        let string2 = String(sb)

        let strD4 = randomChars(7, pool3)
        let strD5 = randomChars(4, pool4)
        let jLongValue = [99, 74, 49].randomElement()! - 12
        let strD6 = randomChars(7, pool5)
        let j2 = Int(String(String(sdkInt).last!))!
        let iH2 = Int.random(in: 10...27)

        let str4 = strD3 + string2 + strD4 + strD5 + String(jLongValue) + strD6 + String(j2) + String(iH2)

        let s = String(iH2)
        let i5 = Int(String(s.first!))!
        let i6 = Int(String(s.last!))!
        let i7 = i5 + i6

        let str5: String
        switch i5 {
        case 1:
            let payload = caesar(shiftDigits(str4, i7 - 1), i6)
            let b64 = Data(payload.utf8).base64EncodedString()
            str5 = b64 + String(i6) + randomChars(2, pool7) + randomChars(1, gI5One)
        case 2:
            let b64 = Data(str4.utf8).base64EncodedString()
            str5 = caesar(shiftDigits(b64, i7), i6) + String(i6) + randomChars(2, pool6) + randomChars(1, gI5Two)
        default:
            return ""
        }

        let strI = String(certMD5Hex.reversed())
        let strD2 = strA
        let strD = strA2

        let strE = caesar(strI, countDigits(strD2) + 1)
        let pkgE = caesar(packageName, countDigits(strD) + 2)

        let combined = strD2 + str5 + strE + pkgE + strD
        let b64f = Data(combined.utf8).base64EncodedString()
        return shiftDigits(b64f, iH) + String(iH) + randomAlphaNumeric(7)
    }

    // MARK: User-Agent (AppModule_ProvideRetrofitFactory)

    static func userAgent() -> String {
        "AnixartApp/8.5.2-26032112 (Android 14; SDK 34; arm64-v8a; Google Pixel 8; ru)"
    }

    // MARK: Helpers

    private static func randomAlphaNumeric(_ n: Int) -> String {
        String((0..<n).map { _ in alphabet.randomElement()! })
    }

    private static func randomChars(_ n: Int, _ pool: [Int]) -> String {
        String((0..<n).map { _ in Character(UnicodeScalar(pool.randomElement()!)!) })
    }

    /// Police.g — shift decimal digits by -n (mod 10 within ASCII range).
    private static func shiftDigits(_ s: String, _ n: Int) -> String {
        var out = String.UnicodeScalarView()
        for scalar in s.unicodeScalars {
            if scalar.properties.numericType == .decimal, scalar.value >= 48, scalar.value <= 57 {
                var v = Int(scalar.value) - n
                if v < 48 { v += 10 }
                out.append(UnicodeScalar(v)!)
            } else {
                out.append(scalar)
            }
        }
        return String(out)
    }

    /// Police.e — Caesar shift on ASCII letters, shift % 26, wrap by 26.
    private static func caesar(_ s: String, _ shift: Int) -> String {
        let k = shift % 26
        if k == 0 { return s }
        var out = String.UnicodeScalarView()
        for scalar in s.unicodeScalars {
            var c = Int(scalar.value)
            if c >= 0x41 && c < 0x5B {
                c += k
                if c > 0x5A { c -= 26 }
            } else if c >= 0x61 && c < 0x7B {
                c += k
                if c > 0x7A { c -= 26 }
            }
            out.append(UnicodeScalar(c)!)
        }
        return String(out)
    }

    /// Police.h — count ASCII digits.
    private static func countDigits(_ s: String) -> Int {
        s.unicodeScalars.filter { $0.value >= 48 && $0.value <= 57 }.count
    }
}

/// Keychain-backed token storage.
enum TokenStore {
    private static let service = "com.kharki.anixart.token"
    private static let account = "anixart-session"

    static func save(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        SecItemAdd(attrs as CFDictionary, nil)
        UserDefaults.standard.set(token, forKey: "tokenBackup")
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
           let data = item as? Data {
            return String(data: data, encoding: .utf8)
        }
        return UserDefaults.standard.string(forKey: "tokenBackup")
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "tokenBackup")
    }
}
