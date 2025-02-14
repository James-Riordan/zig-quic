const std = @import("std");

pub const Error = error{
    TokenGenerationFailed,
    TokenVerificationFailed,
};

pub const Paseto = struct {
    key: [32]u8, // Symmetric key for v4.local

    pub fn init(key: [32]u8) Paseto {
        return Paseto{ .key = key };
    }

    pub fn generate_token(self: *Paseto, payload: []const u8, token_out: []u8) !void {
        if (token_out.len < payload.len + 32) return Error.TokenGenerationFailed;

        var nonce: [24]u8 = undefined;
        std.crypto.random.bytes(&nonce);

        var sealed: [payload.len + 16]u8 = undefined;
        std.crypto.aead.xchacha20_poly1305.encrypt(&sealed, payload, nonce, &self.key);

        const formatted = try std.fmt.bufPrint(token_out, "v4.local.{}{}", .{ nonce, sealed });
        std.mem.copy(u8, token_out[0..formatted.len], formatted);
    }

    pub fn verify_token(self: *Paseto, token: []const u8, payload_out: []u8) !void {
        if (!std.mem.startsWith(u8, token, "v4.local.")) return Error.TokenVerificationFailed;

        const nonce = token[9..33];
        const sealed = token[33..];

        std.crypto.aead.xchacha20_poly1305.decrypt(payload_out, sealed, nonce, &self.key) catch return Error.TokenVerificationFailed;
    }
};

// ✅ **Embedded Unit Tests**
test "PASETO token generation & verification" {
    var key: [32]u8 = undefined; // Fixed the typo here!
    std.crypto.random.bytes(&key);

    var paseto = Paseto.init(key);

    const payload = "Hello, QUIC!";
    var token_out: [128]u8 = undefined;
    var decrypted: [payload.len]u8 = undefined;

    try paseto.generate_token(payload, &token_out);
    try paseto.verify_token(token_out, &decrypted);

    try std.testing.expectEqualSlices(u8, payload, decrypted);
}
