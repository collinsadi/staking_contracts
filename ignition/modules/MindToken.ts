import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const MindTokenModule = buildModule("MindTokenModule", (m) => {
  const MindToken = m.contract("MindToken");

  return { MindToken };
});

export default MindTokenModule;
