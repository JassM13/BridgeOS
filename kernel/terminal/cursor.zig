pub const Cursor = struct {
    column: usize,
    row: usize,
    width: usize,
    height: usize,

    pub fn init(width: usize, height: usize) Cursor {
        return Cursor{
            .column = 0,
            .row = 0,
            .width = width,
            .height = height,
        };
    }

    pub fn advance(self: *Cursor) void {
        self.column += 1;
        if (self.column >= self.width) {
            self.column = 0;
            self.row += 1;
            if (self.row >= self.height) {
                self.row = self.height - 1;
            }
        }
    }

    pub fn backOne(self: *Cursor) void {
        if (self.column > 0) {
            self.column -= 1;
        } else if (self.row > 0) {
            self.row -= 1;
            self.column = self.width - 1;
        }
    }

    pub fn newLine(self: *Cursor) void {
        self.column = 0;
        self.row += 1;
        if (self.row >= self.height) {
            self.row = self.height - 1;
        }
    }

    pub fn checkScroll(self: *Cursor) bool {
        return self.row >= self.height;
    }
};