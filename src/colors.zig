const Pixel = @import("common.zig").Pixel;

pub const Colors = struct {
    pub const WHITE = Pixel.init(255, 255, 255, null);
    pub const BLACK = Pixel.init(0, 0, 0, null);
    pub const RED = Pixel.init(255, 0, 0, null);
    pub const BLUE = Pixel.init(0, 0, 255, null);
    pub const GREEN = Pixel.init(0, 255, 0, null);
    pub const YELLOW = Pixel.init(255, 255, 0, null);
    pub const MAGENTA = Pixel.init(255, 0, 255, null);
    pub const CYAN = Pixel.init(0, 255, 255, null);
    //TODO add more colors
};
