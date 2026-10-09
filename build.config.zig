// public domain

pub const gpu_staging_capacity = .{
    .type = u32,
    .default = 256,
    .min = 1,
    .max = 1024,
    .description = "Maximum capacity (in megabytes) for the per-frame staging buffer.",
};

pub const gpu_heap_overhead = .{
    .type = u32,
    .default = 256,
    .min = 16,
    .max = 1024,
    .description = "Overhead (in megabytes) to allow the OS/driver when allocating gpu heaps.",
};
