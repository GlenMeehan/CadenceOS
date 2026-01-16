// src/kernel/kernel.zig

const std = @import("std");
const vga = @import("vga.zig");
const e820 = @import("E820.zig");
const conv = @import("convert.zig");
const db = @import("debug.zig");
const bi = @import("boot_info.zig");
const tests = @import("tests.zig");
const fa = @import("frame_allocator.zig");
const e820_test = @import("e820_test.zig");
const E820Store = @import("E820Store.zig");
const bm = @import("bitmap.zig");

pub const STACK_SIZE = 0x4000; // 16 KiB, matching what you intended
pub const PAGE_TABLE_BYTES = 64 * 1024; // 64 KiB

// Static heap - 4MB
var heap_buffer: [4 * 1024 * 1024]u8 align(4096) = undefined;


pub fn panic(
    msg: []const u8,
    trace: ?*anyopaque,
    return_address: ?usize,
) noreturn {
    _ = trace;

    // Clear screen to red with spaces, or at least overwrite top lines
    vga.clearScreen(0x4, 0x0); // bg red, fg black (you can adjust)

    // Line 0: big banner
    vga.writeStringAt(0, 0, "KERNEL PANIC", 15, 4); // white on red

    // Line 2: message label
    vga.writeStringAt(2, 0, "Message: ", 14, 4);
    vga.writeStringAt(2, 9, msg, 15, 4);

    // Line 4: return address if available
    vga.writeStringAt(4, 0, "Return address: ", 14, 4);

    if (return_address) |ra| {
        var buf: [18]u8 = undefined; // "0x" + 16 hex digits (64-bit) is enough
        const hex = conv.toHex(usize, ra, buf[0..]);
        vga.writeStringAt(4, 17, hex, 15, 4);
    } else {
        vga.writeStringAt(4, 17, "(none)", 8, 4);
    }

    while (true) {
        asm volatile ("cli; hlt");
    }
}


export fn kernel_entry() void {
    kmain();
    unreachable;
}




pub export fn kmain() noreturn {

    //db.pause();
    const welc_mess = "CadenceOS 64 Bit";

    vga.writeString(welc_mess, 15, 0);

    // 1) Copy E820 entries into kernel-owned memory.
    E820Store.init();

    // 2) Tell E820.zig to use the safe copy.
    e820.setTable(E820Store.getTableAddr(), E820Store.getTableCount());

    // 3) Set up a simple heap allocator from the static buffer.
    var fba = std.heap.FixedBufferAllocator.init(&heap_buffer);
    const allocator = fba.allocator();

    // 4) Use the frame allocator (now backed by safe E820 data).
    fa.FrameAllocator.init();

    const x: u64 = 0x1234ABCDEF112233;
    var buf: [16]u8 = undefined;
    const slice = conv.toHex(u64, x, buf[0..]);

    // Debug: what's the length?
    var len_buf: [8]u8 = undefined;
    vga.writeString(conv.toHex(u32, @intCast(slice.len), &len_buf), 15, 0);

    vga.writeString(slice, 15, 0);

    const y: u32 = 0xBADFACE;
    var buf2: [8]u8 = undefined;
    vga.writeStringAt(3, 0, conv.toHex(u32, y, buf2[0..]), 15, 0);  // yellow on black


    //const bounds = getKernelBounds();
    const info = bi.get();


    var buf_start: [16]u8 = undefined;
    vga.writeStringAt(11, 0, "Kernel start: ", 15, 0);
    vga.writeStringAt(11, 15, conv.toHex(u64, info.kernel_start, &buf_start), 15, 0);

    var buf_end: [16]u8 = undefined;
    vga.writeStringAt(12, 0, "Kernel end:   ", 15, 0);
    vga.writeStringAt(12, 15, conv.toHex(u64, info.kernel_end, &buf_end), 15, 0);

    var buf_stack: [16]u8 = undefined;
    vga.writeStringAt(13, 0, "Stack top:    ", 15, 0);
    vga.writeStringAt(13, 15, conv.toHex(u64, info.stack_top, &buf_stack), 15, 0);

    var row2: u16 = 14;
    var offset: usize = 0;


    while (offset < 0x38) : (offset += 8) {
        var buf_offset: [8]u8 = undefined;
        var buf_bytes: [16]u8 = undefined;

        // Show offset
        vga.writeStringAt(row2, 0, conv.toHex(u32, @intCast(offset), &buf_offset), 15, 0);
        vga.writeStringAt(row2, 9, ": ", 15, 0);

        // Show 8 bytes as one u64
        const value = @as(*const u64, @ptrFromInt(0x7000 + offset)).*;
        vga.writeStringAt(row2, 11, conv.toHex(u64, value, &buf_bytes), 15, 0);

        row2 += 1;
    }

    // Initialize IDT
    const idt = @import("idt.zig");
    idt.init();
    vga.writeStringAt(21, 0, "IDT initialized", 15, 0);

    // Display boot info
    const idt_info = bi.get();
    var buf_idt: [16]u8 = undefined;

    vga.writeStringAt(22, 0, "Kernel start: ", 15, 0);
    vga.writeStringAt(22, 15, conv.toHex(u64, idt_info.kernel_start, &buf_idt), 15, 0);

    vga.writeStringAt(23, 0, "Kernel end:   ", 15, 0);
    vga.writeStringAt(23, 15, conv.toHex(u64, idt_info.kernel_end, &buf_idt), 15, 0);

    // Test exception (remove after testing!)
    // Uncomment to test division by zero handler:
    // Test exception: divide by zero at runtime
    //tests.trigger_divide_by_zero();
    //tests.test_breakpoint();
    //tests.test_invalid_opcode();
    //tests.test_gpf();
    //tests.test_page_fault();
    //@panic("TEST");



    // Test basic allocation
    const ENABLE_TESTS = false;
    if (ENABLE_TESTS) {
        tests.runAllocatorTests(allocator);
    }

    fa.FrameAllocator.init();
    fa.FrameAllocator.parseUsableMemory();
    const regions = fa.getUsableRegions();
    var idx: usize = 0;
    for (regions) |r| {
        var buf_base: [16]u8 = undefined;
        var buf_len: [16]u8 = undefined;

        vga.writeString("Region ", 15, 0);
        vga.writeString(conv.toHex(u64, idx, &buf_base), 15, 0);

        vga.writeString(": base=", 15, 0);
        vga.writeString(conv.toHex(u64, r.base, &buf_base), 15, 0);

        vga.writeString(" len=", 15, 0);
        vga.writeString(conv.toHex(u64, r.length, &buf_len), 15, 0);

        idx += 1;
    }

    // After E820Store and e820.setTable()
    bm.init(regions);
    bm.markUsedRange(info.kernel_start, info.kernel_end);
    bm.markUsedRange(info.stack_top - STACK_SIZE, info.stack_top);
    const e820_start = E820Store.getTableAddr();
    const e820_end = e820_start +
    @as(usize, E820Store.getTableCount()) * @sizeOf(E820Store.E820Entry);
    bm.markUsedRange(e820_start, e820_end);
    const range = bm.getStorageRange();
    bm.markUsedRange(range.start, range.end);
    bm.markUsedRange(info.page_table_base, info.page_table_base + PAGE_TABLE_BYTES);




    while (true) {
        asm volatile ("hlt");
    }
}
