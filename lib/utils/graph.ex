defmodule Graph do
  @moduledoc false

  def new(), do: %{}

  @doc """
  Builds an undirected graph from a list of `{a, b}` edges.

  ## Examples

      iex> Graph.from_edges([{:a, :b}, {:b, :c}])
      %{a: [:b], b: [:c, :a], c: [:b]}

  """
  def from_edges(edge_list) do
    Enum.reduce(edge_list, new(), fn {a, b}, graph ->
      graph
      |> add_edge(a, b)
      |> add_edge(b, a)
    end)
  end

  @doc """
  Builds a directed graph from a list of `{a, b}` edges.

  ## Examples

      iex> Graph.from_edges([{:a, :b}, {:b, :c}], :directed)
      %{a: [:b], b: [:c], c: []}

  """
  def from_edges(edge_list, :directed) do
    Enum.reduce(edge_list, new(), fn {a, b}, graph ->
      graph
      |> add_edge(a, b)
    end)
  end

  @doc """
  Adds `node` to `graph`, unless it's already present

  ## Examples

      iex> Graph.add_node(%{}, :x)
      %{x: []}

  """
  def add_node(graph, node) do
    Map.put_new(graph, node, [])
  end

  @doc """
  Adds an edge from `a` to `b`.

  ## Examples

      iex> Graph.add_edge(%{}, :a, :b)
      %{a: [:b], b: []}

  """
  def add_edge(graph, a, b) do
    graph
    |> add_node(a)
    |> add_node(b)
    |> Map.update!(a, fn neighbors ->
      insert_unique(neighbors, b)
    end)
  end

  defp insert_unique(list, item) do
    if item in list, do: list, else: [item | list]
  end

  @doc """
  Returns all neighbors of `node`.

  ## Examples

      iex> g = Graph.from_edges([{:a, :b}, {:a, :c}])
      iex> Graph.neighbors(g, :a) |> Enum.sort()
      [:b, :c]

  """
  def neighbors(graph, node), do: Map.get(graph, node, [])

  @doc """
  Returns the list of nodes in the graph.

  ## Examples

      iex> g = Graph.from_edges([{:a, :b}, {:b, :c}])
      iex> Graph.nodes(g) |> Enum.sort()
      [:a, :b, :c]

  """
  def nodes(graph), do: Map.keys(graph)

  @doc """
  Performs BFS and returns a map of `{node => distance_from_start}`.

  ## Examples

      iex> g = Graph.from_edges([{:a, :b}, {:b, :c}, {:c, :d}])
      iex> Graph.bfs_distances(g, :a)
      %{a: 0, b: 1, c: 2, d: 3}

  """
  def bfs_distances(graph, start) do
    queue = :queue.in(start, :queue.new())
    bfs_loop(graph, queue, MapSet.new([start]), %{start => 0})
  end


  defp bfs_loop(graph, queue, visited, distances) do
    case :queue.out(queue) do
      {:empty, _queue} ->
        distances

      {{:value, node}, queue} ->
        dist = distances[node]

        {queue, visited, distances} =
          Enum.reduce(neighbors(graph, node), {queue, visited, distances}, fn nbr,
                                                                              {queue, visited, distmap} ->
            if nbr in visited do
              {queue, visited, distmap}
            else
              {
                :queue.in(nbr, queue),
                MapSet.put(visited, nbr),
                Map.put(distmap, nbr, dist + 1)
              }
            end
          end)

        bfs_loop(graph, queue, visited, distances)
    end
  end

  @doc """
  Depth-first search starting at `start`, returning the visit order.

  ## Examples

      iex> g = Graph.from_edges([{:a, :b}, {:a, :c}, {:b, :d}])
      iex> Graph.dfs(g, :a)
      [:a, :c, :b, :d]

  """
  def dfs(graph, start) do
    {_visited, acc} = dfs_loop(graph, start, MapSet.new(), [])
    Enum.reverse(acc)
  end

  defp dfs_loop(graph, node, visited, acc) do
    if node in visited do
      {visited, acc}
    else
      visited = MapSet.put(visited, node)
      acc = [node | acc]

      Enum.reduce(neighbors(graph, node), {visited, acc}, fn nbr, {v, a} ->
        dfs_loop(graph, nbr, v, a)
      end)
    end
  end
end
