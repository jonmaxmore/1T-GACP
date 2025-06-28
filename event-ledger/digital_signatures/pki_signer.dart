import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/pkcs/rsa_private_key.dart';
import 'package:pointycastle/pkcs/rsa_public_key.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:x509/x509.dart';

class PkiSigner {
  final RSAPrivateKey _privateKey;
  final RSAPublicKey _publicKey;

  PkiSigner.fromPem({
    required String privateKeyPem,
    required String publicKeyPem,
  }) : 
        _privateKey = _parsePrivateKeyPem(privateKeyPem),
        _publicKey = _parsePublicKeyPem(publicKeyPem);

  PkiSigner.fromFiles({
    required String privateKeyPath,
    required String publicKeyPath,
  }) : 
        _privateKey = _parsePrivateKeyPem(File(privateKeyPath).readAsStringSync()),
        _publicKey = _parsePublicKeyPem(File(publicKeyPath).readAsStringSync());

  static RSAPrivateKey _parsePrivateKeyPem(String pem) {
    final key = parsePem(pem).first;
    if (key is! PrivateKeyInfo) {
      throw FormatException('Invalid private key format');
    }
    final rsaPrivateKey = key.privateKey as RSAPrivateKey;
    return RSAPrivateKey(
      rsaPrivateKey.modulus,
      rsaPrivateKey.privateExponent,
      rsaPrivateKey.p,
      rsaPrivateKey.q,
      rsaPrivateKey.dp,
      rsaPrivateKey.dq,
      rsaPrivateKey.qInv,
    );
  }

  static RSAPublicKey _parsePublicKeyPem(String pem) {
    final key = parsePem(pem).first;
    if (key is! PublicKeyInfo) {
      throw FormatException('Invalid public key format');
    }
    final rsaPublicKey = key.publicKey as RSAPublicKey;
    return RSAPublicKey(
      rsaPublicKey.modulus,
      rsaPublicKey.exponent,
    );
  }

  Uint8List sign(Uint8List data) {
    final signer = Signer('SHA-256/RSA');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(_privateKey));
    return signer.generateSignature(data).bytes;
  }

  bool verify(Uint8List data, Uint8List signature) {
    final signer = Signer('SHA-256/RSA');
    signer.init(false, PublicKeyParameter<RSAPublicKey>(_publicKey));
    return signer.verifySignature(data, RSASignature(signature));
  }

  String signString(String data) {
    final signature = sign(utf8.encode(data) as Uint8List);
    return base64Encode(signature);
  }

  bool verifyString(String data, String signatureBase64) {
    final signature = base64Decode(signatureBase64);
    return verify(utf8.encode(data) as Uint8List, signature);
  }

  encrypt.Encrypted encryptData(Uint8List data) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(
      publicKey: encrypt.RSAPublicKey(
        modulus: _publicKey.modulus!,
        exponent: _publicKey.exponent!,
      ),
      privateKey: encrypt.RSAPrivateKey(
        modulus: _privateKey.modulus!,
        exponent: _privateKey.exponent!,
        p: _privateKey.p!,
        q: _privateKey.q!,
        dP: _privateKey.dp!,
        dQ: _privateKey.dq!,
        qInv: _privateKey.qInv!,
      ),
    ));
    return encrypter.encryptBytes(data);
  }

  Uint8List decryptData(encrypt.Encrypted encrypted) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(
      publicKey: encrypt.RSAPublicKey(
        modulus: _publicKey.modulus!,
        exponent: _publicKey.exponent!,
      ),
      privateKey: encrypt.RSAPrivateKey(
        modulus: _privateKey.modulus!,
        exponent: _privateKey.exponent!,
        p: _privateKey.p!,
        q: _privateKey.q!,
        dP: _privateKey.dp!,
        dQ: _privateKey.dq!,
        qInv: _privateKey.qInv!,
      ),
    ));
    return encrypter.decryptBytes(encrypted);
  }
}
