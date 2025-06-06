defmodule MiniD3fl.ComputeNodeTest do
  use ExUnit.Case
  doctest MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode
  alias MiniD3fl.ComputeNode.TrainArgs
  alias MiniD3fl.ComputeNode.InitArgs
  alias MiniD3fl.ComputeNode.Model
  alias MiniD3fl.Channel
  alias MiniD3fl.JobController
  alias MiniD3fl.JobController.EventQueue
  alias MiniD3fl.Utils

  setup do
    node_id = 1
    args = %InitArgs{node_id: node_id,
                      data: nil,
                      availability: true,
                      node_num: 2
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    JobController.start_link(
      %{job_controller_id: 0,
      init_event_queue: EventQueue.init_queue})

    %{node_id: node_id}
  end

  def cn_setup(node_id) do
    args = %InitArgs{node_id: node_id,
                      node_num: 20,
                      data: nil,
                      availability: true
                    }

    {:ok, _pid}  = ComputeNode.start_link(args)
    %{node_id: node_id}
  end

  @tag timeout: :infinity
  test "should train with proper state", %{node_id: node_id} do
    ComputeNode.train(%TrainArgs{node_id: node_id})
    assert true
    GenServer.stop(Utils.get_process_name(ComputeNode, node_id), :normal, :infinity)
  end

  test "should tuggle availability", %{node_id: node_id} do
    assert ComputeNode.is_available(node_id) == true
    ComputeNode.become_unavailable(node_id)
    assert ComputeNode.is_available(node_id) == false
    ComputeNode.become_available(node_id)
    assert ComputeNode.is_available(node_id) == true
    GenServer.stop(Utils.get_process_name(ComputeNode, node_id), :normal, :infinity)
  end

  test "should receive model from channel", %{node_id: _node_id} do
    cn_setup(10)
    cn_setup(20)

    # Channelの初期設定
    # TODO: 関数化して切り出す（channel_testの中の共通部分も）

    input_qos = %Channel.QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}
    fid = 10
    tid = 20
    init_args = %Channel.ChannelArgs{
                  from_cn_id: fid,
                  to_cn_id: tid,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)
    model1 = %Model{size: 50, plain_model: "sample_plain_model"}
    :ok = Channel.recv_model_at_channel(fid, tid, model1, 10)
    :ok = Channel.send_model_from_channel(fid, tid, 20)

    %ComputeNode.State{receive_model_list: recv_model} = ComputeNode.get_state(20)
    assert recv_model == [model1.plain_model]

    %Channel.State{queue: queue, model_sum_size: model_sum_size} = Channel.get_state(fid, tid)
    empty_queue =  {[], []}
    assert queue == empty_queue
    assert model_sum_size == 0

    GenServer.stop(Utils.get_process_name(ComputeNode, 10), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 20), :normal, :infinity)
  end

  test "should not receive model when receiver CN is unavailable" do
    # ComputeNode の初期化
    cn_setup(10)
    cn_setup(20)

    # JobController の初期化
    JobController.start_link(
      %{job_controller_id: 0,
      init_event_queue: EventQueue.init_queue})

    # 受け取り側の availability を falseにする

    ComputeNode.become_unavailable(20)

    # Channelの初期設定
    # TODO: 関数化して切り出す（channel_testの中の共通部分も）

    input_qos = %Channel.QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}
    fid = 10
    tid = 20
    init_args = %Channel.ChannelArgs{
                  from_cn_id: fid,
                  to_cn_id: tid,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)
    model1 = %Model{size: 50, plain_model: "sample_plain_model"}

    # 受け渡し
    :ok = Channel.recv_model_at_channel(fid, tid, model1, 10)
    %Channel.State{queue: queue, model_sum_size: model_sum_size} = Channel.get_state(fid, tid)
    received_queue = {[model1], []}

    assert queue == received_queue
    assert model_sum_size == model1.size

    :ok = Channel.send_model_from_channel(fid, tid, 20)

    %ComputeNode.State{receive_model_list: recv_model} = ComputeNode.get_state(20)
    assert recv_model == []

    %Channel.State{queue: queue, model_sum_size: model_sum_size} = Channel.get_state(fid, tid)
    empty_queue =  {[], []}
    assert queue == empty_queue
    assert model_sum_size == 0

    GenServer.stop(Utils.get_process_name(ComputeNode, 10), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 20), :normal, :infinity)
  end

  test "should receive model with proper order" do
    # ComputeNode の初期化
    cn_setup(10)
    cn_setup(20)

    # JobController の初期化
    JobController.start_link(
      %{job_controller_id: 0,
      init_event_queue: EventQueue.init_queue})

    # 受け取り側の availability を trueにする

    ComputeNode.become_available(20)

    # Channelの初期設定
    # TODO: 関数化して切り出す（channel_testの中の共通部分も）

    input_qos = %Channel.QoS{bandwidth: 100,
                      packetloss: 0,
                      capacity: 100}
    fid = 10
    tid = 20
    init_args = %Channel.ChannelArgs{
                  from_cn_id: fid,
                  to_cn_id: tid,
                  QoS: input_qos}

    {:ok, _channel_pid} = Channel.start_link(init_args)
    model1 = %Model{size: 50, plain_model: "sample_plain_model1"}
    model2 = %Model{size: 40, plain_model: "sample_plain_model2"}

    # 受け渡し
    Channel.recv_model_at_channel(fid, tid, model1, 10)
    Channel.recv_model_at_channel(fid, tid, model2, 20)
    %Channel.State{queue: queue, model_sum_size: model_sum_size} = Channel.get_state(fid, tid)
    received_queue = {[model2], [model1]} # model1 が先頭

    assert queue == received_queue
    assert model_sum_size == model1.size + model2.size

    # model1 の送受信

    :ok = Channel.send_model_from_channel(fid, tid, 30)
    %ComputeNode.State{receive_model_list: recv_model} = ComputeNode.get_state(20)
    assert recv_model == [model1.plain_model]

    %Channel.State{queue: queue, model_sum_size: model_sum_size} = Channel.get_state(fid, tid)
    one_queue =  {[], [model2]}
    assert queue == one_queue
    assert model_sum_size == model2.size

    # model2 の送受信

    :ok = Channel.send_model_from_channel(fid, tid, 40)
    %ComputeNode.State{receive_model_list: recv_model} = ComputeNode.get_state(20)
    assert recv_model == [model1.plain_model, model2.plain_model]

    %Channel.State{queue: queue, model_sum_size: model_sum_size} = Channel.get_state(fid, tid)
    empty_queue =  {[], []}
    assert queue == empty_queue
    assert model_sum_size == 0

    GenServer.stop(Utils.get_process_name(ComputeNode, 10), :normal, :infinity)
    GenServer.stop(Utils.get_process_name(ComputeNode, 20), :normal, :infinity)
  end

  test "should receive model from ComputeNode to ComputeNode" do
  # TODO:
  end

end
