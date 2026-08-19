require('cairo')
require('cairo_xlib')

-- Paints the frosted panel the window itself cannot provide: conky windows are
-- rectangles, so the rounded outline has to be drawn. The quickshell bar's #121212
-- but at 85% alpha rather than its 55%: the bar's translucency works because the
-- compositor blurs what is behind it, and Mutter blurs nothing for an X11 window,
-- so the wallpaper would otherwise show through sharp and fight the text.
function conky_draw_panel()
    if conky_window == nil then
        return
    end

    local w, h = conky_window.width, conky_window.height
    local surface = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, w, h)
    local cr = cairo_create(surface)

    local radius = 18
    -- Half-pixel inset keeps the 1px border on whole pixels instead of blurring
    -- across two.
    local x0, y0 = 0.5, 0.5
    local x1, y1 = w - 0.5, h - 0.5

    cairo_new_sub_path(cr)
    cairo_arc(cr, x1 - radius, y0 + radius, radius, -math.pi / 2, 0)
    cairo_arc(cr, x1 - radius, y1 - radius, radius, 0, math.pi / 2)
    cairo_arc(cr, x0 + radius, y1 - radius, radius, math.pi / 2, math.pi)
    cairo_arc(cr, x0 + radius, y0 + radius, radius, math.pi, 3 * math.pi / 2)
    cairo_close_path(cr)

    cairo_set_source_rgba(cr, 0.07, 0.07, 0.07, 0.85)
    cairo_fill_preserve(cr)

    cairo_set_source_rgba(cr, 1, 1, 1, 0.125)
    cairo_set_line_width(cr, 1)
    cairo_stroke(cr)

    cairo_destroy(cr)
    cairo_surface_destroy(surface)
end
