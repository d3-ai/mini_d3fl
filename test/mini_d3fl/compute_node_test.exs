defmodule MiniD3fl.ComputeNodeTest do
  use ExUnit.Case
  doctest MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.TrainArgs
  alias MiniD3fl.ComputeNode.InitArgs
  alias MiniD3fl.ComputeNode

  setup do
    node_id = 1
    args = %InitArgs{node_id: node_id,
                      model: nil,
                      data: nil,
                      availability: true
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    %{node_id: node_id}
  end


  test "should train with proper state", %{node_id: node_id} do
    train_results = ComputeNode.train(%TrainArgs{node_id: node_id})
    assert train_results == :train_results
  end

  test "should tuggle availability", %{node_id: node_id} do
    assert ComputeNode.is_available(node_id) == true
    ComputeNode.become_unavailable(node_id)
    assert ComputeNode.is_available(node_id) == false
    ComputeNode.become_available(node_id)
    assert ComputeNode.is_available(node_id) == true
  end

end
