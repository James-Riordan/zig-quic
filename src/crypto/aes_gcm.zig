const std = @import("std");

pub const Error = error{
    EncryptionFailed,
    DecryptionFailed,
};

pub const AesGcm = struct {
    key: [32]u8, // AES-256 key
    nonce: [12]u8, // Nonce for AES-GCM

    pub fn init(key: [32]u8, nonce: [12]u8) AesGcm {
        return AesGcm{
            .key = key,
            .nonce = nonce,
        };
    }

    pub fn encrypt(self: *AesGcm, plaintext: []const u8, ciphertext: []u8, tag: []u8) !void {
        if (ciphertext.len < plaintext.len or tag.len < 16) return Error.EncryptionFailed;

        var gcm = std.crypto.aead.aes_gcm;
        var ctx = try gcm.initEnc(self.key);
        defer ctx.deinit();

        ctx.encrypt(ciphertext, plaintext, self.nonce, &tag);
    }

    pub fn decrypt(self: *AesGcm, ciphertext: []const u8, tag: []const u8, plaintext: []u8) !void {
        if (plaintext.len < ciphertext.len or tag.len < 16) return Error.DecryptionFailed;

        var gcm = std.crypto.aead.aes_gcm;
        var ctx = try gcm.initDec(self.key);
        defer ctx.deinit();

        ctx.decrypt(plaintext, ciphertext, self.nonce, tag) catch return Error.DecryptionFailed;
    }
};

// ✅ **Embedded Unit Tests**
test "AES-GCM encryption & decryption" {
    var key: [32]u8 = undefined;
    var nonce: [12]u8 = undefined;
    const plaintext = "Hello, QUIC!";
    var ciphertext: [plaintext.len]u8 = undefined;
    var decrypted: [plaintext.len]u8 = undefined;
    var tag: [16]u8 = undefined;

    std.crypto.random.bytes(&key);
    std.crypto.random.bytes(&nonce);

    var aes = AesGcm.init(key, nonce);

    try aes.encrypt(plaintext, &ciphertext, &tag);
    try aes.decrypt(ciphertext, tag, &decrypted);

    try std.testing.expectEqualSlices(u8, plaintext, decrypted);
}
