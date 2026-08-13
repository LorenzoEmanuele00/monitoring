import Foundation
import Security

/// Signs a Google service-account JWT-bearer assertion (RS256) so `FirebaseHostingAdapter`
/// can do the JWT-bearer -> OAuth2 access-token exchange per ADR-0012, without pulling in a
/// third-party JOSE/crypto dependency for one call site. Uses `Security.framework` (`SecKey`)
/// directly, which supports RSA-SHA256 signing from a PKCS#8 private key on macOS.
enum JWTBearerSigner {
    enum SigningError: Error, CustomStringConvertible {
        case invalidPEM
        case keyImportFailed(String)
        case signingFailed(String)
        var description: String {
            switch self {
            case .invalidPEM: return "Service account private key is not valid PEM"
            case .keyImportFailed(let reason): return "Failed to import private key: \(reason)"
            case .signingFailed(let reason): return "JWT signing failed: \(reason)"
            }
        }
    }

    /// Builds and signs a JWT-bearer assertion: header `{"alg":"RS256","typ":"JWT"}`,
    /// claims `{iss, scope, aud, exp, iat}` per Google's service-account OAuth2 flow.
    static func signAssertion(
        clientEmail: String,
        privateKeyPEM: String,
        scope: String,
        audience: String,
        now: Date = Date()
    ) throws -> String {
        let header = try base64URLJSON(["alg": "RS256", "typ": "JWT"])
        let iat = Int(now.timeIntervalSince1970)
        let exp = iat + 3600
        let claims = try base64URLJSON([
            "iss": clientEmail,
            "scope": scope,
            "aud": audience,
            "iat": iat,
            "exp": exp,
        ] as [String: Any])

        let signingInput = "\(header).\(claims)"
        let signature = try sign(signingInput, privateKeyPEM: privateKeyPEM)
        let encodedSignature = base64URLEncode(signature)
        return "\(signingInput).\(encodedSignature)"
    }

    private static func base64URLJSON(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        return base64URLEncode(data)
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func sign(_ input: String, privateKeyPEM: String) throws -> Data {
        let keyData = try pkcs8DER(fromPEM: privateKeyPEM)

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]
        var error: Unmanaged<CFError>?
        guard let secKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            throw SigningError.keyImportFailed((error?.takeRetainedValue() as Error?)?.localizedDescription ?? "unknown")
        }

        guard let signature = SecKeyCreateSignature(
            secKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            Data(input.utf8) as CFData,
            &error
        ) as Data? else {
            throw SigningError.signingFailed((error?.takeRetainedValue() as Error?)?.localizedDescription ?? "unknown")
        }
        return signature
    }

    /// `SecKeyCreateWithData` wants raw PKCS#1 RSA key bytes for `kSecAttrKeyTypeRSA`.
    /// Google service-account keys ship PKCS#8-wrapped PEM; strip the PEM armor and, if it's
    /// a PKCS#8 wrapper (SPKI-style `SEQUENCE { AlgorithmIdentifier, OCTET STRING }`), unwrap
    /// to the inner PKCS#1 `SEQUENCE`.
    private static func pkcs8DER(fromPEM pem: String) throws -> Data {
        let lines = pem
            .split(separator: "\n")
            .filter { !$0.hasPrefix("-----") }
            .joined()
        guard let der = Data(base64Encoded: lines) else {
            throw SigningError.invalidPEM
        }
        return try unwrapPKCS8IfNeeded(der)
    }

    /// Minimal ASN.1 walk: PKCS#8 `PrivateKeyInfo` is
    /// `SEQUENCE { version INTEGER, algorithm SEQUENCE, privateKey OCTET STRING }`
    /// where `privateKey`'s contents are the PKCS#1 `RSAPrivateKey` DER we actually need.
    private static func unwrapPKCS8IfNeeded(_ der: Data) throws -> Data {
        var reader = ASN1Reader(data: der)
        guard let outer = try? reader.readSequence() else { return der }
        var inner = ASN1Reader(data: outer)
        // version INTEGER
        guard (try? inner.readTag(0x02)) != nil else { return der }
        // algorithm identifier SEQUENCE — if the next tag isn't a SEQUENCE, this wasn't PKCS#8.
        guard (try? inner.readTag(0x30)) != nil else { return der }
        // privateKey OCTET STRING — its content bytes are the PKCS#1 key.
        guard let octetString = try? inner.readTag(0x04) else { return der }
        return octetString
    }
}

/// Tiny ASN.1 DER cursor covering only what `unwrapPKCS8IfNeeded` needs — not a general
/// parser.
private struct ASN1Reader {
    let data: Data
    var offset: Int = 0

    init(data: Data) {
        self.data = data
    }

    enum ASN1Error: Error { case truncated, unexpectedTag }

    mutating func readSequence() throws -> Data {
        try readTag(0x30)
    }

    mutating func readTag(_ expected: UInt8) throws -> Data {
        guard offset < data.count else { throw ASN1Error.truncated }
        let tag = data[data.startIndex + offset]
        guard tag == expected else { throw ASN1Error.unexpectedTag }
        offset += 1
        let length = try readLength()
        let start = data.startIndex + offset
        guard start + length <= data.endIndex else { throw ASN1Error.truncated }
        let content = data.subdata(in: start..<(start + length))
        offset += length
        return content
    }

    private mutating func readLength() throws -> Int {
        guard offset < data.count else { throw ASN1Error.truncated }
        let first = data[data.startIndex + offset]
        offset += 1
        if first & 0x80 == 0 {
            return Int(first)
        }
        let byteCount = Int(first & 0x7F)
        guard byteCount > 0, offset + byteCount <= data.count else { throw ASN1Error.truncated }
        var length = 0
        for _ in 0..<byteCount {
            length = (length << 8) | Int(data[data.startIndex + offset])
            offset += 1
        }
        return length
    }
}
