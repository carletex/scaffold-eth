import React, { useEffect, useState } from "react";
import { Button, Card, List } from "antd";
import { useContractReader } from "eth-hooks";
import { Address, AddressInput } from "../components";

// ToDo. IPFS upload / bg color trait?

/**
 * web3 props can be passed from '../App.jsx' into your local view component
 * for use
 * @param {*} yourLocalBalance balance on current network
 * @param {*} readContracts contracts from current chain already pre-loaded
 *   using ethers contract module. More here
 *   https://docs.ethers.io/v5/api/contract/contract/
 * @param {*} writeContracts contracts from current chain already pre-loaded
 *   using ethers contract module. More here
 *   https://docs.ethers.io/v5/api/contract/contract/
 * @param {*} address the address of the connected wallet
 * @param {*} tx The transactor
 * @param {*} mainnetProvider The mainnetProvider
 * @param {*} blockExplorer The blockExplorer
 * @returns react component
 */
function Home({ yourLocalBalance, readContracts, writeContracts, address, tx, mainnetProvider, blockExplorer }) {
  const [yourCollectibles, setYourCollectibles] = useState();
  const [transferToAddresses, setTransferToAddresses] = useState({});

  // keep track of a variable from the contract in the local React state:
  const totalMinted = useContractReader(readContracts, "WolfSheepNFT", "totalMinted");
  const balance = useContractReader(readContracts, "WolfSheepNFT", "balanceOf", [address]);

  // keep track of a variable from the contract in the local React state:
  console.log("🤗 balance:", balance);

  // 🧠 This effect will update yourCollectibles by polling when your balance changes
  const yourBalance = balance && balance.toString && balance.toString();
  useEffect(() => {
    const updateYourCollectibles = async () => {
      const collectibleUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
        try {
          console.log("Getting token index", tokenIndex);
          const tokenId = await readContracts.WolfSheepNFT.tokenOfOwnerByIndex(address, tokenIndex);
          console.log("tokenId", tokenId);
          const tokenTraits = await readContracts.WolfSheepNFT.getTokenTraits(tokenId);
          console.log("tokenTraits", tokenTraits);

          collectibleUpdate.push({
            id: tokenId,
            owner: address,
            isSheep: tokenTraits.isSheep,
          });
        } catch (e) {
          console.log(e);
        }
      }
      setYourCollectibles(collectibleUpdate);
    };
    updateYourCollectibles();
  }, [address, yourBalance]);

  const mintItem = async () => {
    try {
      tx(writeContracts && writeContracts.WolfSheepNFT && writeContracts.WolfSheepNFT.mintItem(address), update => {
        console.log("📡 Transaction Update:", update);
        if (update && (update.status === "confirmed" || update.status === 1)) {
          console.log(" 🍾 Transaction " + update.hash + " finished!");
          console.log(
            " ⛽️ " +
              update.gasUsed +
              "/" +
              (update.gasLimit || update.gas) +
              " @ " +
              parseFloat(update.gasPrice) / 1000000000 +
              " gwei",
          );
        }
      });
    } catch (e) {
      console.log(e);
    }
  };

  return (
    <>
      <div style={{ width: 640, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
        <Button shape="round" size="large" onClick={mintItem}>
          MINT NFT
        </Button>
      </div>
      <div style={{ width: 1200, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
        <List
          bordered
          grid={{ gutter: 4, column: 4 }}
          dataSource={yourCollectibles}
          renderItem={item => {
            const id = item.id.toNumber();
            return (
              <List.Item key={id + "_" + item.uri + "_" + item.owner}>
                <Card>
                  <div>
                    <img src={item.isSheep ? "./img/sheep.png" : "./img/wolf.png"} />
                  </div>
                  <div>
                    owner:{" "}
                    <Address
                      address={item.owner}
                      ensProvider={mainnetProvider}
                      blockExplorer={blockExplorer}
                      fontSize={16}
                    />
                    <AddressInput
                      ensProvider={mainnetProvider}
                      placeholder="transfer to address"
                      value={transferToAddresses[id]}
                      onChange={newValue => {
                        const update = {};
                        update[id] = newValue;
                        setTransferToAddresses({ ...transferToAddresses, ...update });
                      }}
                    />
                    <Button
                      onClick={() => {
                        console.log("writeContracts", writeContracts);
                        tx(writeContracts.WolfSheepNFT.transferFrom(address, transferToAddresses[id], id));
                      }}
                    >
                      Transfer
                    </Button>
                  </div>
                </Card>
              </List.Item>
            );
          }}
        />
      </div>
    </>
  );
}

export default Home;
