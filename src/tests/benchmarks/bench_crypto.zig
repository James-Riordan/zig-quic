const std = @import("std");
const time = std.time;
const Tls = @import("../crypto/tls.zig");
const AesGcm = @import("../crypto/aes_gcm.zig");
const ChaCha20 = @import("../crypto/chacha20.zig");
const HKDF = @import("../crypto/hkdf.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Benchmarking QUIC cryptographic performance...\n", .{});

    var key: [32]u8 = undefined;
    var nonce: [12]u8 = undefined;
    var plaintext: [64]u8 = undefined;
    var ciphertext: [64]u8 = undefined;
    var tag: [16]u8 = undefined;
    var salt: [16]u8 = undefined;
    var prk: [32]u8 = undefined;
    var expanded_key: [32]u8 = undefined;

    std.crypto.random.bytes(&key);
    std.crypto.random.bytes(&nonce);
    std.crypto.random.bytes(&plaintext);
    std.crypto.random.bytes(&salt);

    // Benchmark TLS handshake
    var tls = try Tls.QuicTLS.init(allocator);
    var client_hello: [64]u8 = undefined;
    std.crypto.random.bytes(&client_hello);

    var start_time = time.Instant.now();
    for (0..100) |_| {
        tls.handshake(&client_hello) catch continue;
    }
    var end_time = time.Instant.now();
    std.debug.print("  TLS Handshake Time: {} ns per iteration\n", .{(end_time.since(start_time) / 100)});

    // Benchmark AES-GCM encryption
    var aes = AesGcm.AesGcm.init(key, nonce);
    start_time = time.Instant.now();
    for (0..1000) |_| {
        aes.encrypt(plaintext, &ciphertext, &tag) catch continue;
    }
    end_time = time.Instant.now();
    std.debug.print("  AES-GCM Encryption Time: {} ns per iteration\n", .{(end_time.since(start_time) / 1000)});

    // Benchmark ChaCha20 encryption
    var chacha = ChaCha20.ChaCha20Poly1305.init(key, nonce);
    start_time = time.Instant.now();
    for (0..1000) |_| {
        chacha.encrypt(plaintext, &ciphertext, &tag) catch continue;
    }
    end_time = time.Instant.now();
    std.debug.print("  ChaCha20 Encryption Time: {} ns per iteration\n", .{(end_time.since(start_time) / 1000)});

    // Benchmark HKDF key derivation
    start_time = time.Instant.now();
    for (0..1000) |_| {
        HKDF.HKDF.extract(&salt, &key, &prk) catch continue;
        HKDF.HKDF.expand(&prk, "quic handshake", &expanded_key) catch continue;
    }
    end_time = time.Instant.now();
    std.debug.print("  HKDF Key Derivation Time: {} ns per iteration\n", .{(end_time.since(start_time) / 1000)});
}
