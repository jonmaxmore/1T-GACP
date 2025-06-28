import 'dart:convert';
import 'package:x509/x509.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/pointycastle.dart';

class X509Validator {
  final List<X509Certificate> trustedCertificates;

  X509Validator(this.trustedCertificates);

  bool validateCertificateChain(List<X509Certificate> chain) {
    if (chain.isEmpty) return false;

    // Validate each certificate in the chain
    for (int i = 0; i < chain.length; i++) {
      final cert = chain[i];
      
      // Check validity period
      if (!_isCertificateValidNow(cert)) return false;
      
      // Check signature
      if (i > 0) {
        final issuerCert = chain[i - 1];
        if (!_verifySignature(cert, issuerCert)) return false;
      }
      
      // For root certificate, check trust
      if (i == chain.length - 1) {
        if (!_isTrustedRoot(cert)) return false;
      }
    }

    return true;
  }

  bool _isCertificateValidNow(X509Certificate cert) {
    final now = DateTime.now();
    return now.isAfter(cert.validity.start) && 
           now.isBefore(cert.validity.end);
  }

  bool _verifySignature(
    X509Certificate cert,
    X509Certificate issuer,
  ) {
    try {
      final publicKey = _parsePublicKey(issuer);
      final signer = Signer('SHA-256/RSA');
      signer.init(false, PublicKeyParameter(publicKey));
      
      final tbsData = ASN1Sequence.fromBytes(
        cert.tbsCertificate.contentBytes(),
      );
      final signature = RSASignature(cert.signatureValue);
      
      return signer.verifySignature(
        tbsData.encodedBytes,
        signature,
      );
    } catch (e) {
      return false;
    }
  }

  bool _isTrustedRoot(X509Certificate cert) {
    return trustedCertificates.any((trusted) {
      return _certificatesEqual(cert, trusted);
    });
  }

  bool _certificatesEqual(X509Certificate a, X509Certificate b) {
    return const ListEquality().equals(
      a.encodedBytes,
      b.encodedBytes,
    );
  }

  RSAPublicKey _parsePublicKey(X509Certificate cert) {
    final publicKeyInfo = cert.subjectPublicKeyInfo;
    if (publicKeyInfo is! RSAPublicKey) {
      throw FormatException('Unsupported public key type');
    }
    return RSAPublicKey(
      publicKeyInfo.modulus,
      publicKeyInfo.exponent,
    );
  }

  static List<X509Certificate> loadCertificatesFromPem(String pem) {
    return parsePem(pem)
        .whereType<X509Certificate>()
        .toList();
  }

  static X509Certificate? loadCertificateFromDer(Uint8List der) {
    try {
      return X509Certificate.fromAsn1(ASN1Sequence.fromBytes(der));
    } catch (e) {
      return null;
    }
  }
}
