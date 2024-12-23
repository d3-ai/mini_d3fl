defmodule MiniD3fl.ChannelTest do
  use ExUnit.Case
  doctest MiniD3fl.Channel
  alias MiniD3fl.Channel
  alias MiniD3fl.Channel.ChannelArgs
  alias MiniD3fl.Channel.QoS
  alias MiniD3fl.ComputeNode.Model
  alias MiniD3fl.JobController
  alias MiniD3fl.JobController.EventQueue
  alias MiniD3fl.Utils

  setup do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 1,
                      capacity: 100}

    init_args = %ChannelArgs{
                  from_cn_id: 10,
                  to_cn_id: 20,
                  QoS: input_qos}

    {:ok, _pid} = Channel.start_link(init_args)


    JobController.start_link(
      %{job_controller_id: 0,
      init_event_queue: EventQueue.init_queue})

    {:ok, cn_from_id: 10, cn_to_id: 20}
  end


  test "should not receive model over the limit of capacity", %{cn_from_id: fid, cn_to_id: tid} do
    model = %Model{size: 1000,
                  plain_model: nil}
    {:warning, string} = Channel.recv_model_at_channel(fid, tid, model, 10)
    assert string == "over_the_limit"
    GenServer.stop(Utils.get_process_name(JobController, 0), :normal, :infinity)
    GenServer.stop(Utils.get_channel_name(fid, tid), :normal, :infinity)
  end

  test "should not receive model due to packetloss", %{cn_from_id: fid, cn_to_id: tid} do
    model = %Model{size: 50,
                  plain_model: nil}
    {:warning, string} = Channel.recv_model_at_channel(fid, tid, model, 10)
    assert string == "paket loss"
    GenServer.stop(Utils.get_process_name(JobController, 0), :normal, :infinity)
    GenServer.stop(Utils.get_channel_name(fid, tid), :normal, :infinity)
  end

  test "should receive models and increment the state" do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}

    fid = 100
    tid = 200
    init_args = %ChannelArgs{
                  from_cn_id: fid,
                  to_cn_id: tid,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)

    JobController.start_link(
      %{job_controller_id: 0,
      init_event_queue: EventQueue.init_queue})


    model1 = %Model{size: 50,
                  plain_model: nil}
    model2 = %Model{size: 40,
                  plain_model: nil}
    :ok = Channel.recv_model_at_channel(fid, tid, model1, 10)
    :ok = Channel.recv_model_at_channel(fid, tid, model2, 20)
    %Channel.State{queue: queue, model_sum_size: size} = Channel.get_state(fid, tid)

    queue_desired = :queue.new()
    queue_desired = :queue.in(model1, queue_desired)
    queue_desired = :queue.in(model2, queue_desired)

    assert queue == queue_desired
    assert size == 90
    GenServer.stop(Utils.get_process_name(JobController, 0), :normal, :infinity)
    GenServer.stop(Utils.get_channel_name(fid, tid), :normal, :infinity)
  end

  test "should receive models until limit is reached" do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}
    fid = 100
    tid = 200
    init_args = %ChannelArgs{
                  from_cn_id: fid,
                  to_cn_id: tid,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)

    JobController.start_link(
      %{job_controller_id: 0,
      init_event_queue: EventQueue.init_queue})

    model1 = %Model{size: 50,
                  plain_model: nil}
    model2 = %Model{size: 40,
                  plain_model: nil}
    model3 = %Model{size: 30,
                  plain_model: nil}
    :ok = Channel.recv_model_at_channel(fid, tid, model1, 10)
    :ok = Channel.recv_model_at_channel(fid, tid, model2, 20)
    {:warning, "over_the_limit"} = Channel.recv_model_at_channel(fid, tid, model3, 30)
    %Channel.State{queue: queue, model_sum_size: size} = Channel.get_state(fid, tid)

    queue_desired = :queue.new()
    queue_desired = :queue.in(model1, queue_desired)
    queue_desired = :queue.in(model2, queue_desired)

    assert queue == queue_desired
    assert size == 90
    GenServer.stop(Utils.get_process_name(JobController, 0), :normal, :infinity)
    GenServer.stop(Utils.get_channel_name(fid, tid), :normal, :infinity)
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

  test "should change channel params" do
    input_qos = %QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}
    fid = 100
    tid = 200
    init_args = %ChannelArgs{
                  from_cn_id: fid,
                  to_cn_id: tid,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)

    Channel.change_channel_params(%ChannelArgs{init_args | QoS: %Channel.QoS{packetloss: 1}})
    state = Channel.get_state(fid, tid)
    IO.inspect state

    %Channel.State{QoS: qos} = state
    IO.inspect qos

    %Channel.QoS{packetloss: pkl} = qos
    assert pkl == 1
  end

end
