pub const Sampler = packed struct(u32) {
    storage_index: Index,

    pub fn nearest(gpu: *Gpu) !Sampler {
        return custom(gpu, &.{
            .mag_filter = .nearest,
            .min_filter = .nearest,
            .mipmap_mode = .nearest,
        });
    }

    pub fn linear(gpu: *Gpu) !Sampler {
        return custom(gpu, &.{
            .mag_filter = .linear,
            .min_filter = .linear,
            .mipmap_mode = .linear,
            .max_anisotropy = 0.0, // TODO: mipmaps
        });
    }

    pub fn custom(gpu: *Gpu, config: *const Config) !Sampler {
        return gpu.store.sampler.fetch(config);
    }

    pub fn getIndex(self: Sampler) u32 {
        return self.storage_index;
    }
};

pub const Index = u32;

pub const Config = struct {
    unnormalized_coordinates: bool = false,
    mag_filter: Gpu.Filter,
    min_filter: Gpu.Filter,
    mipmap_mode: Gpu.MipmapMode,
    address_mode_u: Gpu.AddressMode = .repeat,
    address_mode_v: Gpu.AddressMode = .repeat,
    address_mode_w: Gpu.AddressMode = .repeat,
    compare_op: Gpu.CompareOp = .none,
    border_color: Gpu.BorderColor = .int_opaque_white,
    min_lod: f32 = 0.0,
    max_lod: f32 = 0.0,
    mip_lod_bias: f32 = 0.0,
    max_anisotropy: f32 = 0.0,

    fn toData(self: Config) Data {
        return Data{
            .bits = .{
                .unnormalized_coordinates = self.unnormalized_coordinates,
                .mag_filter = self.mag_filter,
                .min_filter = self.min_filter,
                .mipmap_mode = self.mipmap_mode,
                .address_mode_u = self.address_mode_u,
                .address_mode_v = self.address_mode_v,
                .address_mode_w = self.address_mode_w,
                .compare_op = self.compare_op,
                .border_color = self.border_color,
            },
            .min_lod = .fromF32(self.min_lod),
            .max_lod = .fromF32(self.max_lod),
            .mip_lod_bias = .fromF32(self.mip_lod_bias),
            .max_anisotropy = .fromF32(self.max_anisotropy),
        };
    }
};

pub const Data = extern struct {
    bits: Packed = .{},
    min_lod: Gpu.CanonFloat = .zero,
    max_lod: Gpu.CanonFloat = .zero,
    mip_lod_bias: Gpu.CanonFloat = .zero,
    max_anisotropy: Gpu.CanonFloat = .zero,

    pub const Packed = packed struct(u32) {
        unnormalized_coordinates: bool = false, // 1
        mag_filter: Gpu.Filter = .nearest, // 2
        min_filter: Gpu.Filter = .nearest, // 2
        mipmap_mode: Gpu.MipmapMode = .nearest, // 1
        address_mode_u: Gpu.AddressMode = .clamp_to_edge, // 3
        address_mode_v: Gpu.AddressMode = .clamp_to_edge, // 3
        address_mode_w: Gpu.AddressMode = .clamp_to_edge, // 3
        compare_op: Gpu.CompareOp = .none, // 4
        border_color: Gpu.BorderColor = .float_opaque_black, // 3
        // 1 + 2 + 2 + 1 + 3 + 3 + 3 + 4 + 3 = 22
        _unused: u10 = 0,

        // TODO: support extensions?
        // subsampled_bit_ext: bool = false,
        // subsampled_coarse_reconstruction_bit_ext: bool = false,
        // non_seamless_cube_map_bit_ext: bool = false,
        // descriptor_buffer_capture_replay_bit_ext: bool = false,
        // image_processing_bit_qcom: bool = false,
    };
};

