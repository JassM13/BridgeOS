const vga = @import("../drivers/vga/color.zig");
const Color = vga.Color;
const vga_buffer = @import("../drivers/vga/buffer.zig");
const VGABuffer = vga_buffer.VGABuffer;
const Cursor = @import("cursor.zig").Cursor;
const Keyboard = @import("../drivers/keyboard/keyboard.zig").Keyboard;
const VgaCursor = @import("../drivers/vga/cursor.zig").VgaCursor;

var color = vga.vgaEntryColor(Color.LightGrey, Color.Black);
var cursor = Cursor.init(VGABuffer.WIDTH, VGABuffer.HEIGHT);
const buffer: *VGABuffer = VGABuffer.getInstance();

const TAB_SIZE = 4;

// Function to update hardware cursor position
fn updateHardwareCursor() void {
    VgaCursor.setPosition(cursor.column, cursor.row, VGABuffer.WIDTH);
}

pub fn initialize() void {
    buffer.flush(color);
    Keyboard.initialize();
    VgaCursor.enable(); // Enable the hardware cursor
    updateHardwareCursor(); // Initialize hardware cursor position
}

fn putChar(c: u8, new_color: u8) void {
    switch (c) {
        '\n' => {
            cursor.newLine();
            if (cursor.checkScroll()) {
                buffer.scroll(color);
                cursor.row = VGABuffer.HEIGHT - 1;
            }
            updateHardwareCursor();
        },
        '\t' => {
            const spaces = TAB_SIZE - (cursor.column % TAB_SIZE);
            var i: usize = 0;
            while (i < spaces) : (i += 1) {
                if (cursor.column >= VGABuffer.WIDTH) {
                    cursor.newLine();
                    if (cursor.checkScroll()) {
                        buffer.scroll(color);
                        cursor.row = VGABuffer.HEIGHT - 1;
                    }
                }
                buffer.writeAt(' ', new_color, cursor.column, cursor.row);
                cursor.advance();
                updateHardwareCursor();
            }
        },
        '\r' => {
            cursor.column = 0;
            updateHardwareCursor();
        },
        0x08 => {
            if (cursor.column > 0 or cursor.row > 0) {
                cursor.backOne();
                buffer.writeAt(' ', color, cursor.column, cursor.row);
                updateHardwareCursor();
            }
        },
        else => {
            if (cursor.column >= VGABuffer.WIDTH) {
                cursor.newLine();
                if (cursor.checkScroll()) {
                    buffer.scroll(color);
                    cursor.row = VGABuffer.HEIGHT - 1;
                }
            }
            buffer.writeAt(c, new_color, cursor.column, cursor.row);
            cursor.advance();
            updateHardwareCursor();
        },
    }
}

pub fn write(data: []const u8) void {
    for (data) |c|
        putChar(c, color);
}

pub fn handleInput() void {
    const scancode = Keyboard.readScancode();
    if (Keyboard.handleScancode(scancode)) |char| {
        switch (char) {
            0x08 => { // backspace
                cursor.backOne();
                buffer.writeAt(' ', color, cursor.column, cursor.row);
                updateHardwareCursor();
            },
            0x09 => { // tab
                const spaces = TAB_SIZE - (cursor.column % TAB_SIZE);
                var i: usize = 0;
                while (i < spaces) : (i += 1) {
                    putChar(' ', color);
                }
            },
            0x0A => { // enter
                cursor.newLine();
                if (cursor.checkScroll()) {
                    buffer.scroll(color);
                }
                updateHardwareCursor();
            },
            else => {
                putChar(char, color);
            },
        }
    }
}
