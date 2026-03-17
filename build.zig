const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    comptime {
        const needed = "0.15.2";
        const current = builtin.zig_version;
        const needed_vers = std.SemanticVersion.parse(needed) catch unreachable;
        if (current.order(needed_vers) != .eq) {
            @compileError("Your zig version is not supported, need version " ++ needed);
        }
    }

    const optimize = b.standardOptimizeOption(.{});
    const strip = b.option(bool, "strip", "Strip the binary") orelse switch (optimize) {
        .Debug, .ReleaseSafe => false,
        else => true,
    };

    const targets = [_]std.Target.Query{
        .{ .os_tag = .linux, .cpu_arch = .aarch64 },
        .{ .os_tag = .linux, .cpu_arch = .x86_64 },
        .{ .os_tag = .macos, .cpu_arch = .aarch64 },
        .{ .os_tag = .macos, .cpu_arch = .x86_64 },
        .{ .os_tag = .windows, .cpu_arch = .x86_64 },
    };

    for (targets) |query| {
        const target = b.resolveTargetQuery(query);

        const cmark = b.addLibrary(.{
            .name = "cmark",
            .linkage = .static,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .single_threaded = true,
            }),
        });
        cmark.addIncludePath(b.path("deps/cmark"));
        cmark.addCSourceFiles(.{
            .files = &.{
                "deps/cmark/blocks.c",
                "deps/cmark/buffer.c",
                "deps/cmark/cmark.c",
                "deps/cmark/cmark_ctype.c",
                "deps/cmark/commonmark.c",
                "deps/cmark/houdini_href_e.c",
                "deps/cmark/houdini_html_e.c",
                "deps/cmark/houdini_html_u.c",
                "deps/cmark/html.c",
                "deps/cmark/inlines.c",
                "deps/cmark/iterator.c",
                "deps/cmark/latex.c",
                "deps/cmark/man.c",
                "deps/cmark/node.c",
                "deps/cmark/references.c",
                "deps/cmark/render.c",
                "deps/cmark/scanners.c",
                "deps/cmark/utf8.c",
                "deps/cmark/xml.c",
            },
            .flags = &.{
                "-Wall", "-Wextra", "-Werror",
            },
        });

        const libharu = b.addLibrary(.{
            .name = "libharu",
            .linkage = .static,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .single_threaded = true,
            }),
        });
        libharu.addIncludePath(b.path("deps/libharu/include"));
        libharu.addCSourceFiles(.{
            .files = &.{
                "deps/libharu/src/hpdf_3dmeasure.c",
                "deps/libharu/src/hpdf_annotation.c",
                "deps/libharu/src/hpdf_array.c",
                "deps/libharu/src/hpdf_binary.c",
                "deps/libharu/src/hpdf_boolean.c",
                "deps/libharu/src/hpdf_catalog.c",
                "deps/libharu/src/hpdf_destination.c",
                "deps/libharu/src/hpdf_dict.c",
                "deps/libharu/src/hpdf_direct.c",
                "deps/libharu/src/hpdf_doc.c",
                "deps/libharu/src/hpdf_doc_png.c",
                "deps/libharu/src/hpdf_encoder.c",
                "deps/libharu/src/hpdf_encoder_cns.c",
                "deps/libharu/src/hpdf_encoder_cnt.c",
                "deps/libharu/src/hpdf_encoder_jp.c",
                "deps/libharu/src/hpdf_encoder_kr.c",
                "deps/libharu/src/hpdf_encoder_utf.c",
                "deps/libharu/src/hpdf_encrypt.c",
                "deps/libharu/src/hpdf_encryptdict.c",
                "deps/libharu/src/hpdf_error.c",
                "deps/libharu/src/hpdf_exdata.c",
                "deps/libharu/src/hpdf_ext_gstate.c",
                "deps/libharu/src/hpdf_font.c",
                "deps/libharu/src/hpdf_font_cid.c",
                "deps/libharu/src/hpdf_fontdef_base14.c",
                "deps/libharu/src/hpdf_fontdef.c",
                "deps/libharu/src/hpdf_fontdef_cid.c",
                "deps/libharu/src/hpdf_fontdef_cns.c",
                "deps/libharu/src/hpdf_fontdef_cnt.c",
                "deps/libharu/src/hpdf_fontdef_jp.c",
                "deps/libharu/src/hpdf_fontdef_kr.c",
                "deps/libharu/src/hpdf_fontdef_tt.c",
                "deps/libharu/src/hpdf_fontdef_type1.c",
                "deps/libharu/src/hpdf_font_tt.c",
                "deps/libharu/src/hpdf_font_type1.c",
                "deps/libharu/src/hpdf_gstate.c",
                "deps/libharu/src/hpdf_image.c",
                "deps/libharu/src/hpdf_image_ccitt.c",
                "deps/libharu/src/hpdf_image_png.c",
                "deps/libharu/src/hpdf_info.c",
                "deps/libharu/src/hpdf_list.c",
                "deps/libharu/src/hpdf_mmgr.c",
                "deps/libharu/src/hpdf_name.c",
                "deps/libharu/src/hpdf_namedict.c",
                "deps/libharu/src/hpdf_null.c",
                "deps/libharu/src/hpdf_number.c",
                "deps/libharu/src/hpdf_objects.c",
                "deps/libharu/src/hpdf_outline.c",
                "deps/libharu/src/hpdf_page_label.c",
                "deps/libharu/src/hpdf_page_operator.c",
                "deps/libharu/src/hpdf_pages.c",
                "deps/libharu/src/hpdf_pdfa.c",
                "deps/libharu/src/hpdf_real.c",
                "deps/libharu/src/hpdf_shading.c",
                "deps/libharu/src/hpdf_streams.c",
                "deps/libharu/src/hpdf_string.c",
                "deps/libharu/src/hpdf_u3d.c",
                "deps/libharu/src/hpdf_utils.c",
                "deps/libharu/src/hpdf_xref.c",
            },
            .flags = &.{
                "-Wall", "-Wextra",
            },
        });

        const t = target.result;

        const exe = b.addExecutable(.{
            .name = b.fmt("resumark-{s}-{s}", .{
                @tagName(t.os.tag),
                @tagName(t.cpu.arch),
            }),
            .root_module = b.createModule(.{
                .root_source_file = b.path("main.zig"),
                .target = target,
                .optimize = optimize,
                .strip = strip,
                .link_libc = true,
                .single_threaded = true,
            }),
        });
        exe.addIncludePath(b.path("deps/cmark"));
        exe.addIncludePath(b.path("deps/libharu/include"));
        exe.linkLibrary(cmark);
        exe.linkLibrary(libharu);
        b.installArtifact(exe);
    }
}
