const std = @import("std");

pub const Graph = struct {
    pub const Node = struct {
        edges: *std.ArrayList(Edge),
        cost: u64 = undefined,
        indx: usize = undefined,
        pub fn init(allocator: std.mem.Allocator) !Node {
            const edges = try allocator.create(std.ArrayList(Edge));
            edges.* = std.ArrayList(Edge).init(allocator);
            return .{
                .edges = edges,
            };
        }
        pub fn add_edge(self: *Node, other: *Node, cost: u64) !void {
            try self.edges.append(Edge{
                .u = self,
                .v = other,
                .cost = cost,
            });
        }

        pub fn print(self: *const Node) void {
            std.debug.print("Node:\n\tLocation: {any}\n\tEdges:", .{self.indx});
            for (0..self.edges.items.len) |i| {
                std.debug.print("\n\t\tLocation: {any} {d}", .{ self.edges.items[i].v.indx, self.edges.items[i].cost });
            }
            std.debug.print("\n", .{});
        }
        pub fn deinit(self: *Node, allocator: std.mem.Allocator) void {
            self.edges.deinit();
            allocator.destroy(self.edges);
        }
        pub fn less_than(context: void, self: Node, other: Node) std.math.Order {
            _ = context;
            return std.math.order(self.cost, other.cost);
        }
    };
    pub const Edge = struct {
        u: *Node,
        v: *Node,
        cost: u64,
    };

    nodes: std.ArrayList(Node),
    allocator: std.mem.Allocator,
    dist: ?[]u64,
    prev: ?[]std.ArrayList(usize),
    paths: std.ArrayList(std.ArrayList(usize)),
    const INF = std.math.maxInt(u64);

    pub fn init(allocator: std.mem.Allocator) Graph {
        return Graph{
            .nodes = std.ArrayList(Node).init(allocator),
            .allocator = allocator,
            .dist = null,
            .prev = null,
            .paths = std.ArrayList(std.ArrayList(usize)).init(allocator),
        };
    }

    pub fn deinit(self: *Graph) void {
        for (0..self.nodes.items.len) |i| {
            self.nodes.items[i].deinit(self.allocator);
        }
        self.nodes.deinit();
        if (self.dist != null) {
            self.allocator.free(self.dist.?);
        }
        if (self.prev != null) {
            for (0..self.prev.?.len) |i| {
                self.prev.?[i].deinit();
            }
            self.allocator.free(self.prev.?);
        }
        for (0..self.paths.items.len) |i| {
            self.paths.items[i].deinit();
        }
        self.paths.deinit();
    }

    // creates a new a node and returns a pointer to it to allow for adding edges
    pub fn add_node(self: *Graph) std.mem.Allocator.Error!*Node {
        const indx = self.nodes.items.len;
        try self.nodes.append(try Node.init(self.allocator));
        self.nodes.items[indx].indx = indx;
        return &self.nodes.items[indx];
    }

    pub const DijkstraOptions = enum {
        All,
        Any,
    };
    pub fn dijkstra(self: *Graph, src: *Node, dest: *Node, comptime options: DijkstraOptions, build_path: bool) !u64 {
        if (self.dist == null) {
            self.dist = try self.allocator.alloc(u64, self.nodes.items.len);
        }
        if (self.prev == null) {
            self.prev = try self.allocator.alloc(std.ArrayList(usize), self.nodes.items.len);
            for (0..self.prev.?.len) |i| {
                self.prev.?[i] = std.ArrayList(usize).init(self.allocator);
            }
        }
        for (0..self.dist.?.len) |i| {
            self.dist.?[i] = INF;
        }
        for (0..self.prev.?.len) |i| {
            self.prev.?[i].clearRetainingCapacity();
        }

        var prio_q = std.PriorityQueue(Node, void, Node.less_than).init(self.allocator, {});
        defer prio_q.deinit();

        self.dist.?[src.indx] = 0;
        try prio_q.add(Node{
            .edges = self.nodes.items[src.indx].edges,
            .cost = 0,
            .indx = src.indx,
        });
        while (prio_q.items.len > 0) {
            const u = prio_q.remove();
            if (options == .Any) {
                if (u.indx == dest.indx) break;
            }
            for (u.edges.items) |edge| {
                const new_cost = u.cost + edge.cost;
                if (new_cost < self.dist.?[edge.v.indx]) {
                    self.dist.?[edge.v.indx] = new_cost;
                    self.prev.?[edge.v.indx].clearRetainingCapacity();
                    try self.prev.?[edge.v.indx].append(u.indx);
                    try prio_q.add(Node{
                        .edges = self.nodes.items[edge.v.indx].edges,
                        .cost = new_cost,
                        .indx = edge.v.indx,
                    });
                } else if (new_cost == self.dist.?[edge.v.indx]) {
                    if (options == .All) {
                        try self.prev.?[edge.v.indx].append(u.indx);
                    }
                }
            }
        }
        if (build_path) {
            try self.trace_path(dest.indx);
        }
        return self.dist.?[dest.indx];
    }

    pub fn trace_path(self: *Graph, curr: u64) !void {
        for (0..self.paths.items.len) |i| {
            self.paths.items[i].clearAndFree();
        }
        self.paths.clearRetainingCapacity();
        try self.paths.append(std.ArrayList(usize).init(self.allocator));
        try self.trace_path_helper(&self.paths.items[self.paths.items.len - 1], curr);
    }

    pub fn trace_path_helper(self: *Graph, path: *std.ArrayList(usize), curr: u64) !void {
        if (self.prev.?[curr].items.len == 0) return;
        const start_len = path.items.len;
        for (0..self.prev.?[curr].items.len) |i| {
            if (i != 0) {
                try self.paths.append(std.ArrayList(usize).init(self.allocator));
                var dupe = &self.paths.items[self.paths.items.len - 1];
                if (start_len > 0) {
                    try dupe.appendSlice(path.items[0..start_len]);
                }
                try dupe.insert(0, self.prev.?[curr].items[i]);
                try self.trace_path_helper(&self.paths.items[self.paths.items.len - 1], self.prev.?[curr].items[i]);
            } else {
                try path.insert(0, self.prev.?[curr].items[i]);
                try self.trace_path_helper(path, self.prev.?[curr].items[i]);
            }
        }
    }

    pub fn trace_path_nodes_exist_helper(self: *const Graph, visited: []bool, curr: u64, node1: u64, node2: u64, node1_exists: *bool, node2_exists: *bool) bool {
        if (node1_exists.* and node2_exists.*) return true;
        if (visited[curr]) return false;
        visited[curr] = true;
        if (curr == node1) node1_exists.* = true;
        if (curr == node2) node2_exists.* = true;
        for (0..self.prev.?[curr].items.len) |i| {
            const result = self.trace_path_nodes_exist_helper(visited, self.prev.?[curr].items[i], node1, node2, node1_exists, node2_exists);
            if (result) return true;
        }
        return false;
    }
    pub fn trace_path_nodes_exist(self: *const Graph, curr: u64, node1: u64, node2: u64) !bool {
        var node1_exists = false;
        var node2_exists = false;
        var visited: []bool = try self.allocator.alloc(bool, self.prev.?.len);
        for (0..visited.len) |i| {
            visited[i] = false;
        }
        defer self.allocator.free(visited);
        return self.trace_path_nodes_exist_helper(visited, curr, node1, node2, &node1_exists, &node2_exists);
    }

    pub fn a_star(self: *Graph, src: *Node, dest: *Node, comptime heuristic: fn (node: *const Node, goal: *const Node) u64, build_path: bool) !u64 {
        if (self.dist == null) {
            self.dist = try self.allocator.alloc(u64, self.nodes.items.len);
        }
        if (self.prev == null) {
            self.prev = try self.allocator.alloc(std.ArrayList(usize), self.nodes.items.len);
            for (0..self.prev.?.len) |i| {
                self.prev.?[i] = std.ArrayList(usize).init(self.allocator);
            }
        }
        for (0..self.dist.?.len) |i| {
            self.dist.?[i] = INF;
        }

        for (0..self.prev.?.len) |i| {
            self.prev.?[i].clearRetainingCapacity();
        }

        var prio_q = std.PriorityQueue(Node, void, Node.less_than).init(self.allocator, {});
        defer prio_q.deinit();
        self.dist.?[src.indx] = 0;
        try prio_q.add(Node{
            .edges = self.nodes.items[src.indx].edges,
            .cost = heuristic(src, dest),
            .indx = src.indx,
        });
        while (prio_q.items.len > 0) {
            const u = prio_q.remove();
            if (u.indx == dest.indx) break;
            for (u.edges.items) |edge| {
                const new_cost = self.dist.?[u.indx] + edge.cost;
                const estimated_cost = new_cost + heuristic(edge.v, dest);
                if (new_cost < self.dist.?[edge.v.indx]) {
                    self.dist.?[edge.v.indx] = new_cost;
                    self.prev.?[edge.v.indx].clearRetainingCapacity();
                    try self.prev.?[edge.v.indx].append(u.indx);
                    try prio_q.add(Node{
                        .edges = self.nodes.items[edge.v.indx].edges,
                        .cost = estimated_cost,
                        .indx = edge.v.indx,
                    });
                } else if (new_cost == self.dist.?[edge.v.indx]) {
                    try self.prev.?[edge.v.indx].append(u.indx);
                }
            }
        }
        if (build_path) {
            try self.trace_path(dest.indx);
        }
        return self.dist.?[dest.indx];
    }
};

test "add nodes" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var graph = Graph.init(allocator);
    var node_a = try graph.add_node();
    var node_b = try graph.add_node();
    var node_c = try graph.add_node();
    var node_d = try graph.add_node();

    try node_a.add_edge(node_b, 1);
    try node_a.add_edge(node_c, 3);
    try node_b.add_edge(node_c, 1);
    try node_c.add_edge(node_d, 3);

    try node_b.add_edge(node_a, 1);
    try node_c.add_edge(node_a, 3);
    try node_c.add_edge(node_b, 1);
    try node_d.add_edge(node_c, 3);
    for (graph.nodes.items) |node| {
        node.print();
    }
    const cost = try graph.dijkstra(node_a, node_d, .Any, true);
    std.log.warn("{d} ", .{cost});
    std.log.warn("{any}", .{graph.paths.items[0].items});
    graph.deinit();
    if (gpa.deinit() == .leak) {
        std.log.warn("Leaked!\n", .{});
    }
}
