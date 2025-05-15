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
    pub const SLATE = Pixel.init(112, 128, 144, null);
    pub const GRAY = Pixel.init(128, 128, 128, null);
    pub const STONE = Pixel.init(146, 142, 133, null);
    pub const BROWN = Pixel.init(51, 24, 0, null);
    pub const WENGE = Pixel.init(100, 84, 82, null);
    pub const DARK_BROWN = Pixel.init(92, 64, 51, null);
    pub const BEAVER = Pixel.init(159, 129, 112, null);
    //TODO add more colors
};
