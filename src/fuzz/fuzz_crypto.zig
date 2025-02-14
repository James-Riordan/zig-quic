const std = @import("std");
const Tls = @import("../crypto/tls.zig");
const AesGcm = @import("../crypto/aes_gcm.zig");
const ChaCha20 = @import("../crypto/chacha20.zig");
const HKDF = @import("../crypto/hkdf.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    std.debug.print("Starting QUIC cryptographic fuzz testing...\n", .{});

    // Fuzz TLS handshake
    var tls = try Tls.QuicTLS.init(allocator);
    var random_hello: [64]u8 = undefined;
    std.crypto.random.bytes(&random_hello);

    std.debug.print("Fuzzing TLS handshake...\n", .{});
    tls.handshake(&random_hello) catch |err| {
        std.debug.print("Handled malformed TLS handshake: {}\n", .{err});
    };

    // Fuzz AES-GCM encryption
    var key: [32]u8 = undefined;
    var nonce: [12]u8 = undefined;
    var plaintext: [64]u8 = undefined;
    var ciphertext: [64]u8 = undefined;
    var tag: [16]u8 = undefined;

    std.crypto.random.bytes(&key);
    std.crypto.random.bytes(&nonce);
    std.crypto.random.bytes(&plaintext);

    var aes = AesGcm.AesGcm.init(key, nonce);
    std.debug.print("Fuzzing AES-GCM encryption...\n", .{});
    aes.encrypt(plaintext, &ciphertext, &tag) catch |err| {
        std.debug.print("Handled encryption failure: {}\n", .{err});
    };

    // Fuzz ChaCha20 encryption
    var chacha = ChaCha20.ChaCha20Poly1305.init(key, nonce);
    std.debug.print("Fuzzing ChaCha20 encryption...\n", .{});
    chacha.encrypt(plaintext, &ciphertext, &tag) catch |err| {
        std.debug.print("Handled encryption failure: {}\n", .{err});
    };

    // Fuzz HKDF key derivation
    var prk: [32]u8 = undefined;
    var expanded_key: [32]u8 = undefined;
    var salt: [16]u8 = undefined;

    std.crypto.random.bytes(&salt);
    std.debug.print("Fuzzing HKDF key derivation...\n", .{});
    HKDF.HKDF.extract(&salt, &key, &prk) catch |err| {
        std.debug.print("Handled HKDF extraction failure: {}\n", .{err});
    };

    // Fix: Actually use `expanded_key` by calling HKDF.expand()
    HKDF.HKDF.expand(&prk, "quic handshake", &expanded_key) catch |err| {
        std.debug.print("Handled HKDF expansion failure: {}\n", .{err});
    };

    std.debug.print("QUIC cryptographic fuzz test completed.\n", .{});
}
