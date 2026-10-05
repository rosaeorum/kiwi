//! This tool fixes a specific bug in the Zig compiler's SPIR-V backend. When Zig
//! compiles a shader to SPIR-V, it sometimes produces structs that contain a
//! "runtime-sized array" (an array whose length isn't known at compile time, like
//! a vertex buffer with an arbitrary number of vertices). The SPIR-V spec requires
//! that any struct containing such an array must be marked with a `Block`
//! decoration, but the Zig backend doesn't always add it; particularly when the
//! struct is accessed through a pointer stored inside another struct (like a buffer
//! pointer stored in a push constant block). The basic patch process is as follows.
//!
//! Scan the zig-generated binary for three things:
//! - runtime array type definitions (`OpTypeRuntimeArray`) - we collect their IDs
//! - struct definitions (`OpTypeStruct`) - for each one, we check whether any member type is a runtime array
//! - existing `Block` decorations (`OpDecorate ... Block`) - so it doesn't add duplicates
//!
//! Then, if structs are missing the `Block` decoration:
//! - find the insertion point:
//!   * decoration instructions must appear in a specific section that comes before the type definitions
//!   * we locate the first type instruction (opcodes 19–39) so that we may insert right before it
//! - allocate a new buffer large enough for the original content plus the new instructions
//! - copy everything up to the insertion point (header, capabilities, entry points, existing annotations, etc.)
//! - insert one `OpDecorate <id> Block` instruction (3 words each) for each struct that needs it
//! - copy the rest of the file (types, constants, functions) after the inserted instructions

const spv_patch = @This();

const std = @import("std");
const builtin = @import("builtin");

const MAGIC: u32 = 0x07230203;
const HEADER_WORDS: usize = 5;

const Opcode = struct {
    pub const type_runtime_array: u16 = 29;
    pub const type_struct: u16 = 30;
    pub const decorate: u16 = 71;
};

const Decoration = struct {
    pub const block: u32 = 2;
};

const native_endian = builtin.target.cpu.arch.endian();

inline fn readWord(words: []const u32, idx: usize) u32 {
    const raw = words[idx];
    return if (native_endian == .big) @byteSwap(raw) else raw;
}

inline fn writeWord(words: []u32, idx: usize, val: u32) void {
    words[idx] = if (native_endian == .big) @byteSwap(val) else val;
}

inline fn makeInstructionWord(word_count: u16, opcode: u16) u32 {
    return (@as(u32, word_count) << 16) | @as(u32, opcode);
}

fn isTypeInstruction(opcode: u16) bool {
    return opcode >= 19 and opcode <= 39;
}

const Instruction = struct {
    offset: usize,
    word_count: u16,
    opcode: u16,
};

const InstructionIter = struct {
    words: []const u32,
    pos: usize = HEADER_WORDS,

    fn next(self: *InstructionIter) ?Instruction {
        if (self.pos >= self.words.len) return null;
        const raw = readWord(self.words, self.pos);
        const word_count: u16 = @intCast(raw >> 16);
        const opcode: u16 = @intCast(raw & 0xFFFF);
        if (word_count == 0) return null;
        const inst = Instruction{ .offset = self.pos, .word_count = word_count, .opcode = opcode };
        self.pos += word_count;
        return inst;
    }
};

