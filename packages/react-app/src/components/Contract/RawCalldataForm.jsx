import { Button, Collapse, Input, notification, Typography } from "antd";
import React, { useState } from "react";
import { Transactor } from "../../helpers";
import { utils } from "ethers";
const { Panel } = Collapse;
const { Text, Paragraph } = Typography;

export default function RawCalldataForm({ address, provider, gasPrice, triggerRefresh }) {
  const tx = Transactor(provider, gasPrice);
  const [rawCalldataValue, setRawCalldataValue] = useState("");
  const [keccak256String, setKeccak256String] = useState("");

  const sendRawCalldataToContract = async () => {
    if (!utils.isHexString(rawCalldataValue)) {
      notification.error({
        message: "Raw calldata should be an Hex string (Starting with '0x')",
      });
      return;
    }

    const signer = provider.getSigner();
    await tx(
      signer.sendTransaction({
        to: address,
        data: rawCalldataValue,
      }),
    );

    triggerRefresh(true);
  };

  return (
    <>
      <Collapse style={{ margin: "0 auto 20px", maxWidth: "500px" }}>
        <Panel header={<strong>Utils</strong>} key="1" style={{ textAlign: "left" }}>
          <strong>Keccak-256</strong> <Text type="secondary">(Function signature => 4 Byte Hash)</Text>
          <Input
            placeholder="function signature"
            onChange={e => {
              setKeccak256String(e.target.value);
            }}
          />
          <Paragraph style={{ marginTop: "5px" }} copyable>
            {keccak256String && utils.keccak256(utils.toUtf8Bytes(keccak256String)).slice(0, 7)}
          </Paragraph>
        </Panel>
      </Collapse>
      <textarea
        style={{ display: "block", margin: "0 auto 20px" }}
        cols="50"
        rows="10"
        value={rawCalldataValue}
        onChange={e => setRawCalldataValue(e.target.value)}
      />
      <Button type="primary" onClick={sendRawCalldataToContract}>
        Send Raw tx
      </Button>
    </>
  );
}
