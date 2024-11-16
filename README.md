# MiniD3fl[Work in Progress]

MiniD3flは、非中央集権型連合学習のシミュレーションを行うElixirベースのプロジェクトです。このプロジェクトは現在進行中です。

## 概要

MiniD3flは、以下の４つの観点を満たす非中央集権型連合学習のシミュレーターです。：

- スケーラビリティ（クライアント数）
- 通信品質の反映（帯域幅、パケットロスなど）
- クライアントの可用性
- 非同期な学習

## TODO
コード内に'#TODO'と書かれている部分を参照のこと。

- [ ] **レイテンシを正確に反映する**：モデルの転送が途中の場合の数値を考慮する（channel.exの:recv_model_at_channelにて）
- [ ] **訓練部分の追加**
- [ ] **Supervised Treeの追加**
- [ ] **テストの整備**：JobExecutorTestのさらなる追記。イベントの時系列と内部状態の正しさのテストを追加（出力から確認済みではある。）

### バグ修正

- （動作検証段階であり、今後追加予定）

## インストール

このプロジェクトをローカルにインストールするには、以下の手順に従ってください：

1. **リポジトリをクローン**：

   ```bash
   git clone https://github.com/your_username/mini_d3fl.git
   cd mini_d3fl

  
2. **Elixirなどのインストール**
    - install [elixir](https://elixir-lang.org/install.html)
    - ```bash
      mix deps.get
      ```

3. **Run the Simulator Sample [WIP]:**
   - ```bash
      mix test test/mini_d3fl/job_executor_test.exs
      ```
   