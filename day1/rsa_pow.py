import hashlib
import time
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization

def generate_keys():
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048
    )
    public_key = private_key.public_key()
    return private_key, public_key

def mine_pow(nickname, target_prefix):
    nonce = 0
    start_time = time.time()
    while True:
        text = f"{nickname}{nonce}"
        hash_result = hashlib.sha256(text.encode()).hexdigest()
        if hash_result.startswith(target_prefix):
            end_time = time.time()
            elapsed_time = end_time - start_time
            return nonce, hash_result, elapsed_time
        nonce += 1

def sign_message(private_key, message):
    signature = private_key.sign(
        message.encode(),
        padding.PSS(
            mgf=padding.MGF1(hashes.SHA256()),
            salt_length=padding.PSS.MAX_LENGTH
        ),
        hashes.SHA256()
    )
    return signature

def verify_signature(public_key, message, signature):
    try:
        public_key.verify(
            signature,
            message.encode(),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()),
                salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256()
        )
        return True
    except:
        return False

def main():
    nickname = "b1wl7cH"  # Replace with your nickname

    # Generate RSA keys
    private_key, public_key = generate_keys()

    # Find hash with 4 leading zeros
    target_prefix_4 = "0000"
    nonce_4, hash_result_4, elapsed_time_4 = mine_pow(nickname, target_prefix_4)
    message_4 = f"{nickname}{nonce_4}"
    print(f"4 leading zeros:\nNonce: {nonce_4}\nHash: {hash_result_4}\nTime: {elapsed_time_4} seconds\n")

    # Sign the message with the private key
    signature_4 = sign_message(private_key, message_4)
    print(f"Signature: {signature_4.hex()}\n")

    # Verify the signature with the public key
    is_valid_4 = verify_signature(public_key, message_4, signature_4)
    print(f"Signature valid: {is_valid_4}\n")

if __name__ == "__main__":
    main()
