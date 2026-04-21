const std = @import("std");
//TODO add inverse calculation to support solving systems of linear equations
/// A simple matrix library for 2D and 3D transformations, as well as some image processing kernels. The main purpose of this library is to demonstrate the use of compile-time features in Zig, such as generics and error handling, to create a flexible and efficient matrix implementation. The library supports basic operations like scaling, rotation, shearing, translation, and convolution with predefined kernels for edge detection and blurring. It also includes a method for vectorizing tuples or structs into homogeneous coordinates for transformation applications.
pub fn Mat(comptime S: comptime_int, comptime T: type) type {
    return struct {
        data: [S * S]T = undefined,
        size: usize = S,
        pub const Self = @This();
        pub const Vec = @Vector(S, T);
        pub const Error = error{
            TransformationUndefined,
            ArgError,
        };
        pub fn init(data: [S * S]T) Self {
            return Self{
                .data = data,
            };
        }
        /// Debug method to print the matrix in a readable format. This is not optimized for performance and is intended for development and debugging purposes.
        pub fn print(self: *const Self) void {
            std.log.debug("{any}\n", .{self.data});
            for (0..S) |i| {
                const v: Vec = self.data[i * S .. i * S + S][0..S].*;
                std.log.debug("{any}\n", .{v});
            }
        }
        /// Creates a scaling transformation matrix. This method assumes that the scaling is uniform across all dimensions and that the last row and column are reserved for homogeneous coordinates. If the matrix size is less than 2, it returns an error since scaling is not defined for 1x1 matrices.
        pub fn scale(s: T) Error!Self {
            if (S < 2) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = s;
            ret.data[1] = 0;
            ret.data[2] = 0;

            ret.data[S] = 0;
            ret.data[S + 1] = s;
            ret.data[S + 2] = 0;
            ret.fill_identity(2);
            return ret;
        }
        /// Fills the matrix with the identity transformation starting from a specified row and column index. This is useful for creating transformation matrices where only a subset of the matrix is modified, and the rest should remain as the identity. The method iterates through the specified range and sets the appropriate elements to 1 for the diagonal and 0 for the off-diagonal elements.-
        pub fn fill_identity(self: *Self, rc_start: usize) void {
            for (rc_start..S) |i| {
                for (0..S - 1) |j| {
                    self.data[j * S + i] = 0;
                    self.data[i * S + j] = 0;
                }
                self.data[i * S + i] = 1;
            }
        }

        /// Clamps the elements of a vector to a specified minimum and maximum value. This method creates two vectors filled with the minimum and maximum values, respectively, and then uses vectorized comparisons and selections to clamp each element of the input vector. The result is a new vector where each element is guaranteed to be within the specified range. This is particularly useful for operations like color clamping in image processing, where pixel values need to be constrained to a certain range.
        pub fn clamp_vector(v: Vec, min: T, max: T) Vec {
            const min_v: Vec = @splat(min);
            const max_v: Vec = @splat(max);
            var pred: @Vector(S, bool) = v < min_v;
            var res: Vec = @select(T, pred, min_v, v);
            pred = res > max_v;
            res = @select(T, pred, max_v, res);
            return res;
        }

        /// Fills the matrix with a specified value starting from a given row and column index. This method is similar to `fill_identity`, but instead of setting the diagonal elements to 1 and the off-diagonal elements to 0, it sets all elements in the specified range to the provided value. This can be useful for initializing matrices with a specific value or for creating uniform transformation matrices where all elements are the same.
        pub fn fill_x(self: *Self, rc_start: usize, x: T) void {
            for (rc_start..S) |i| {
                for (rc_start..S) |j| {
                    self.data[i * S + j] = x;
                }
            }
        }

        /// Creates a rotation transformation matrix for a specified axis and angle in degrees. The method first checks if the matrix size is sufficient to support the requested rotation (at least 2x2 for 2D rotation and at least 4x4 for 3D rotation). It then calculates the sine and cosine of the rotation angle and fills the appropriate elements of the matrix based on the chosen axis of rotation (x, y, or z). The remaining elements are set to form an identity transformation for the unaffected dimensions. If the requested rotation is not defined for the given matrix size or axis, it returns an error.
        pub fn rotate(comptime axis: @Type(.enum_literal), degrees: T) Error!Self {
            if (S < 2) return Error.TransformationUndefined;
            const rad = degrees * std.math.rad_per_deg;
            var ret = Self{};
            switch (axis) {
                .x => {
                    if (S < 4) return Error.TransformationUndefined;
                    ret.data[0] = 1;
                    ret.data[1] = 0;
                    ret.data[2] = 0;

                    ret.data[S] = 0;
                    ret.data[S + 1] = std.math.cos(rad);
                    ret.data[S + 2] = std.math.sin(rad);

                    ret.data[2 * S] = 0;
                    ret.data[2 * S + 1] = -std.math.sin(rad);
                    ret.data[2 * S + 2] = std.math.cos(rad);
                    ret.fill_identity(3);
                },
                .y => {
                    if (S < 4) return Error.TransformationUndefined;
                    ret.data[0] = std.math.cos(rad);
                    ret.data[1] = 0;
                    ret.data[2] = -std.math.sin(rad);

                    ret.data[S] = 0;
                    ret.data[S + 1] = 1;
                    ret.data[S + 2] = 0;

                    ret.data[2 * S] = std.math.sin(rad);
                    ret.data[2 * S + 1] = 0;
                    ret.data[2 * S + 2] = std.math.cos(rad);
                    ret.fill_identity(3);
                },
                .z => {
                    ret.data[0] = std.math.cos(rad);
                    ret.data[1] = -std.math.sin(rad);

                    ret.data[S] = std.math.sin(rad);
                    ret.data[S + 1] = std.math.cos(rad);
                    ret.fill_identity(2);
                },
                else => return Error.TransformationUndefined,
            }
            return ret;
        }
        /// Creates a shearing transformation matrix with specified shear factors in the x and y directions. The method checks if the matrix size is sufficient to support shearing (at least 2x2) and then fills the appropriate elements of the matrix based on the provided shear factors. The rest of the matrix is set to form an identity transformation for the unaffected dimensions. If shearing is not defined for the given matrix size, it returns an error.
        pub fn shear(x: T, y: T) Error!Self {
            if (S < 2) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = 1;
            ret.data[1] = y;
            ret.data[2] = 0;

            ret.data[S] = x;
            ret.data[S + 1] = 1;
            ret.data[S + 2] = 0;
            ret.fill_identity(2);
            return ret;
        }
        /// Creates a translation transformation matrix with specified translation distances in the x and y directions. The method checks if the matrix size is sufficient to support translation (at least 3x3) and then fills the appropriate elements of the matrix based on the provided translation distances. The rest of the matrix is set to form an identity transformation for the unaffected dimensions. If translation is not defined for the given matrix size, it returns an error.
        pub fn translate(x: T, y: T) Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = 1;
            ret.data[1] = 0;
            ret.data[2] = x;

            ret.data[S] = 0;
            ret.data[S + 1] = 1;
            ret.data[S + 2] = y;

            ret.data[2 * S] = 0;
            ret.data[2 * S + 1] = 0;
            ret.data[2 * S + 2] = 1;
            ret.fill_identity(3);
            return ret;
        }
        /// Creates an identity transformation matrix. This method checks if the matrix size is sufficient to support an identity transformation (at least 3x3) and then fills the diagonal elements with 1 and the off-diagonal elements with 0. If the matrix size is less than 3, it returns an error since an identity transformation is not defined for such matrices.
        pub fn identity() Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.fill_identity(0);
            return ret;
        }

        /// Creates a convolution kernel for edge detection. This method checks if the matrix size is sufficient to support a 3x3 kernel and then fills the elements of the matrix with the appropriate values for edge detection. The center element is set to 8, while the surrounding elements are set to -1. The rest of the matrix is set to form an identity transformation for any unaffected dimensions. If edge detection is not defined for the given matrix size, it returns an error.
        pub fn edge_detection() Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = -1;
            ret.data[1] = -1;
            ret.data[2] = -1;

            ret.data[S] = -1;
            ret.data[S + 1] = 8;
            ret.data[S + 2] = -1;

            ret.data[2 * S] = -1;
            ret.data[2 * S + 1] = -1;
            ret.data[2 * S + 2] = -1;
            ret.fill_identity(3);
            return ret;
        }

        /// Creates a convolution kernel for vertical edge detection. This method checks if the matrix size is sufficient to support a 3x3 kernel and then fills the elements of the matrix with the appropriate values for vertical edge detection. The center column is set to 0, while the left column is set to -1 and the right column is set to 1. The rest of the matrix is set to form an identity transformation for any unaffected dimensions. If vertical edge detection is not defined for the given matrix size, it returns an error.
        pub fn vertical_edge_detection() Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = -1;
            ret.data[1] = 0;
            ret.data[2] = 1;

            ret.data[S] = -1;
            ret.data[S + 1] = 0;
            ret.data[S + 2] = 1;

            ret.data[2 * S] = -1;
            ret.data[2 * S + 1] = 0;
            ret.data[2 * S + 2] = 1;
            ret.fill_identity(3);
            return ret;
        }
        /// Creates a convolution kernel for horizontal edge detection. This method checks if the matrix size is sufficient to support a 3x3 kernel and then fills the elements of the matrix with the appropriate values for horizontal edge detection. The center row is set to 0, while the top row is set to -1 and the bottom row is set to 1. The rest of the matrix is set to form an identity transformation for any unaffected dimensions. If horizontal edge detection is not defined for the given matrix size, it returns an error.
        pub fn horizontal_edge_detection() Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = -1;
            ret.data[1] = -1;
            ret.data[2] = -1;

            ret.data[S] = 0;
            ret.data[S + 1] = 0;
            ret.data[S + 2] = 0;

            ret.data[2 * S] = 1;
            ret.data[2 * S + 1] = 1;
            ret.data[2 * S + 2] = 1;
            ret.fill_identity(3);
            return ret;
        }
        /// Creates a convolution kernel for sharpening. This method checks if the matrix size is sufficient to support a 3x3 kernel and then fills the elements of the matrix with the appropriate values for sharpening. The center element is set to 4, while the surrounding elements are set to -1. The rest of the matrix is set to form an identity transformation for any unaffected dimensions. If sharpening is not defined for the given matrix size, it returns an error.
        pub fn sharpen() Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = 0;
            ret.data[1] = -1;
            ret.data[2] = 0;

            ret.data[S] = -1;
            ret.data[S + 1] = 4;
            ret.data[S + 2] = -1;

            ret.data[2 * S] = 0;
            ret.data[2 * S + 1] = -1;
            ret.data[2 * S + 2] = 0;
            ret.fill_identity(3);
            return ret;
        }
        /// Creates a convolution kernel for box blurring. This method checks if the matrix size is sufficient to support a 3x3 kernel and then fills the elements of the matrix with the appropriate values for box blurring. All elements in the 3x3 area are set to 1/9, which averages the values of the surrounding pixels. The rest of the matrix is set to form an identity transformation for any unaffected dimensions. If box blurring is not defined for the given matrix size, it returns an error.
        pub fn box_blur() Error!Self {
            if (S < 3) return Error.TransformationUndefined;
            var ret = Self{};
            ret.data[0] = 1.0 / 9.0;
            ret.data[1] = 1.0 / 9.0;
            ret.data[2] = 1.0 / 9.0;

            ret.data[S] = 1.0 / 9.0;
            ret.data[S + 1] = 1.0 / 9.0;
            ret.data[S + 2] = 1.0 / 9.0;

            ret.data[2 * S] = 1.0 / 9.0;
            ret.data[2 * S + 1] = 1.0 / 9.0;
            ret.data[2 * S + 2] = 1.0 / 9.0;
            ret.fill_identity(3);
            return ret;
        }
        /// Vectorizes a tuple or struct into a homogeneous coordinate vector. This method checks if the input argument is a struct and if it has the correct number of fields (one less than the matrix size). It then extracts the values from the struct fields and fills them into a vector, setting the last element to 1 for homogeneous coordinates. If the input argument is not a struct or does not have the correct number of fields, it returns an error.
        pub fn vectorize(args: anytype) Error!Vec {
            const ArgsType = @TypeOf(args);
            const args_type_info = @typeInfo(ArgsType);
            if (args_type_info != .@"struct") {
                @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
            }
            if (args_type_info.@"struct".fields.len != S - 1) {
                return Error.ArgError;
            }
            var res: Vec = undefined;
            inline for (0..args_type_info.@"struct".fields.len) |i| {
                res[i] = @field(args, args_type_info.@"struct".fields[i].name);
            }
            res[S - 1] = 1;
            //std.log.warn("vectorized {any}\n", .{res});
            return res;
        }
        /// Retrieves a specific row from the matrix as a vector. This method calculates the starting index of the desired row in the flat data array and then extracts the elements corresponding to that row into a vector. The resulting vector contains the values of the specified row, which can be used for operations like matrix-vector multiplication or for inspecting the contents of the matrix.
        pub fn row(self: *const Self, r: usize) Vec {
            return self.data[r * S .. r * S + S][0..S].*;
        }
        /// Transposes the matrix in place. This method iterates through the upper triangle of the matrix (excluding the diagonal) and swaps the elements with their corresponding elements in the lower triangle. By doing this, it effectively transposes the matrix without needing additional storage for a temporary matrix. The method ensures that each pair of elements is swapped only once, making it efficient for square matrices.
        pub fn transpose(self: *Self) void {
            for (0..S - 1) |i| {
                for (i + 1..S) |j| {
                    const temp = self.data[i * S + j];
                    self.data[i * S + j] = self.data[j * S + i];
                    self.data[j * S + i] = temp;
                }
            }
        }
        /// Multiplies the matrix by a vector. This method iterates through each row of the matrix, retrieves it as a vector, and then performs a dot product with the input vector to calculate the resulting vector. The output vector contains the results of the matrix-vector multiplication, which can be used for transformations or other operations that involve applying the matrix to a vector.
        pub fn mul_v(self: *const Self, v: Vec) Vec {
            var res: Vec = undefined;
            for (0..S) |i| {
                const mat_r: Vec = self.data[i * S .. i * S + S][0..S].*;
                res[i] = @reduce(.Add, mat_r * v);
            }
            //std.log.warn("matrix vector {any}\n", .{res});
            return res;
        }
        /// Multiplies the matrix by another matrix. This method implements the standard matrix multiplication algorithm, where each element of the resulting matrix is calculated as the dot product of the corresponding row from the first matrix and the corresponding column from the second matrix. The method iterates through each row and column, performing the necessary multiplications and additions to compute the final result. The output is a new matrix that represents the product of the two input matrices.
        pub fn mul(self: *const Self, other: Self) Self {
            return self.naive_mul(other);
        }
        //TODO reintegrate vector operations with 0.14
        // pub fn mul_by_col(self: *const Self, other: Self) Self {
        //     var res: Self = undefined;
        //     for (0..S) |i| {
        //         const mat_r: Vec = self.data[i * S .. i * S + S][0..S].*;
        //         for (0..S) |j| {
        //             var mat_c: Vec = undefined;
        //             for (0..S) |k| {
        //                 mat_c[k] = other.data[k * S + j];
        //             }
        //             res.data[i * S + j] = @reduce(.Add, mat_r * mat_c);
        //         }
        //     }
        //     std.log.debug("matrix matrix by col {any}\n", .{res.data});
        //     return res;
        // }
        // pub fn mul_by_row(self: *const Self, other: Self) Self {
        //     var res: Self = Self.init(.{0} ** (S * S));
        //     for (0..S) |i| {
        //         const mat_r: Vec = self.data[i * S .. i * S + S][0..S].*;
        //         for (0..S) |j| {
        //             const mat_other_r: Vec = other.data[j * S .. j * S + S][0..S].*;
        //             res.data[i * S .. i * S + S][0..S].* += mat_r * mat_other_r;
        //         }
        //     }
        //     std.log.debug("matrix matrix by row {any}\n", .{res.data});
        //     return res;
        // }
        pub fn naive_mul(self: *const Self, other: Self) Self {
            var res: Self = undefined;
            for (0..S) |i| {
                for (0..S) |j| {
                    res.data[i * S + j] = 0;
                    //std.debug.print("C{d}{d} = ", .{ i, j });
                    for (0..S) |k| {
                        //std.debug.print("{d} x {d}", .{ self.data[i * S + k], other.data[k * S + j] });
                        res.data[i * S + j] += self.data[i * S + k] * other.data[k * S + j];
                        if (k < S - 1) {
                            //std.debug.print(" + ", .{});
                        }
                    }
                    //std.debug.print(" = {d}\n", .{res.data[i * S + j]});
                }
            }
            //std.log.warn("matrix matrix {any}\n", .{res.data});
            return res;
        }
        pub fn naive_mul_v(self: *const Self, v: [S]f64) [S]f64 {
            var res: [S]f64 = undefined;
            for (0..S) |i| {
                res[i] = 0;
                for (0..S) |j| {
                    res[i] += self.data[i * S + j] * v[j];
                }
            }
            //std.log.warn("matrix vector {any}\n", .{res});
            return res;
        }
    };
}
