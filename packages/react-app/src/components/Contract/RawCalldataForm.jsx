import { Button, Collapse, Input, notification, Typography } from "antd";
import React, { useState } from "react";
import { Transactor } from "../../helpers";
import { utils } from "ethers";
const { Panel } = Collapse;
const { Text, Paragraph } = Typography;

const isNumeric = input => {
  return !isNaN(input) && !isNaN(parseFloat(input));
};

const stringToHex = input => {
  if (isNumeric(input)) {
    return utils.hexStripZeros(utils.hexlify(Number(input))).slice(2);
  }

  return utils.hexStripZeros(utils.hexlify(utils.toUtf8Bytes(input))).slice(2);
};

export default function RawCalldataForm({ address, provider, gasPrice, triggerRefresh }) {
  const tx = Transactor(provider, gasPrice);
  const [rawCalldataValue, setRawCalldataValue] = useState("");
  const [keccak256String, setKeccak256String] = useState("");
  const [paddingString, setPaddingString] = useState("");

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
          <div style={{ marginBottom: "25px" }}>
            <strong>Keccak-256</strong> <Text type="secondary">(Function signature => 4 Bytes Hash)</Text>
            <Input
              placeholder="function signature"
              onChange={e => {
                setKeccak256String(e.target.value);
              }}
            />
            <Paragraph style={{ marginTop: "5px" }} copyable>
              {keccak256String && utils.keccak256(utils.toUtf8Bytes(keccak256String)).slice(0, 10)}
            </Paragraph>
          </div>

          <div style={{ marginBottom: "25px" }}>
            <strong>Hex & Padding</strong> <Text type="secondary">(Convert input to hex and pad it to 32 Bytes)</Text>
            <Input
              placeholder="Value to pad"
              onChange={e => {
                setPaddingString(e.target.value);
              }}
            />
            <Paragraph style={{ marginTop: "5px" }} copyable>
              {paddingString && stringToHex(paddingString).padStart(64, "0")}
            </Paragraph>
            <Paragraph style={{ marginTop: "5px" }} copyable>
              {paddingString && stringToHex(paddingString).padEnd(64, "0")}
            </Paragraph>
          </div>
        </Panel>
      </Collapse>
      <textarea
        style={{ display: "block", margin: "0 auto 20px", fontFamily: "monospace" }}
        cols="60"
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