pub fn main(init: std.process.Init) !void {
    const argv = try init.minimal.args.toSlice(init.arena.allocator());

    var verbose: bool = false;
    var positional: std.array_list.Managed([]const u8) = .init(init.gpa);
    defer positional.deinit();

    for (argv[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            verbose = true;
        } else {
            try positional.append(arg);
        }
    }

    if (positional.items.len != 2) {
        std.debug.print(
            "Usage: spv_patch [-v] <input.spv> <output.spv>\n",
            .{},
        );
        std.process.exit(1);
    }
    const input_path = positional.items[0];
    const output_path = positional.items[1];

    const input = try std.Io.Dir.cwd().readFileAllocOptions(
        init.io,
        input_path,
        init.gpa,
        .limited(64 * 1024 * 1024),
        .of(u32),
        null,
    );
    defer init.gpa.free(input);

    if (input.len < HEADER_WORDS * 4) {
        std.debug.print("Error: File too small to be valid SPIR-V\n", .{});
        std.process.exit(1);
    }
    if (input.len % 4 != 0) {
        std.debug.print("Error: SPIR-V binary size not a multiple of 4\n", .{});
        std.process.exit(1);
    }

    const words = std.mem.bytesAsSlice(u32, input);

    if (readWord(words, 0) != MAGIC) {
        std.debug.print("Error: Invalid SPIR-V magic number (got 0x{x:0>8}, expected 0x{x:0>8})\n", .{
            readWord(words, 0), MAGIC,
        });
        std.process.exit(1);
    }

    var runtime_array_ids = std.AutoHashMap(u32, void).init(init.gpa);
    defer runtime_array_ids.deinit();

    var structs_needing_block = std.AutoHashMap(u32, void).init(init.gpa);
    defer structs_needing_block.deinit();

    var existing_block = std.AutoHashMap(u32, void).init(init.gpa);
    defer existing_block.deinit();

    var insert_at: usize = words.len;

    var iter = InstructionIter{ .words = words };
    while (iter.next()) |inst| {
        if (insert_at == words.len and isTypeInstruction(inst.opcode)) {
            insert_at = inst.offset;
        }

        switch (inst.opcode) {
            Opcode.type_runtime_array => {
                if (inst.word_count >= 3) {
                    const result_id = readWord(words, inst.offset + 1);
                    try runtime_array_ids.put(result_id, {});
                }
            },

            Opcode.type_struct => {
                if (inst.word_count >= 2) {
                    const struct_id = readWord(words, inst.offset + 1);

                    var member_idx: usize = 2;
                    while (member_idx < inst.word_count) : (member_idx += 1) {
                        const member_type = readWord(words, inst.offset + member_idx);
                        if (runtime_array_ids.contains(member_type)) {
                            try structs_needing_block.put(struct_id, {});
                            break;
                        }
                    }
                }
            },

            Opcode.decorate => {
                if (inst.word_count >= 3) {
                    const target_id = readWord(words, inst.offset + 1);
                    const decoration = readWord(words, inst.offset + 2);
                    if (decoration == Decoration.block) {
                        try existing_block.put(target_id, {});
                    }
                }
            },

            else => {},
        }
    }

    var to_decorate = std.array_list.Managed(u32).init(init.gpa);
    defer to_decorate.deinit();

    var it = structs_needing_block.iterator();
    while (it.next()) |entry| {
        const id = entry.key_ptr.*;
        if (!existing_block.contains(id)) {
            try to_decorate.append(id);
        }
    }

    if (to_decorate.items.len == 0) {
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = output_path, .data = input });
        if (verbose) {
            std.debug.print("No patches needed. Copied as-is.\n", .{});
        }
        return;
    }

    if (insert_at >= words.len) {
        std.debug.print("Error: Could not find types section in SPIR-V binary\n", .{});
        std.process.exit(1);
    }

    const new_inst_count = to_decorate.items.len * 3;
    const total_words = words.len + new_inst_count;
    const output_bytes = try init.gpa.alignedAlloc(u8, .of(u32), total_words * 4);
    defer init.gpa.free(output_bytes);
    const output_words = std.mem.bytesAsSlice(u32, output_bytes);

    for (0..insert_at) |i| {
        writeWord(output_words, i, readWord(words, i));
    }

    var write_pos: usize = insert_at;
    for (to_decorate.items) |struct_id| {
        writeWord(output_words, write_pos, makeInstructionWord(3, Opcode.decorate));
        writeWord(output_words, write_pos + 1, struct_id);
        writeWord(output_words, write_pos + 2, Decoration.block);
        write_pos += 3;
        if (verbose) {
            std.debug.print("Added: OpDecorate %{} Block\n", .{struct_id});
        }
    }

    for (insert_at..words.len) |i| {
        writeWord(output_words, write_pos, readWord(words, i));
        write_pos += 1;
    }

    std.debug.assert(write_pos == total_words);

    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = output_path, .data = output_bytes });
    if (verbose) {
        std.debug.print(
            "Patched {d} struct(s) with Block decoration. Output: {s}\n",
            .{ to_decorate.items.len, output_path },
        );
    }
}
