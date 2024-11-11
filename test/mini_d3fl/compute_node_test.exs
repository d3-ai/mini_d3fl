defmodule MiniD3fl.ComputeNodeTest do
  use ExUnit.Case
  doctest MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.InitArgs
  alias MiniD3fl.ComputeNode

  test "should init with proper state" do
    args = %ComputeNode.InitArgs{node_id: nil,
                      model: nil,
                      data: nil}

    {value, pid}  = ComputeNode.start_link(args)
    assert value == :ok
  end

end
