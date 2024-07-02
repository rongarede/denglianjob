import hashlib
import time

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

def main():
    nickname = "b1wl7cH"  # Replace with your nickname

    # Find hash with 4 leading zeros
    target_prefix_4 = "0000"
    nonce_4, hash_result_4, elapsed_time_4 = mine_pow(nickname, target_prefix_4)
    print(f"4 leading zeros:\nNonce: {nonce_4}\nHash: {hash_result_4}\nTime: {elapsed_time_4} seconds\n")

    # Find hash with 5 leading zeros
    target_prefix_5 = "00000"
    nonce_5, hash_result_5, elapsed_time_5 = mine_pow(nickname, target_prefix_5)
    print(f"5 leading zeros:\nNonce: {nonce_5}\nHash: {hash_result_5}\nTime: {elapsed_time_5} seconds\n")

if __name__ == "__main__":
    main()
