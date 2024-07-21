import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  BuyNFT,
  EIP712DomainChanged,
  List
} from "../generated/NFTMarket/NFTMarket"

export function createBuyNFTEvent(
  buyer: Address,
  nftAddr: Address,
  tokenId: BigInt,
  price: BigInt
): BuyNFT {
  let buyNftEvent = changetype<BuyNFT>(newMockEvent())

  buyNftEvent.parameters = new Array()

  buyNftEvent.parameters.push(
    new ethereum.EventParam("buyer", ethereum.Value.fromAddress(buyer))
  )
  buyNftEvent.parameters.push(
    new ethereum.EventParam("nftAddr", ethereum.Value.fromAddress(nftAddr))
  )
  buyNftEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  buyNftEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return buyNftEvent
}

export function createEIP712DomainChangedEvent(): EIP712DomainChanged {
  let eip712DomainChangedEvent = changetype<EIP712DomainChanged>(newMockEvent())

  eip712DomainChangedEvent.parameters = new Array()

  return eip712DomainChangedEvent
}

export function createListEvent(
  seller: Address,
  nftAddr: Address,
  tokenId: BigInt,
  price: BigInt
): List {
  let listEvent = changetype<List>(newMockEvent())

  listEvent.parameters = new Array()

  listEvent.parameters.push(
    new ethereum.EventParam("seller", ethereum.Value.fromAddress(seller))
  )
  listEvent.parameters.push(
    new ethereum.EventParam("nftAddr", ethereum.Value.fromAddress(nftAddr))
  )
  listEvent.parameters.push(
    new ethereum.EventParam(
      "tokenId",
      ethereum.Value.fromUnsignedBigInt(tokenId)
    )
  )
  listEvent.parameters.push(
    new ethereum.EventParam("price", ethereum.Value.fromUnsignedBigInt(price))
  )

  return listEvent
}
