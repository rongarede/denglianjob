from web3 import Web3
from eth_abi import encode
# 连接到以太坊节点
base_url = 'https://base.llamarpc.com'
web3 = Web3(Web3.HTTPProvider(base_url))


def get_storage_at(contract_address, slot):
    return web3.eth.get_storage_at(contract_address, slot)


def keccak256(value):
    return Web3.keccak(value).hex()


def get_element_slot(slot, index):
    # 使用 eth_abi 库中的 encode 方法
    encoded_slot = encode(['uint256'], [slot])
    base_slot = int(Web3.keccak(encoded_slot).hex(), 16)
    return base_slot + index * 2  # 每个结构体占用 2 个插槽

def to_checksum_address(address_bytes):
    address_hex = Web3.toHex(address_bytes[-20:])
    return Web3.toChecksumAddress(address_hex)

def decode_user_and_start_time(data):
    user_bytes = data[-20:]  # 后20个字节表示address
    start_time_bytes = data[-28:-20]  # 倒数第21到第28个字节表示startTime
    user = user_bytes.hex()
    start_time = int.from_bytes(start_time_bytes, byteorder='big')
    return user, start_time

def read_locks_array(contract_address, slot_index):
    # 获取数组长度
    array_length_slot = hex(slot_index)
    array_length = int.from_bytes(get_storage_at(contract_address, array_length_slot), byteorder='big')

    elements = []
    for i in range(array_length):
        element_base_slot = get_element_slot(slot_index, i)

        user_and_start_time_slot = hex(element_base_slot)
        amount_slot = hex(element_base_slot + 1)

        # 获取 user 和 startTime
        user_and_start_time_data = get_storage_at(contract_address, user_and_start_time_slot)
        user, start_time = decode_user_and_start_time(user_and_start_time_data)
        # 获取 amount
        amount_data = get_storage_at(contract_address, amount_slot)
        amount = int.from_bytes(amount_data, byteorder='big')

        print(user,start_time,amount)



contract_address = '0x6c2CaF6a9Ac480466ec4c5eec67D73c2aAfA4aFa'
slot_index = 0  # _locks 数组的起始插槽

read_locks_array(contract_address, slot_index)

