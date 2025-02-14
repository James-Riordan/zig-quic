const std = @import("std");

pub const Error = error{
    EncryptionFailed,
    DecryptionFailed,
};

pub const ChaCha20Poly1305 = struct {
    key: [32]u8, // 256-bit key
    nonce: [12]u8, // 96-bit nonce

    pub fn init(key: [32]u8, nonce: [12]u8) ChaCha20Poly1305 {
        return ChaCha20Poly1305{
            .key = key,
            .nonce = nonce,
        };
    }

    pub fn encrypt(self: *ChaCha20Poly1305, plaintext: []const u8, ciphertext: []u8, tag: []u8) !void {
        if (ciphertext.len < plaintext.len or tag.len < 16) return Error.EncryptionFailed;

        var chacha = std.crypto.aead.chacha20_poly1305;
        var ctx = try chacha.initEnc(self.key);
        defer ctx.deinit();

        ctx.encrypt(ciphertext, plaintext, self.nonce, &tag);
    }

    pub fn decrypt(self: *ChaCha20Poly1305, ciphertext: []const u8, tag: []const u8, plaintext: []u8) !void {
        if (plaintext.len < ciphertext.len or tag.len < 16) return Error.DecryptionFailed;

        var chacha = std.crypto.aead.chacha20_poly1305;
        var ctx = try chacha.initDec(self.key);
        defer ctx.deinit();

        ctx.decrypt(plaintext, ciphertext, self.nonce, tag) catch return Error.DecryptionFailed;
    }
};

// ✅ **Embedded Unit Tests**
test "ChaCha20-Poly1305 encryption & decryption" {
    var key: [32]u8 = undefined;
    var nonce: [12]u8 = undefined;
    const plaintext = "Hello, QUIC!";
    var ciphertext: [plaintext.len]u8 = undefined;
    var decrypted: [plaintext.len]u8 = undefined;
    var tag: [16]u8 = undefined;

    std.crypto.random.bytes(&key);
    std.crypto.random.bytes(&nonce);

    var chacha = ChaCha20Poly1305.init(key, nonce);

    try chacha.encrypt(plaintext, &ciphertext, &tag);
    try chacha.decrypt(ciphertext, tag, &decrypted);

    try std.testing.expectEqualSlices(u8, plaintext, decrypted);
}
