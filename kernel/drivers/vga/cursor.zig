const x86 = @import("../../arch/x86-64/io.zig");

pub const VgaCursor = struct {
    // VGA cursor control registers
    const CURSOR_INDEX_PORT: u16 = 0x3D4;
    const CURSOR_DATA_PORT: u16 = 0x3D5;

    // VGA cursor control register indices
    const CURSOR_START_REGISTER: u8 = 0x0A;
    const CURSOR_END_REGISTER: u8 = 0x0B;
    const CURSOR_LOCATION_HIGH_REGISTER: u8 = 0x0E;
    const CURSOR_LOCATION_LOW_REGISTER: u8 = 0x0F;

    pub fn disable() void {
        // To disable the cursor, we set bit 5 of the cursor start register
        x86.outb(CURSOR_INDEX_PORT, CURSOR_START_REGISTER);
        x86.outb(CURSOR_DATA_PORT, 0x20); // Set bit 5 to disable cursor
    }

    pub fn enable() void {
        // Vertical block cursor, from scanlines 0-15 in text mode
        x86.outb(CURSOR_INDEX_PORT, CURSOR_START_REGISTER);
        x86.outb(CURSOR_DATA_PORT, 0); // Start scanline at top (0)

        x86.outb(CURSOR_INDEX_PORT, CURSOR_END_REGISTER);
        x86.outb(CURSOR_DATA_PORT, 15); // End scanline at bottom (15)
    }

    pub fn setPosition(x: usize, y: usize, width: usize) void {
        const position: u16 = @intCast(y * width + x);

        // Set high byte of cursor position
        x86.outb(CURSOR_INDEX_PORT, CURSOR_LOCATION_HIGH_REGISTER);
        x86.outb(CURSOR_DATA_PORT, @intCast((position >> 8) & 0xFF));

        // Set low byte of cursor position
        x86.outb(CURSOR_INDEX_PORT, CURSOR_LOCATION_LOW_REGISTER);
        x86.outb(CURSOR_DATA_PORT, @intCast(position & 0xFF));
    }
};
