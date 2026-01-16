//src/kernel/vga.zig

const VGA = @as([*]volatile u16, @ptrFromInt(0xB8000));
const WIDTH = 80;
const HEIGHT = 25;

pub fn writeStringAt(
    row: u16,
    col: u16,
    s: []const u8,
    fg: u8,
    bg: u8,
) void {
    const color = (@as(u16, bg) << 12) | (@as(u16, fg) << 8);

    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        const pos = row * 80 + col + @as(u16, @intCast(i));
        VGA[pos] = color | s[i];
    }
}

pub var cursor_row: usize = 0;
pub var cursor_col: usize = 0;

/// Scroll the screen up by one line
pub fn scroll() void {
    // Move rows 1..24 to rows 0..23
    var row: usize = 1;
    while (row < HEIGHT) : (row += 1) {
        const src = row * WIDTH;
        const dst = (row - 1) * WIDTH;

        var col: usize = 0;
        while (col < WIDTH) : (col += 1) {
            VGA[dst + col] = VGA[src + col];
        }
    }

    // Clear the last row
    const last = (HEIGHT - 1) * WIDTH;
    var i: usize = 0;
    while (i < WIDTH) : (i += 1) {
        VGA[last + i] = 0x0720; // space, light grey on black
    }
}

/// Write a single character at the current cursor position
pub fn putChar(c: u8, fg: u8, bg: u8) void {
    const color = (@as(u16, bg) << 12) | (@as(u16, fg) << 8);

    if (c == '\n') {
        cursor_row += 1;
        cursor_col = 0;
    } else {
        VGA[cursor_row * WIDTH + cursor_col] = color | c;
        cursor_col += 1;
    }

    if (cursor_col >= WIDTH) {
        cursor_col = 0;
        cursor_row += 1;
    }

    if (cursor_row >= HEIGHT) {
        scroll();
        cursor_row = HEIGHT - 1;
    }
}

/// Write a string starting at the cursor
pub fn writeString(s: []const u8, fg: u8, bg: u8) void {
    nextLine();
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        putChar(s[i], fg, bg);
    }
}

pub fn nextLine() void {
    // Try to find the first empty line
    var row: usize = 0;
    while (row < HEIGHT) : (row += 1) {
        var empty = true;

        var col: usize = 0;
        while (col < WIDTH) : (col += 1) {
            const cell = VGA[row * WIDTH + col];
            const ch = @as(u8, @truncate(cell)); // low byte = character

            if (ch != 0x20) { // not a space
                empty = false;
                break;
            }
        }

        if (empty) {
            cursor_row = row;
            cursor_col = 0;
            return;
        }
    }

    // No empty line found → scroll
    scroll();
    cursor_row = HEIGHT - 1;
    cursor_col = 0;
}

pub fn clearScreen(fg: u8, bg: u8) void {
    const color = (@as(u16, bg) << 12) | (@as(u16, fg) << 8);
    const blank = color | 0x20; // space character

    var i: usize = 0;
    while (i < WIDTH * HEIGHT) : (i += 1) {
        VGA[i] = blank;
    }

    cursor_row = 0;
    cursor_col = 0;
}

