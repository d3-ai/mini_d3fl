defmodule MiniD3fl.ComputeNodeTest do
  use ExUnit.Case
  doctest MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.TrainArgs
  alias MiniD3fl.ComputeNode.InitArgs
  alias MiniD3fl.ComputeNode

  test "should init with proper state" do
    args = %InitArgs{node_id: nil,
                      model: nil,
                      data: nil}

    {value, _pid}  = ComputeNode.start_link(args)
    assert value == :ok
  end

  test "should train with proper state" do
    args = %InitArgs{node_id: 1,
                      model: nil,
                      data: nil}

    {value, _pid}  = ComputeNode.start_link(args)
    assert value == :ok

    train_results = ComputeNode.train(%TrainArgs{node_id: 1})
    assert train_results == :train_results
  end

end
