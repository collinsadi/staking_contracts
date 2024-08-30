import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakeMindTokenModule = buildModule("StakeMindTokenModule", (m) => {
  const StakeMindToken = m.contract("StakeMindToken");

  return { StakeMindToken };
});

export default StakeMindTokenModule;
