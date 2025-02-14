# zig-quic 🚀  
A modern, high-performance **QUIC** implementation in **Zig**, designed for low-latency, secure, and scalable networking.

## 📌 Features
- ✅ **QUIC Transport Layer** – Efficient packetized communication over UDP.
- ✅ **Multiplexed Streams** – Multiple reliable streams per connection.
- ✅ **HTTP/3 Support** – Built-in framing and stream management.
- ✅ **Congestion Control** – Implements **NewReno** & **BBR**.
- ✅ **Memory Efficient** – Uses Zig’s allocator model to minimize overhead.
- ✅ **Custom ZSON Configuration** – Supports declarative QUIC tuning.

## 🚀 Getting Started
### **Prerequisites**
- Install **Zig** (0.14+)
- Clone the repo:
  ```sh
  git clone https://github.com/yourname/zig-quic.git
  cd zig-quic

  zig build test --verbose --summary all
  zig build integratetest --verbose --summary all
  ```


## Project Structure
 
```
zig-quic/
├── src/
│   ├── quic.zig              # Main QUIC protocol implementation
│   ├── http3.zig             # HTTP/3 framing & stream management
│   ├── transport/
│   │   ├── connection.zig    # QUIC connection handling
│   │   ├── stream.zig        # QUIC bidirectional/unidirectional streams
│   │   ├── packet.zig        # QUIC packet encoding & parsing
│   │   ├── congestion.zig    # Congestion control (NewReno, BBR)
│   ├── root.zig              # Entry point for the library
├── tests/                    # Unit tests for various components
└── README.md

```

## ⚡ Roadmap

- Implement QUIC handshake & TLS 1.3 integration.
- Optimize packet encryption/decryption.
- Support 0-RTT resumption.
- Performance benchmarking against quiche & lsquic.

## 🤝 Contributing

## 🛠 License

This project is licensed under the MIT License.
