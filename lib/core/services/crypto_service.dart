import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  CryptoService._internal();

  final _secureStorage = const FlutterSecureStorage();
  
  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;
  
  bool get isInitialized => _privateKey != null && _publicKey != null;

  Future<void> initialize() async {
    if (isInitialized) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final privKeyJson = await _secureStorage.read(key: 'rsa_private_key_${user.uid}');
    final pubKeyJson = await _secureStorage.read(key: 'rsa_public_key_${user.uid}');

    if (privKeyJson != null && pubKeyJson != null) {
      _privateKey = _parsePrivateKey(jsonDecode(privKeyJson));
      _publicKey = _parsePublicKey(jsonDecode(pubKeyJson));
    } else {
      // Generate new key pair
      final keyPair = await compute(_generateRSAKeyPair, 2048);
      _publicKey = keyPair.publicKey;
      _privateKey = keyPair.privateKey;
      
      await _secureStorage.write(
        key: 'rsa_private_key_${user.uid}', 
        value: jsonEncode(_privateKeyToJson(_privateKey!))
      );
      await _secureStorage.write(
        key: 'rsa_public_key_${user.uid}', 
        value: jsonEncode(_publicKeyToJson(_publicKey!))
      );
      
      // Update public key in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'publicKey': jsonEncode(_publicKeyToJson(_publicKey!))
      }, SetOptions(merge: true));
    }
  }

  // --- AES Encryption (Symmetric) ---
  
  encrypt.Key generateAESKey() {
    return encrypt.Key.fromSecureRandom(32); // 256-bit AES
  }

  String encryptMessage(String plainText, encrypt.Key aesKey) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Combine IV and CipherText
    return '${iv.base64}:${encrypted.base64}';
  }

  String decryptMessage(String encryptedPayload, encrypt.Key aesKey) {
    final parts = encryptedPayload.split(':');
    if (parts.length != 2) return encryptedPayload; // Fallback
    
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedText = encrypt.Encrypted.fromBase64(parts[1]);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(encryptedText, iv: iv);
  }

  // --- RSA Encryption (Asymmetric) ---

  String encryptAESKeyWithRSA(encrypt.Key aesKey, RSAPublicKey pubKey) {
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: pubKey));
    return encrypter.encryptBytes(aesKey.bytes).base64;
  }

  encrypt.Key? decryptAESKeyWithRSA(String encryptedAESKeyBase64) {
    if (_privateKey == null) return null;
    final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: _privateKey));
    final decryptedBytes = encrypter.decryptBytes(encrypt.Encrypted.fromBase64(encryptedAESKeyBase64));
    return encrypt.Key(Uint8List.fromList(decryptedBytes));
  }
  
  RSAPublicKey parsePublicKeyFromJson(String jsonString) {
    return _parsePublicKey(jsonDecode(jsonString));
  }
  
  Future<void> clearKeys() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _secureStorage.delete(key: 'rsa_private_key_${user.uid}');
      await _secureStorage.delete(key: 'rsa_public_key_${user.uid}');
    }
    _privateKey = null;
    _publicKey = null;
  }
}

// --- Helpers for RSA ---

AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair(int bitLength) {
  final secureRandom = FortunaRandom();
  final random = Random.secure();
  final seeds = <int>[];
  for (var i = 0; i < 32; i++) {
    seeds.add(random.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

  final keyGen = RSAKeyGenerator()
    ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom));

  final pair = keyGen.generateKeyPair();
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey, pair.privateKey as RSAPrivateKey);
}

Map<String, String> _publicKeyToJson(RSAPublicKey key) {
  return {
    'n': key.modulus!.toString(),
    'e': key.exponent!.toString(),
  };
}

Map<String, String> _privateKeyToJson(RSAPrivateKey key) {
  return {
    'n': key.modulus!.toString(),
    'd': key.privateExponent!.toString(),
    'p': key.p!.toString(),
    'q': key.q!.toString(),
  };
}

RSAPublicKey _parsePublicKey(Map<String, dynamic> json) {
  return RSAPublicKey(
    BigInt.parse(json['n']),
    BigInt.parse(json['e']),
  );
}

RSAPrivateKey _parsePrivateKey(Map<String, dynamic> json) {
  return RSAPrivateKey(
    BigInt.parse(json['n']),
    BigInt.parse(json['d']),
    BigInt.parse(json['p']),
    BigInt.parse(json['q']),
  );
}
