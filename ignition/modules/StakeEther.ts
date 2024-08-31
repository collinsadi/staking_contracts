import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakeEther = buildModule("StakeEtherModule", (m) => {
  const StakeEther = m.contract("StakeEtherToken");

  return { StakeEther };
});

export default StakeEther;
