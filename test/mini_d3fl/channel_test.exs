defmodule MiniD3fl.ChannelTest do
  use ExUnit.Case
  doctest MiniD3fl.Channel
  alias MiniD3fl.Channel
  alias MiniD3fl.Channel.InitArgs
  alias MiniD3fl.Channel.QoS
  alias MiniD3fl.ComputeNode.Model

  setup do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 1,
                      capacity: 100}

    init_args = %InitArgs{channel_id: 1,
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, pid} = Channel.start_link(init_args)
    {:ok, pid: pid}
  end


  test "should not receive model over the limit of capacity", %{pid: channel_pid} do
    model = %Model{size: 1000,
                  plain_model: nil}
    {:warning, string} = Channel.recv_model_at_channel(channel_pid, model)
    assert string == "over_the_limit"
  end

  test "should not receive model due to packetloss", %{pid: channel_pid} do
    model = %Model{size: 50,
                  plain_model: nil}
    {:warning, string} = Channel.recv_model_at_channel(channel_pid, model)
    assert string == "paket loss"
  end

  test "should receive models and increment the state" do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}

    init_args = %InitArgs{channel_id: 1,
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, channel_pid} = Channel.start_link(init_args)

    model1 = %Model{size: 50,
                  plain_model: nil}
    model2 = %Model{size: 40,
                  plain_model: nil}
    :ok = Channel.recv_model_at_channel(channel_pid, model1)
    :ok = Channel.recv_model_at_channel(channel_pid, model2)
    %Channel.State{queue: queue, model_sum_size: size} = Channel.get_state(channel_pid)

    queue_desired = :queue.new()
    queue_desired = :queue.in(model1, queue_desired)
    queue_desired = :queue.in(model2, queue_desired)

    assert queue == queue_desired
    assert size == 90
  end

  test "should receive models until limit is reached" do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}

    init_args = %InitArgs{channel_id: 1,
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, channel_pid} = Channel.start_link(init_args)

    model1 = %Model{size: 50,
                  plain_model: nil}
    model2 = %Model{size: 40,
                  plain_model: nil}
    model3 = %Model{size: 30,
                  plain_model: nil}
    :ok = Channel.recv_model_at_channel(channel_pid, model1)
    :ok = Channel.recv_model_at_channel(channel_pid, model2)
    {:warning, "over_the_limit"} = Channel.recv_model_at_channel(channel_pid, model3)
    %Channel.State{queue: queue, model_sum_size: size} = Channel.get_state(channel_pid)

    queue_desired = :queue.new()
    queue_desired = :queue.in(model1, queue_desired)
    queue_desired = :queue.in(model2, queue_desired)

    assert queue == queue_desired
    assert size == 90
  end

  test "should have correct packetloss rate" do
    num = 0.2
    rep = 10000
    sum = Enum.reduce(1..rep, 0, fn _x, acc ->
      if Channel.is_loss_packet(num), do: acc + 1, else: acc + 0
    end)
    assert sum/rep <= num + num/10
    assert sum/rep >= num - num/10
  end

end
