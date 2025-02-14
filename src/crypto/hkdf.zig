const std = @import("std");

pub const Error = error{
    KeyDerivationFailed,
};

pub const HKDF = struct {
    pub fn extract(salt: []const u8, ikm: []const u8, out_key: []u8) !void {
        if (out_key.len < 32) return Error.KeyDerivationFailed;
        var hmac = std.crypto.auth.hmac.sha256;
        var prk = [32]u8{0} ** 32;
        hmac.create(&prk, salt, ikm);
        @memcpy(out_key, prk[0..32]);
    }

    pub fn expand(prk: []const u8, info: []const u8, out_key: []u8) !void {
        if (out_key.len < 32) return Error.KeyDerivationFailed;
        var hmac = std.crypto.auth.hmac.sha256;
        hmac.create(out_key, prk, info);
    }
};

// ✅ **Embedded Unit Tests**
test "HKDF key derivation" {
    var salt: [16]u8 = undefined;
    var ikm: [32]u8 = undefined;
    var prk: [32]u8 = undefined;
    var expanded_key: [32]u8 = undefined;

    std.crypto.random.bytes(&salt);
    std.crypto.random.bytes(&ikm);

    try HKDF.extract(&salt, &ikm, &prk);
    try HKDF.expand(&prk, "quic handshake", &expanded_key);

    try std.testing.expect(prk[0] != 0);
    try std.testing.expect(expanded_key[0] != 0);
}
