const std = @import("std");
const frame_allocator = @import("frame_allocator.zig");
const Region = frame_allocator.Region;

pub const PAGE_SIZE: usize = 4096;

// ------------------------------------------------------------
// Global bitmap storage
// ------------------------------------------------------------

// Enough for ~1 GiB of RAM (262,144 pages)
var bitmap_storage: [32768]u8 = [_]u8{0xFF} ** 32768;
var bitmap: []u8 = bitmap_storage[0..];

var total_pages: usize = 0;

// ------------------------------------------------------------
// Helpers
// ------------------------------------------------------------

fn computeBitmapSize(pages: usize) usize {
    return (pages + 7) / 8;
}

fn markFree(page_index: usize) void {
    const byte_index = page_index / 8;
    const bit_index = page_index % 8;
    bitmap[byte_index] &= ~( @as(u8, 1) << @intCast(bit_index) );
}

fn markUsed(page_index: usize) void {
    const byte_index = page_index / 8;
    const bit_index = page_index % 8;
    bitmap[byte_index] |= (@as(u8, 1) << @intCast(bit_index));
}

// ------------------------------------------------------------
// Init
// ------------------------------------------------------------

pub fn init(regions: []const Region) void {
    // 1. Count total pages across all regions
    var total: usize = 0;
    for (regions) |r| {
        total += r.length / PAGE_SIZE;
    }
    total_pages = total;

    // 2. Check bitmap capacity
    const needed_bytes = computeBitmapSize(total_pages);
    if (needed_bytes > bitmap.len) {
        @panic("Bitmap storage too small for available memory");
    }

    // 3. Mark usable pages as free
    for (regions) |r| {
        const start_page = r.base / PAGE_SIZE;
        const page_count = r.length / PAGE_SIZE;

        var i: usize = 0;
        while (i < page_count) : (i += 1) {
            markFree(start_page + i);
        }
    }
}

pub fn markUsedRange(start_phys: usize, end_phys: usize) void {
    const start_page = start_phys / PAGE_SIZE;
    const end_page = (end_phys + PAGE_SIZE - 1) / PAGE_SIZE;

    var page = start_page;
    while (page < end_page) : (page += 1) {
        markUsed(page);
    }
}

pub fn getStorageRange() struct { start: usize, end: usize } {
    const start = @intFromPtr(&bitmap_storage[0]);
    const end   = start + bitmap_storage.len;
    return .{ .start = start, .end = end };
}