pub const Store = struct {
    gpu: *Gpu,
    key_page_count: u32 = 0,
    keys: base.VMultiArray(Key) = .empty,
    storage: base.VArray(vk.Sampler) = .empty,

    pub const max_capacity = math.maxInt(u8);

    const Key = struct {
        hash: u64 = 0,
        index: u32 = base.sentinel(u32),
        data: Data = .{},

        pub const uninit = Key{};
    };

    const key_page_size = 8192;
    const max_probes = 16;
    const max_pages = @divFloor(max_capacity, key_page_size);

    pub fn init(gpu: *Gpu) !*Store {
        const self = try base.gpa.create(Store);

        self.* = .{ .gpu = gpu };

        return self;
    }

    pub fn deinit(self: *Store) void {
        for (self.storage.slice()) |handle| {
            self.gpu.device.proxy.destroySampler(handle, null);
        }
        self.keys.deinit();
        self.storage.deinit();
        self.* = undefined;
    }

    pub fn fetch(self: *Store, config: *const Config) !Sampler {
        const key = Data{
            .bits = .{
                .unnormalized_coordinates = config.unnormalized_coordinates,
                .mag_filter = config.mag_filter,
                .min_filter = config.min_filter,
                .mipmap_mode = config.mipmap_mode,
                .address_mode_u = config.address_mode_u,
                .address_mode_v = config.address_mode_v,
                .address_mode_w = config.address_mode_w,
                .compare_op = config.compare_op,
                .border_color = config.border_color,
            },
            .min_lod = .fromF32(config.min_lod),
            .max_lod = .fromF32(config.max_lod),
            .mip_lod_bias = .fromF32(config.mip_lod_bias),
            .max_anisotropy = .fromF32(config.max_anisotropy),
        };

        const hash = base.wyhash(mem.asBytes(&key));
        const hash_index = hash % key_page_size;

        var page_probe_index: u64 = 0;

        const key_index: u64 = page_loop: while (page_probe_index < self.key_page_count) : (page_probe_index += 1) {
            const page_index_offset = page_probe_index * key_page_size;

            var key_probe_count: u32 = 0;
            var key_index_offset: u64 = hash_index;

            while (key_probe_count < max_probes) : ({
                key_index_offset = (key_index_offset + 1) % key_page_size;
                key_probe_count += 1;
            }) {
                const key_index = page_index_offset + key_index_offset;

                if (base.isSentinel(self.keys.field(.index, key_index))) {
                    break :page_loop key_index;
                }

                if (self.keys.field(.hash, key_index) == hash) {
                    if (mem.eql(u8, mem.asBytes(self.keys.fieldPtr(.data, key_index)), mem.asBytes(&key))) {
                        break :page_loop key_index;
                    }
                }
            }
        } else new_page: {
            const old_key_count = self.keys.count;
            self.key_page_count += 1;
            try self.keys.ensureCapacity(self.key_page_count * key_page_size);
            self.keys.count = key_page_size;
            @memset(self.keys.sliceMut(.hash)[old_key_count..], Key.uninit.hash);
            @memset(self.keys.sliceMut(.index)[old_key_count..], Key.uninit.index);
            @memset(self.keys.sliceMut(.data)[old_key_count..], Key.uninit.data);
            break :new_page hash_index;
        };

        const storage_index = self.keys.fieldMut(.index, key_index);

        if (!base.isSentinel(storage_index.*)) {
            return .{ .storage_index = storage_index.* };
        }

        const new_index = self.storage.count;
        if (new_index >= self.gpu.max_samplers) return error.OutOfMemory;

        const compare_op = config.compare_op.toVk();

        const handle = try self.gpu.device.proxy.createSampler(&.{
            .mag_filter = config.mag_filter.toVk(),
            .min_filter = config.min_filter.toVk(),
            .mipmap_mode = config.mipmap_mode.toVk(),
            .address_mode_u = config.address_mode_u.toVk(),
            .address_mode_v = config.address_mode_v.toVk(),
            .address_mode_w = config.address_mode_w.toVk(),
            .anisotropy_enable = if (config.max_anisotropy > 0) .true else .false,
            .max_anisotropy = config.max_anisotropy,
            .compare_enable = if (compare_op != null) .true else .false,
            .compare_op = compare_op orelse .always,
            .min_lod = config.min_lod,
            .max_lod = config.max_lod,
            .mip_lod_bias = config.mip_lod_bias,
            .border_color = config.border_color.toVk(),
            .unnormalized_coordinates = if (config.unnormalized_coordinates) .true else .false,
        }, null);
        errdefer self.gpu.device.proxy.destroySampler(handle, null);

        try self.storage.push(handle);

        storage_index.* = @intCast(new_index);

        self.keys.fieldMut(.hash, key_index).* = hash;
        self.keys.fieldMut(.data, key_index).* = key;

        self.gpu.device.proxy.updateDescriptorSets(&.{
            vk.WriteDescriptorSet{
                .dst_set = self.gpu.descriptor_set,
                .dst_binding = 1,
                .dst_array_element = storage_index.*,
                .descriptor_count = 1,
                .descriptor_type = .sampler,
                .p_image_info = &.{
                    vk.DescriptorImageInfo{
                        .sampler = handle,
                        .image_view = .null_handle,
                        .image_layout = .undefined,
                    },
                },
                .p_buffer_info = undefined,
                .p_texel_buffer_view = undefined,
            },
        }, null);

        return .{ .storage_index = storage_index.* };
    }
};

const base = @import("../base.zig");
const vk = @import("../vulkan.zig");
const Gpu = @import("../Gpu.zig");

const mem = base.mem;
const math = base.math;
