const std = @import("std");

/// A simple graph implementation with Dijkstra's and A* algorithms. The graph is represented as an adjacency list, where each node maintains a list of its edges. Each edge contains a reference to the neighboring node and the cost of traversing that edge. The graph also includes methods for adding nodes and edges, as well as for performing Dijkstra's and A* pathfinding algorithms. The implementation allows for both finding any shortest path and finding all shortest paths between two nodes, depending on the options provided to the algorithms.
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
        /// Adds an edge from the current node to another node with a specified cost. This method takes a pointer to the neighboring node and the cost of the edge as arguments. It creates a new Edge struct with the current node as the source (u), the neighboring node as the destination (v), and the specified cost. The new edge is then appended to the list of edges for the current node, allowing for multiple edges to be added between nodes if needed.
        pub fn add_edge(self: *Node, other: *Node, cost: u64) !void {
            try self.edges.append(Edge{
                .u = self,
                .v = other,
                .cost = cost,
            });
        }

        /// Prints the node's index and its edges with their costs. This method is useful for debugging and visualizing the structure of the graph. It iterates through the list of edges for the node and prints the index of the neighboring node along with the cost of the edge connecting them. The output is formatted to clearly show the relationships between nodes and their connections in the graph.
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
    /// Adds a new node to the graph and returns a pointer to it. This method initializes a new Node struct using the provided allocator and appends it to the list of nodes in the graph. The index of the new node is set based on its position in the list, allowing for easy reference when adding edges or performing pathfinding operations. The method returns a pointer to the newly added node, which can then be used to create edges or for other graph operations.
    pub fn add_node(self: *Graph) std.mem.Allocator.Error!*Node {
        const indx = self.nodes.items.len;
        try self.nodes.append(try Node.init(self.allocator));
        self.nodes.items[indx].indx = indx;
        return &self.nodes.items[indx];
    }

    /// Option for Dijkstra's algorithm to specify whether to find any shortest path or all shortest paths between the source and destination nodes. The `All` option indicates that the algorithm should find all shortest paths, while the `Any` option indicates that it should stop after finding the first shortest path. This allows for flexibility in how the algorithm is used,
    /// depending on whether the user is interested in just one optimal solution or all possible optimal solutions.
    pub const DijkstraOptions = enum {
        All,
        Any,
    };

    /// Implements Dijkstra's algorithm to find the shortest path from a source node to a destination node.
    /// The method takes pointers to the source and destination nodes,
    /// as well as options for whether to find any shortest path or all shortest paths,
    /// and a boolean indicating whether to build the path after finding the shortest distance.
    /// It initializes the distance and previous node arrays,
    /// uses a priority queue to explore the graph,
    /// and updates distances and paths as it traverses.
    /// If the build_path option is true, it calls the trace_path method to construct the actual paths from the source to the destination.
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

    /// Traces back the paths from the destination node to the source node using the previous node information stored during the execution of Dijkstra's or A* algorithm. This method clears any existing paths and then recursively builds new paths by following the previous nodes from the destination back to the source. It uses a helper method, trace_path_helper, to perform the recursive tracing and construct the paths in a way that allows for multiple paths to be stored if there are multiple shortest paths between the source and destination.
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
    /// Checks if both node1 and node2 exist in any of the paths from the source to the destination. This method initializes a visited array to keep track of which nodes have been visited during the traversal. It then calls a helper method, trace_path_nodes_exist_helper, which recursively checks each path from the current node back to the source node to see if both node1 and node2 are present. The method returns true if both nodes are found in any path, and false otherwise.
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

    /// Implements the A* algorithm to find the shortest path from a source node to a destination node using a heuristic function. The method takes pointers to the source and destination nodes, a compile-time heuristic function that estimates the cost from a node to the goal,
    /// and a boolean indicating whether to build the path after finding the shortest distance.
    /// It initializes the distance and previous node arrays, uses a priority queue to explore the graph while considering both the actual cost from the source and the estimated cost to the destination, and updates distances and paths as it traverses.
    /// If the build_path option is true, it calls the trace_path method to construct the actual paths from the source to the destination.
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
