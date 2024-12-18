defmodule MiniD3fl.ComputeNode.AiCore.MnistTest do
  use ExUnit.Case
  use MiniD3fl.Aliases

  @tag timeout: :infinity
  test "should transform images and labels" do
    batch_size = 32
    {images, labels} = Scidata.CIFAR10.download()
    {all_local_images, global_test_images} = Cifar10.transform_images(images)
    {all_local_labels, global_test_labels} = Cifar10.transform_labels(labels)
    IO.inspect all_local_images
  end

  @tag timeout: :infinity
  test "should download data" do
    Cifar10.data_download(:cifar10, 2, 0.3)
  end

  @tag timeout: :infinity
  test "should make suffled & batched tensors" do
    client_id = 1
    %DataLoader.MlData{
      locals_train: locals_train,
      locals_valid: locals_valid,
      global_test: global_test} = Cifar10.data_download(:cifar10, 2, 0.3)

    local_train= Enum.at(locals_train, client_id-1)
    local_valid = Enum.at(locals_valid, client_id-1)

    trains = Cifar10.shuffle_batch_lists_to_tensors(local_train)
    valids = Cifar10.shuffle_batch_lists_to_tensors(local_valid)

    assert Nx.is_tensor(trains)
    assert Nx.is_tensor(valids)
  end

end
