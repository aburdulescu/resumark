// TODOs:
// - implement line wrap, or error if line is too big?
// - error if document is bigger than 1 page -> cv must be short
// - error if md contains unexpected nodes

const std = @import("std");
const c = @cImport({
    @cInclude("cmark.h");
    @cInclude("hpdf.h");
});

pub fn main() !void {
    var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const all_args = try std.process.argsAlloc(arena);
    const args = all_args[1..];

    if (args.len == 0) {
        std.debug.print("Usage: resumark MARKDOWN_FILE\n", .{});
        return;
    }

    const markdown_file = args[0];

    const MB = 1024 * 1024;
    const markdown = try std.fs.cwd().readFileAlloc(arena, markdown_file, 1 * MB);

    try markdown_to_pdf(markdown);
}

fn markdown_to_pdf(markdown: []const u8) !void {
    const doc = c.HPDF_New(libharu_error_handler, null);
    if (doc == null) {
        return error.CannotCreatePDFObject;
    }

    const page = c.HPDF_AddPage(doc);

    const max_x: f32 = c.HPDF_Page_GetWidth(page);
    const max_y: f32 = c.HPDF_Page_GetHeight(page);

    const font_size_text = 9;
    const font_size_head = 14;
    const indent = 15;

    const font = c.HPDF_GetFont(doc, "Helvetica", null);
    if (c.HPDF_GetError(doc) != c.HPDF_OK) return error.FailedToGetFont;

    const font_bold = c.HPDF_GetFont(doc, "Helvetica-Bold", null);
    if (c.HPDF_GetError(doc) != c.HPDF_OK) return error.FailedToGetBoldFont;

    const font_italic = c.HPDF_GetFont(doc, "Helvetica-Oblique", null);
    if (c.HPDF_GetError(doc) != c.HPDF_OK) return error.FailedToGetBoldFont;

    const list_item_prefix = "- ";
    var list_item_prefix_width: f32 = 0;

    var x: f32 = indent;
    var y: f32 = max_y - 20;

    const root = c.cmark_parse_document(
        markdown.ptr,
        markdown.len,
        c.CMARK_OPT_DEFAULT,
    );

    const iter = c.cmark_iter_new(root);
    while (true) {
        const event = c.cmark_iter_next(iter);
        if (event == c.CMARK_EVENT_DONE) {
            break;
        }
        const node = c.cmark_iter_get_node(iter);
        const node_type = c.cmark_node_get_type(node);
        const node_type_string = c.cmark_node_get_type_string(node);



        switch (event) {
            c.CMARK_EVENT_ENTER => {
                std.debug.print("-> {s}\n", .{node_type_string});

                switch (node_type) {
                    c.CMARK_NODE_DOCUMENT => {
                        // ignore
                    },

                    c.CMARK_NODE_STRONG => {
                        if (c.HPDF_Page_SetFontAndSize(page, font_bold, font_size_text) != c.HPDF_OK) return error.FailedToSetFontForSTRONG;
                    },

                    c.CMARK_NODE_EMPH => {
                        if (c.HPDF_Page_SetFontAndSize(page, font_italic, font_size_text) != c.HPDF_OK) return error.FailedToSetFontForEMPH;
                    },

                    c.CMARK_NODE_HEADING => {
                        const level = c.cmark_node_get_heading_level(node);
                        const size: f32 = @floatFromInt(font_size_head - (level * 2));
                        if (c.HPDF_Page_SetFontAndSize(page, font_bold, size) != c.HPDF_OK) return error.FailedToSetFontForHEADING;
                    },

                    c.CMARK_NODE_PARAGRAPH => {
                        if (c.HPDF_Page_SetFontAndSize(page, font, font_size_text) != c.HPDF_OK) return error.FailedToSetFontForPARAGRAPH;
                    },

                    c.CMARK_NODE_LIST => {
                        x += indent;
                    },

                    c.CMARK_NODE_ITEM => {
                        list_item_prefix_width = c.HPDF_Page_TextWidth(page, list_item_prefix);
                        if (c.HPDF_Page_BeginText(page) != c.HPDF_OK) return error.FailedToBeginITEM;
                        if (c.HPDF_Page_TextOut(page, x, y, list_item_prefix) != c.HPDF_OK) return error.FailedToPrintITEM;
                        if (c.HPDF_Page_EndText(page) != c.HPDF_OK) return error.FailedToEndITEM;
                        x += list_item_prefix_width;
                    },

                    c.CMARK_NODE_TEXT => {
                        const text = c.cmark_node_get_literal(node);
                        if (c.HPDF_Page_BeginText(page) != c.HPDF_OK) return error.FailedToBeginTEXT;
                        if (c.HPDF_Page_TextOut(page, x, y, text) != c.HPDF_OK) return error.FailedToPrintTEXT;
                        if (c.HPDF_Page_EndText(page) != c.HPDF_OK) return error.FailedToEndTEXT;
                        y -= 16; // move down
                    },

                    c.CMARK_NODE_LINK => {
                        std.debug.print("error: node not supported: '{s}'\n", .{node_type_string});
                        return error.UnsupportedNode;
                    },

                    else => {
                        std.debug.print("warning: node entered but not handled: '{s}'\n", .{node_type_string});
                    },
                }
            },

            c.CMARK_EVENT_EXIT => {
                std.debug.print("<- {s}\n", .{node_type_string});

                switch (node_type) {
                    c.CMARK_NODE_STRONG, c.CMARK_NODE_EMPH => {
                        if (c.HPDF_Page_SetFontAndSize(page, font, font_size_text) != c.HPDF_OK) return error.FailedToReSetFontForSTRONG;
                    },

                    c.CMARK_NODE_LIST => {
                        x -= indent;
                    },

                    c.CMARK_NODE_ITEM => {
                        x -= list_item_prefix_width;
                    },

                    else => {
                        // ignore
                    },
                }
            },

            else => unreachable,
        }
    }

    if (c.HPDF_SaveToFile(doc, "out.pdf") != c.HPDF_OK) return error.FailedToSaveFile;

    _ = max_x; // TODO: use this for line wrap
}

fn libharu_error_handler(
    error_no: c.HPDF_STATUS,
    detail_no: c.HPDF_STATUS,
    user_data: ?*anyopaque,
) callconv(.c) void {
    _ = user_data;
    std.debug.print("libharu error: error_no 0x{x:0>4}, detail_no 0x{x:0>4}\n", .{ error_no, detail_no });
}
