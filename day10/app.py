from flask import Flask, request, jsonify
from eth_account import Account, messages
from eth_utils import to_bytes
from web3 import Web3

app = Flask(__name__)

# 管理员私钥（应安全保存，不要在生产环境中明文存储）
admin_private_key = 'YOUR_ADMIN_PRIVATE_KEY'

# 白名单（简单存储在内存中，可以扩展为数据库）
whitelist = ["0xWhitelistAddress1", "0xWhitelistAddress2"]  # 示例地址

@app.route('/verify_whitelist', methods=['POST'])
def add_to_whitelist():
    data = request.json
    address = data.get('address')
    if not address:
        return jsonify({"error": "Address is required"}), 400

    if address in whitelist:
        return jsonify({"error": "Address already in whitelist"}), 400

    whitelist.append(address)
    return jsonify({"message": "Address added to whitelist"}), 200

@app.route('/generate_signature', methods=['POST'])
def generate_signature():
    data = request.json
    address = data.get('address')
    if not address:
        return jsonify({"error": "Address is required"}), 400

    if address not in whitelist:
        return jsonify({"error": "Address not in whitelist"}), 403

    # EIP-712 结构体定义
    domain = {
        'name': 'WhitelistNFT',
        'version': '1',
        'chainId': 1,
        'verifyingContract': '0xYourContractAddress'
    }

    # 定义要签名的数据结构
    message = {
        'user': address
    }

    domain_separator = messages.make_domain(domain)
    message_types = {
        'Permit': [
            {'name': 'user', 'type': 'address'}
        ]
    }

    # 创建EIP-712类型数据
    data = messages.encode_structured_data(
        domain_separator, message_types, message)

    # 对数据进行签名
    signed_message = Account.sign_message(data, admin_private_key)

    return jsonify({
        "address": address,
        "signature": signed_message.signature.hex()
    }), 200

if __name__ == '__main__':
    app.run(debug=True)
