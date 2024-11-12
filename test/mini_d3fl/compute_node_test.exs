defmodule MiniD3fl.ComputeNodeTest do
  use ExUnit.Case
  doctest MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.TrainArgs
  alias MiniD3fl.ComputeNode.InitArgs
  alias MiniD3fl.ComputeNode.Model
  alias MiniD3fl.Channel

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

  def cn_setup(node_id) do
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

  test "should receive model from channel", %{node_id: node_id} do
    cn_setup(10)
    cn_setup(20)

    # Channelの初期設定
    # TODO: 関数化して切り出す（channel_testの中の共通部分も）

    input_qos = %Channel.QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}

    init_args = %Channel.InitArgs{channel_id: 1,
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, channel_pid} = Channel.start_link(init_args)
    model1 = %Model{size: 50, plain_model: "sample_plain_model"}
    :ok = Channel.recv_model_at_channel(channel_pid, model1)
    :ok = Channel.send_model_from_channel(channel_pid)

    %ComputeNode.State{receive_model: recv_model} = ComputeNode.get_state(20)
    assert recv_model == model1
  end

  test "receive model from ComputeNode to ComputeNode" do

  end

end
