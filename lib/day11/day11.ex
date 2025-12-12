defmodule Day11 do
  def part1(input) do
    graph =
      input
      |> parse_input()
      |> Graph.from_edges(:directed)

    sorted_nodes = topological_sort(graph)

    graph
    |> count_paths(sorted_nodes, :you, :out)
  end

  def part2(input) do
    graph =
      input
      |> parse_input()
      |> Graph.from_edges(:directed)

    sorted_nodes = topological_sort(graph)

    graph
    |> count_paths_with_required_nodes(sorted_nodes, :svr, :out)
  end

  # Basic input parsing abstracted out for both parts
  defp parse_input(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.flat_map(fn line ->
      [from_str, rest] = String.split(line, ": ", parts: 2)
      from = String.to_atom(from_str)

      rest
      |> String.split(" ", trim: true)
      |> Enum.map(fn to_str ->
        {from, String.to_atom(to_str)}
      end)
    end)
  end

  # Topological sort orders nodes so that, for every directed edge a->b,
  # node b appears earlier in the list than node a. This is the reverse of
  # the typical topological order (where a appears earlier than b). This is
  # done intentionally to ensure each node is processed only after all paths
  # flowing into it have been handled.
  #
  # Topological sort only works on directed graphs because if there's an
  # edge from a->b, and some way of getting back to a from b, then you can't
  # choose which node appears earlier in the sorted list. Many systems use this
  # to ensure proper handling of dependencies (such as in code package tools).
  defp topological_sort(graph) do
    {order, _} =
      Enum.reduce(Map.keys(graph), {[], MapSet.new()}, fn node, {order, visited} ->
        topological_dfs(graph, node, order, visited)
      end)

    order
  end

  # To achieve this, we use DFS to visit all outgoing neighbours of a node first.
  # A node is added to the order only after all such neighbours have been
  # processed, so nodes that appear later in the graph appear earlier in the
  # resulting list.
  defp topological_dfs(graph, node, order, visited) do
    if node in visited do
      {order, visited}
    else
      visited = MapSet.put(visited, node)

      {order, visited} =
        graph
        |> Map.get(node, [])
        |> Enum.reduce({order, visited}, fn adjacent_node, {order, visited} ->
          topological_dfs(graph, adjacent_node, order, visited)
        end)

      {[node | order], visited}
    end
  end

  # Count directed paths from start_node to target_node.
  #
  # The graph is processed in topological order, and for each node we track the
  # number of paths that reach it. Because the graph is directed with no cycles,
  # and we've topologically sorted the nodes, all paths leading into a node
  # contribute to the count by the time the current node is processed.
  #
  # The primary performance boost from a traditional "just traverse all paths and
  # count" method is that we don't need to keep track of each path in the state.
  # The outer reduce is over all nodes, giving us a linear runtime to start. The
  # inner reduce is simply over each edge of the current node. This collapses an
  # exponential runtime (O(# of paths)) to a linear runtime (O(# of edges))
  defp count_paths(graph, sorted_nodes, start_node, target_node) do
    path_counts_initial = %{start_node => 1}

    path_counts_final =
      Enum.reduce(sorted_nodes, path_counts_initial, fn node, path_counts ->
        ways_here = Map.get(path_counts, node, 0)
        outgoing_nodes = Map.get(graph, node)

        Enum.reduce(outgoing_nodes, path_counts, fn adjacent_node, path_counts ->
          Map.update(path_counts, adjacent_node, ways_here, fn existing_count ->
            existing_count + ways_here
          end)
        end)
      end)

    Map.get(path_counts_final, target_node, 0)
  end

  # This constant represents the different types of paths from svr->out we can have:
  #   - Does not contain either required node
  #   - Contains the first required node but not the second
  #   - Contains the second required node but not the first
  #   - Contains both required nodes
  #
  # It is used in count_paths_with_required_nodes below
  @path_types [{false, false}, {true, false}, {false, true}, {true, true}]

  # Count directed paths from start_node to target_node that pass through both
  # required nodes.
  #
  # This follows the same strategy as count_paths/4 in tracking path counts
  # rather than the paths themselves.
  #
  # The difference is that, instead of tracking a single count per node, we track
  # a small fixed set of path states per node indicating whether the path has
  # already seen each required node (see above). Paths that reach the same node
  # with the same state are collapsed into a single count.
  #
  # This preserves the linear runtime of the simpler algorithm because the
  # path_types are a small fixed number, and therefore do not contribute to any
  # increase in time complexity, while allowing paths to be filtered by additional
  # constraints.
  defp count_paths_with_required_nodes(graph, sorted_nodes, start_node, target_node) do
    required_a = :dac
    required_b = :fft

    initial_seen_a = start_node == required_a
    initial_seen_b = start_node == required_b

    path_counts_initial = %{{start_node, initial_seen_a, initial_seen_b} => 1}

    path_counts_final =
      Enum.reduce(sorted_nodes, path_counts_initial, fn node, path_counts ->
        outgoing_nodes = Map.get(graph, node)

        Enum.reduce(@path_types, path_counts, fn {seen_a, seen_b}, path_counts ->
          state = {node, seen_a, seen_b}
          ways_here = Map.get(path_counts, state, 0)

          seen_a = seen_a or node == required_a
          seen_b = seen_b or node == required_b

          Enum.reduce(outgoing_nodes, path_counts, fn adjacent_node, path_counts ->
            next_state = {adjacent_node, seen_a, seen_b}

            Map.update(path_counts, next_state, ways_here, fn existing_count ->
              existing_count + ways_here
            end)
          end)
        end)
      end)

    Map.get(path_counts_final, {target_node, true, true}, 0)
  end
end
