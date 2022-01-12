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
  // const totalMinted = useContractReader(readContracts, "WolfSheepNFT", "totalMinted");
  const balance = useContractReader(readContracts, "WolfSheepNFT", "balanceOf", [address]);

  // keep track of a variable from the contract in the local React state:
  console.log("🤗 balance:", balance);

  // 🧠 This effect will update yourCollectibles by polling when your balance changes
  useEffect(() => {
    const updateYourCollectibles = async () => {
      const collectibleUpdate = [];
      const yourBalance = balance && balance.toString && balance.toString();
      for (let tokenIndex = 0; tokenIndex < yourBalance; tokenIndex++) {
        try {
          console.log("Getting token index", tokenIndex);
          const tokenId = await readContracts.WolfSheepNFT.tokenOfOwnerByIndex(address, tokenIndex);
          console.log("tokenId", tokenId);
          const tokenTraits = await readContracts.WolfSheepNFT.getTokenTraits(tokenId);
          console.log("tokenTraits", tokenTraits);
          const stakeSheeps = await readContracts.WolfSheepStaking.barn(tokenId);
          console.log("stakeSheeps", stakeSheeps);
          const stakeWolfIndex = await readContracts.WolfSheepStaking.packIndices(tokenId);
          console.log("stakeWolfsIndex", stakeWolfIndex);

          // ToDo. Recalculate onBlock (or contract Reader)
          let rewards;
          if (!!stakeSheeps.tokenId) {
            rewards = await readContracts.WolfSheepStaking.calculateRewards(tokenId);
          }

          collectibleUpdate.push({
            id: tokenId,
            owner: address,
            isSheep: tokenTraits.isSheep,
            staked: tokenTraits.isSheep ? !!stakeSheeps.tokenId : !!stakeWolfIndex.toNumber(),
            rewards: rewards?.toString(),
          });
        } catch (e) {
          console.log(e);
        }
      }
      setYourCollectibles(collectibleUpdate);
    };
    updateYourCollectibles();
  }, [address, balance, readContracts]);

  const mintItem = async () => {
    try {
      tx(writeContracts && writeContracts.WolfSheepNFT && writeContracts.WolfSheepNFT.mintItem(), update => {
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
                    <img alt={`token ${item.id}`} src={item.isSheep ? "./img/sheep.png" : "./img/wolf.png"} />
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
                        console.log("Trasfering NFT", writeContracts);
                        tx(writeContracts.WolfSheepNFT.transferFrom(address, transferToAddresses[id], id));
                      }}
                    >
                      Transfer
                    </Button>
                    <Button
                      disabled={item.staked}
                      onClick={() => {
                        console.log("Staking", id);
                        try {
                          item.isSheep
                            ? tx(writeContracts.WolfSheepStaking.addSheepToBarn(id))
                            : tx(writeContracts.WolfSheepStaking.addWolfToPack(id));
                        } catch (e) {
                          console.log(e);
                        }
                      }}
                    >
                      Stake
                    </Button>
                    {item.staked && (
                      <>
                        <h3>
                          <strong>Stacked</strong>
                        </h3>
                        <p>Unclaimed TOKEN rewards: {item.rewards}</p>
                        <p>
                          <Button
                            disabled={!item.staked}
                            onClick={() => {
                              console.log("Claim rewards", id);
                              try {
                                tx(writeContracts.WolfSheepStaking.claimWoolFromSheep(id, false));
                              } catch (e) {
                                console.log(e);
                              }
                            }}
                          >
                            Claim rewards
                          </Button>
                        </p>
                      </>
                    )}
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
