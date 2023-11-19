import { WagmiConfig, createConfig, configureChains, mainnet } from "wagmi";
import { useAccount, useConnect, useDisconnect, useBalance } from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";
// import { jsonRpcProvider } from "wagmi/providers/jsonRpc";
import { publicProvider } from "@wagmi/core/providers/public";
import "./App.css";

// const { chains, publicClient } = configureChains(
//   [mainnet],
//   [
//     jsonRpcProvider({
//       rpc: () => ({
//         http: "https://autumn-fabled-sky.ethereum-sepolia.quiknode.pro/45ffb5979f8c56f89515b47dc2d36e21da9d135a/",
//       }),
//     }),
//   ]
// );
const { chains, publicClient } = configureChains([mainnet], [publicProvider()]);

const config = createConfig({
  autoConnect: false,
  publicClient,
  connectors: [
    new InjectedConnector({
      chains,
      options: {
        name: "Injected",
        shimDisconnect: true,
      },
    }),
  ],
});

function Profile() {
  const { address } = useAccount();
  const { connect, isConnecting } = useConnect({
    connector: new InjectedConnector(),
  });
  const { disconnect } = useDisconnect();
  const { data, isError, isLoading } = useBalance({
    address: address,
  });

  if (address) {
    return (
      <div className="App">
        <div className="content">
          <div className={`txt ${address ? "active" : ""}`}>
            <p>Active address: {address}</p>
          </div>
          <p>Balance: {data ? data.formatted : "Loading..."} ETH</p>
          <p>Chain ID: {config ? config.lastUsedChainId : ""}</p>
          <button onClick={disconnect}>Disconnect</button>
        </div>
      </div>
    );
  }

  if (isConnecting) {
    return (
      <div>
        <p>Connecting...</p>
      </div>
    );
  }

  return (
    <div className="App">
      <p className="heading">You can connect your wallet here!</p>
      <button onClick={() => connect()}>Connect Wallet</button>
    </div>
  );
}

function App() {
  return (
    <WagmiConfig config={config}>
      <Profile />
    </WagmiConfig>
  );
}

export default App;
