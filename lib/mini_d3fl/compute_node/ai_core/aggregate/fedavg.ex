defmodule FedAvg do
  def average(maps) when is_list(maps) and length(maps) > 0 do
    # Get the total count of maps
    map_count = maps |> Enum.reject(fn item -> item == %{} or item == nil end)
                      |> length()

    # Accumulate all maps into a single map with summed values
    summed_map =
      Enum.reduce(maps, %{}, fn map, acc ->
        Map.merge(acc, map, fn _key, val1, val2 ->
          merge_nested(val1, val2)
        end)
      end)

    # Divide each value by the count to get the average
    Enum.into(summed_map, %{}, fn {key, value} ->
      {key, divide_nested(value, map_count)}
    end)
  end

  # Helper function to merge nested maps (e.g., {"bias", "kernel"})
  defp merge_nested(val1, val2) when is_map(val1) and is_map(val2) do
    Map.merge(val1, val2, fn _key, v1, v2 -> Nx.add(v1, v2) end)
  end
  defp merge_nested(val1, val2), do: Nx.add(val1, val2)

  # Helper function to divide nested maps
  defp divide_nested(value, divisor) when is_map(value) do
    Enum.into(value, %{}, fn {key, val} -> {key, Nx.divide(val, divisor)} end)
  end
  defp divide_nested(value, divisor), do: Nx.divide(value, divisor)
end
