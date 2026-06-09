
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

void main() async {
  final x25519 = X25519();
  
  // 1. Generate fresh keypair
  final keyPair = await x25519.newKeyPair();
  final pubKey = await keyPair.extractPublicKey();
  final privBytes = await keyPair.extractPrivateKeyBytes();
  
  print('Original Pub: ${base64Encode(pubKey.bytes)}');
  
  // 2. Re-create from seed (using privBytes as seed)
  final recoveredKeyPair = await x25519.newKeyPairFromSeed(privBytes);
  final recoveredPubKey = await recoveredKeyPair.extractPublicKey();
  
  print('Recovered Pub: ${base64Encode(recoveredPubKey.bytes)}');
  
  if (base64Encode(pubKey.bytes) == base64Encode(recoveredPubKey.bytes)) {
    print('SUCCESS: Seed recovery works.');
  } else {
    print('FAILURE: Seed recovery produces different public key!');
  }
}
