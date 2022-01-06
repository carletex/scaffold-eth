import React from "react";
import { PageHeader } from "antd";
import { Link } from "react-router-dom";

// displays a page header

export default function Header() {
  return (
    <Link to="/">
      <PageHeader
        title="🐺 Wolf & Sheep 🐑"
        subTitle="Learn game dynamics with scaffold-eth"
        style={{ cursor: "pointer" }}
      />
    </Link>
  );
}
