!/bin/bash

sudo apt update
sudo apt install -y mtr traceroute iputils-ping dnsutils


echo "🔍 Running BSC Network Diagnostics..."
echo "---------------------------------------"

echo ""
echo "🧠 What to Look For"
echo "==================="
echo ""
echo "Metric	Ideal Value"
echo "Ping	< 30ms to BSC seed nodes"
echo "Packet loss	0% (anything over 1% = issue)"
echo "Traceroute	< 10 hops = direct path"
echo "MTR Avg/Last	Under 50ms"
echo ""
echo "If any node has high ping or packet loss, it's either:"
echo ""
echo "Bad upstream route (Leaseweb can adjust BGP if you ask)"
echo "Congestion (time of day or shared port speed)"
echo ""
echo "---------------------------------------"



TARGETS=(
  "seed1.bscnodes.com"
  "rpc.ankr.com"  # good public endpoint
  "bsc-dataseed1.binance.org"
  "bsc-dataseed3.defibit.io"
  "bsc-dataseed1.ninicoin.io"
)

for target in "${TARGETS[@]}"; do
  echo ""
  echo "🔹 Testing: $target"
  echo "----------------------"

  echo "📡 PING:"
  ping -c 5 "$target"

  echo ""
  echo "🚀 Traceroute:"
  traceroute -n "$target"

  echo ""
  echo "📊 MTR (10s):"
  mtr -rwbzc100 "$target" | head -n 20
done

echo ""
echo "✅ Network test complete!"

