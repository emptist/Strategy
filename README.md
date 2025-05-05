# **Strategy Protocol and Utilities Library**

## **Introduction**
This repository provides a flexible and powerful framework for financial strategy development and testing, designed specifically for use with Swift. It includes a standard `Strategy` protocol and a suite of utility functions to assist in strategy analysis and decision-making based on technical indicators.

## **Key Features**
- **Strategy Protocol**: A protocol to standardize the development of trading strategies.
- **Decision Engine & Position Management**: Integrated modules for evaluating trade entry conditions and managing stop-losses dynamically.
- **Utility Functions**: A comprehensive collection of functions to calculate various technical indicators such as SMA (Simple Moving Average), Bollinger Bands, ROC (Rate of Change), and more.
- **Persistent Trade Storage**: Ensures trades can be restored after a crash or app restart.
- **Dynamic Strategy Loading**: Strategies can be compiled as `.dylib` files and loaded dynamically into the **TradeUI** application.
- **Integration with TradeUI**: The strategies built using this repository can be used within the [TradeUI application](https://github.com/TradeWithIt/TradeUI), allowing for real-time execution and visualization of trading strategies.

---

## **📌 Generating a Dynamic Library (`.dylib`) for TradeUI**
To allow your strategies to be dynamically loaded by **TradeUI**, you need to set up your **Swift Package** to produce a `.dylib`.

### **📌 Step 1: Set Up Your Strategy Package (`Package.swift`)**
Ensure that your Swift package is correctly set up to:
- **Depend on the `Strategy` package.**
- **Produce a `.dylib` instead of a static framework.**

#### **Example `Package.swift` for a Custom Strategy Package**
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyStrategyPackage",
    products: [
        // ✅ This produces a `.dylib` that can be dynamically loaded by TradeUI.
        .library(name: "MyStrategyPackage", type: .dynamic, targets: ["MyStrategyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/TradeWithIt/Strategy.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MyStrategyPackage",
            dependencies: [
                .product(name: "TradingStrategy", package: "Strategy")
            ]
        ),
        .testTarget(
            name: "MyStrategyPackageTests",
            dependencies: ["MyStrategyPackage"]),
    ]
)
```

---

## **📌 Step 2: Implementing Strategy Registration**
In your package, **you need to expose your strategies using C-compatible functions**. This allows TradeUI to discover and instantiate them dynamically.

#### **Example Implementation**
```swift
import Foundation
import TradingStrategy

// ✅ Expose available strategies as a C-compatible string
@_cdecl("getAvailableStrategies")
public func getAvailableStrategies() -> UnsafeMutablePointer<CChar> {
    let strategyList = ["ORB", "Surprise Bar"].joined(separator: ",")
    print("📢 Available Strategies in dylib: \(strategyList)")
    return strdup(strategyList)! // ✅ Ensure valid C string pointer
}

// ✅ Dynamically create a strategy by name
@_cdecl("createStrategy")
public func createStrategy(strategyName: UnsafePointer<CChar>) -> UnsafeRawPointer? {
    let name = String(cString: strategyName).trimmingCharacters(in: .whitespacesAndNewlines)
    print("🔍 Requested strategy: '\(name)'")

    let factory: () -> Strategy = {
        switch name {
        case "ORB":
            print("✅ Returning ORBStrategy instance")
            return ORBStrategy(candles: [])
        case "Surprise Bar":
            print("✅ Returning SurpriseBarStrategy instance")
            return SurpriseBarStrategy(candles: [])
        default:
            print("❌ Strategy not found: '\(name)'")
            return ORBStrategy(candles: []) // Default or error handling
        }
    }

    let boxedFactory = Box(factory)
    return UnsafeRawPointer(Unmanaged.passRetained(boxedFactory).toOpaque()) // ✅ Ensure safe interop
}

// ✅ Helper class to store closures in an `Unmanaged` object
class Box<T> {
    let value: T
    init(_ value: T) { self.value = value }
}
```

---

## **📌 Step 3: Building and Using Your Strategy in TradeUI**
### **Build the `.dylib`**
Run the following command inside your **strategy package directory** to generate the `.dylib` file:
```sh
swift build -c release
```
- This will generate the `.dylib` file in the `.build/release` directory.

### **Copy the `.dylib` to TradeUI**
Once the `.dylib` is built, move it into the TradeUI strategies directory:
```sh
cp .build/release/libMyStrategyPackage.dylib ~/Downloads/Strategies/
```

### **Ensure TradeUI Can Find the `.dylib`**
TradeUI looks for `.dylib` files in `~/Downloads/Strategies/` by default.
1. **Make sure your `.dylib` is placed inside that folder.**
2. **Restart TradeUI** to dynamically load the new strategies.

---

## **📌 Step 4: Loading Strategies in TradeUI**
TradeUI automatically discovers and loads strategies from `.dylib` files.

### **How Strategies Are Loaded**
TradeUI will:
1. **Find all `.dylib` files** in the `Strategies` folder.
2. **Call `getAvailableStrategies()`** to list strategies inside each `.dylib`.
3. **Call `createStrategy(strategyName:)`** to instantiate a strategy dynamically.
4. **Register the strategy for use in the application.**

### **Expected Log Output**
If everything works correctly, TradeUI should print:
```
🔍 Loading strategies from /Downloads/Strategies/libMyStrategyPackage.dylib
📢 Available Strategies in dylib: ORB, Surprise Bar
✅ Successfully registered strategy: ORB
✅ Successfully registered strategy: Surprise Bar
```
🚀 **Now your custom strategies are loaded into TradeUI!**  

---

## **📌 Example Strategy Implementation**
Here’s an example of how to implement a simple strategy inside your package:

```swift
import Foundation
import TradingStrategy

public struct ORBStrategy: Strategy {
    public var charts: [[Klines]] = []
    public var resolution: [Scale] = []
    public var distribution: [[Phase]] = []
    public var indicators: [[String: [Double]]] = []
    public var levels: [Level] = []
    public var patternIdentified: Bool = false
    public var patternInformation: [String: Bool] = [:]

    public init(candles: [Klines]) {
        self.charts = [candles]
    }

    public func unitCount(entryBar: Klines, equity: Double, feePerUnit cost: Double) -> Int {
        return 10
    }

    public func shouldEnterWitUnitCount(entryBar: Klines) -> Double? {
        if shouldEnter { 
            return calculateUnitCount()
        }
        // if not enter 
        return nil
    }

    public func shouldExit(entryBar: Klines) -> Bool {
        return false
    }
}
```

---

## **🚀 Final Summary**
### **What You Need to Do**
1️⃣ **Set up your package to generate a `.dylib`.**  
2️⃣ **Implement `getAvailableStrategies()` and `createStrategy(strategyName:)`.**  
3️⃣ **Compile the package using `swift build -c release`.**  
4️⃣ **Move the `.dylib` into the TradeUI strategies folder.**  
5️⃣ **Restart TradeUI to dynamically load your strategies.**  

---

## **📌 Troubleshooting**
- **Missing strategies in TradeUI?**  
  → Check that the `.dylib` is inside `~/Downloads/Strategies/`  
- **Type mismatch errors?**  
  → Ensure your strategy struct **conforms to `Strategy`**.  
- **TradeUI crashes when loading strategies?**  
  → Use `print()` debugging inside `createStrategy()` to verify correct loading.  

🚀 **Now, your package is correctly configured for TradeUI! Happy trading!** 🚀🔥

---

## 🐳 Build Linux-Compatible `.so` with Docker

To run your strategy with the [TradeUI CLI](https://github.com/TradeWithIt/TradeUI) inside Docker or Linux, you need a **Linux `.so` file**.
This section shows how to build it from any platform using Docker.

### 📁 Step 1: Create `Dockerfile.linux.build`

In the root of this repository, add this file:

```dockerfile
# Dockerfile.linux.build

FROM swift:5.9-jammy AS builder
WORKDIR /strategy

# Copy source
COPY . .

# Build the dynamic library product
RUN swift build -c release --product Strategy

# Rename it for export
RUN cp .build/release/libStrategy.so /strategy/Strategy.so

# Export the .so in a minimal image
FROM ubuntu:22.04
COPY --from=builder /strategy/Strategy.so /out/Strategy.so
```

---

### 🛠 Step 2: Build & Extract `.so` File

From the root of the repo, run:

```bash
docker build -f Dockerfile.linux.build -t strategy-builder .
docker run --rm -v $(pwd)/output:/out strategy-builder
```

You will now have:

```
output/Strategy.so
```

This `.so` is ready for use with the `trade` CLI:

```bash
trade ./output/Strategy.so FUT ESM5 60 CME USD
```

---

### 🧠 Note

* Make sure your `Package.swift` includes `Strategy` as a **dynamic library** product.
* You can rename or copy the `.so` file for different strategies.

---
