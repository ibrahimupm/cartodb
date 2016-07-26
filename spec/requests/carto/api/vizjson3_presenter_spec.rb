require 'spec_helper_min'
require 'mock_redis'

describe Carto::Api::VizJSON3Presenter do
  include Carto::Factories::Visualizations
  include_context 'visualization creation helpers'

  before(:all) do
    @user_1 = FactoryGirl.create(:carto_user, private_tables_enabled: false)
  end

  after(:all) do
    @user_1.destroy
  end

  let(:redis_mock) do
    MockRedis.new
  end

  shared_context 'full visualization' do
    before(:all) do
      @map, @table, @table_visualization, @visualization = create_full_visualization(Carto::User.find(@user_1.id))
    end

    after(:all) do
      destroy_full_visualization(@map, @table, @table_visualization, @visualization)
    end

    let(:viewer_user) { @visualization.user }
  end

  describe 'caching' do
    include_context 'full visualization'

    let(:fake_vizjson) { { fake: 'sure!', layers: [] } }

    it 'to_vizjson uses the redis vizjson cache' do
      cache_mock = mock
      cache_mock.expects(:cached).with(@visualization.id, false, 3).twice.returns(fake_vizjson)
      presenter = Carto::Api::VizJSON3Presenter.new(@visualization, cache_mock)
      v1 = presenter.to_vizjson
      v2 = presenter.to_vizjson
      v1.should eq fake_vizjson
      v1.should eq v2
    end

    it 'every call to_vizjson uses calculate_vizjson if no cache is provided' do
      presenter = Carto::Api::VizJSON3Presenter.new(@visualization, nil)
      presenter.expects(:calculate_vizjson).twice.returns(fake_vizjson)
      presenter.to_vizjson
      presenter.to_vizjson
    end

    it 'to_vizjson is not overriden by v2 caching or to_named_map_vizjson' do
      v2_presenter = Carto::Api::VizJSONPresenter.new(@visualization, $tables_metadata)
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization)

      v2_vizjson = v2_presenter.to_vizjson
      v3_vizjson = v3_presenter.to_vizjson
      v3n_vizjson = v3_presenter.to_named_map_vizjson

      v3_vizjson.should_not eq v2_vizjson
      v2_vizjson[:version].should eq '0.1.0'
      v3_vizjson[:version].should eq '3.0.0'
      v3n_vizjson[:version].should eq '3.0.0'
    end

    it 'to_vizjson does not override v2 caching or named map vizjson' do
      v2_presenter = Carto::Api::VizJSONPresenter.new(@visualization, $tables_metadata)
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization)

      v3_vizjson = v3_presenter.to_vizjson
      v2_vizjson = v2_presenter.to_vizjson
      v3n_vizjson = v3_presenter.to_named_map_vizjson

      v2_vizjson.should_not eq v3_vizjson
      v3n_vizjson.should_not eq v3_vizjson
      v2_vizjson[:version].should eq '0.1.0'
      v3_vizjson[:version].should eq '3.0.0'
      v3n_vizjson[:version].should eq '3.0.0'
    end

    it 'to_vizjson does not cache vector' do
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization)
      vizjson_a = v3_presenter.to_vizjson(vector: true)
      vizjson_b = v3_presenter.to_vizjson(vector: false)
      vizjson_a[:vector].should eq true
      vizjson_b[:vector].should eq false
    end

    it 'to_named_map_vizjson uses the redis vizjson cache' do
      fake_vizjson = { fake: 'sure!', layers: [] }

      cache_mock = mock
      cache_mock.expects(:cached).with(@visualization.id, false, anything).returns(fake_vizjson).twice
      presenter = Carto::Api::VizJSON3Presenter.new(@visualization, cache_mock)
      v1 = presenter.to_named_map_vizjson
      v2 = presenter.to_named_map_vizjson
      v1.should eq fake_vizjson
      v1.should eq v2
    end

    it 'to_named_map_vizjson does not cache vector' do
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization)
      vizjson_a = v3_presenter.to_named_map_vizjson(vector: true)
      vizjson_b = v3_presenter.to_named_map_vizjson(vector: false)
      vizjson_a[:vector].should eq true
      vizjson_b[:vector].should eq false
    end
  end

  describe '#to_named_map_vizjson' do
    include_context 'full visualization'

    it 'generates the vizjson of visualizations that have not named map as if they had' do
      @table.privacy = Carto::UserTable::PRIVACY_PUBLIC
      @table.save
      @visualization = Carto::Visualization.find(@visualization.id)
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization, nil)

      original_vizjson = v3_presenter.to_vizjson.reject { |k, _| k == :updated_at }
      original_named_vizjson = v3_presenter.to_named_map_vizjson.reject { |k, _| k == :updated_at }
      original_vizjson.should_not eq original_named_vizjson

      @table.privacy = Carto::UserTable::PRIVACY_PRIVATE
      @table.save
      @visualization = Carto::Visualization.find(@visualization.id)
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization, nil)

      named_vizjson = v3_presenter.to_vizjson.reject { |k, _| k == :updated_at }
      original_named_vizjson.should eq named_vizjson
      named_named_vizjson = v3_presenter.to_vizjson.reject { |k, _| k == :updated_at }
      named_named_vizjson.should eq named_vizjson
    end

    it 'includes analyses information without including sources parameters' do
      analysis = FactoryGirl.create(:analysis_with_source, visualization: @visualization, user: @user_1)
      analysis.analysis_definition[:params].should_not be_nil
      @visualization.reload
      v3_presenter = Carto::Api::VizJSON3Presenter.new(@visualization, nil)
      named_vizjson = v3_presenter.to_vizjson
      analyses_json = named_vizjson[:analyses]
      analyses_json.should_not be_nil
      source_analysis_definition = analyses_json[0][:params][:source]
      source_analysis_definition[:type].should eq 'source'
      source_analysis_definition[:params].should be_nil
    end

    it 'includes source at layers options' do
      source = 'a1'
      layer = @visualization.data_layers.first
      layer.options['source'] = source
      layer.save
      @table.privacy = Carto::UserTable::PRIVACY_PRIVATE
      @table.save
      @visualization.reload

      v3_vizjson = Carto::Api::VizJSON3Presenter.new(@visualization, viewer_user).send :calculate_vizjson
      v3_vizjson[:layers][1][:options][:source].should eq source
    end
  end

  describe 'analyses' do
    include_context 'full visualization'

    it 'sends `source` at layer options instead of sql if source is set for named maps' do
      query = "select * from #{@table.name}"

      layer = @visualization.data_layers.first
      layer.options['source'].should eq nil
      layer.options['query'] = query
      layer.save

      # INFO: send :calculate_vizjson won't use cache
      v2_vizjson = Carto::Api::VizJSONPresenter.new(@visualization, $tables_metadata).send(:calculate_vizjson)
      nm_vizjson = Carto::Api::VizJSONPresenter.new(@visualization, $tables_metadata).send(:calculate_vizjson, for_named_map: true)
      v3_vizjson = Carto::Api::VizJSON3Presenter.new(@visualization, viewer_user).send(:calculate_vizjson)

      v2_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:sql].should eq query
      v2_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:source].should be_nil
      nm_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:sql].should eq query
      nm_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:source].should be_nil
      v3_vizjson[:layers][1][:options][:sql].should eq query
      v3_vizjson[:layers][1][:options][:source].should be_nil

      source = 'a1'
      layer.options['source'] = source
      layer.save
      @visualization.reload

      v2_vizjson = Carto::Api::VizJSONPresenter.new(@visualization, $tables_metadata).send(:calculate_vizjson)
      nm_vizjson = Carto::Api::VizJSONPresenter.new(@visualization, $tables_metadata).send(:calculate_vizjson, for_named_map: true)
      v3_vizjson = Carto::Api::VizJSON3Presenter.new(@visualization, viewer_user).send(:calculate_vizjson)

      v2_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:sql].should eq query
      v2_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:source].should be_nil
      nm_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:sql].should be_nil
      nm_vizjson[:layers][1][:options][:layer_definition][:layers][0][:options][:source].should eq(id: source)
      v3_vizjson[:layers][1][:options][:sql].should be_nil
      v3_vizjson[:layers][1][:options][:source].should eq source
    end
  end

  describe 'anonyous_vizjson' do
    include_context 'full visualization'

    it 'v3 should include sql_wrap' do
      v3_vizjson = Carto::Api::VizJSON3Presenter.new(@visualization, viewer_user).send :calculate_vizjson
      v3_vizjson[:layers][1][:options][:sql_wrap].should eq "select * from (<%= sql %>) __wrap"
    end
  end

  describe 'layers' do
    include_context 'full visualization'

    before(:all) do
      @data_layer = @map.data_layers.first
      @data_layer.options[:attribution] = 'CARTO attribution'
      @data_layer.save

      @torque_layer = FactoryGirl.create(:carto_layer, kind: 'torque', maps: [@map])
      @torque_layer.options[:attribution] = 'CARTO attribution'
      @torque_layer.options[:query] = 'select * from wadus'
      @torque_layer.save
    end

    shared_examples 'common layer checks' do
      it 'should not include layergroup layers' do
        vizjson[:layers].map { |l| l[:type] }.should_not include 'layergroup'
      end

      it 'should not include namedmap layers' do
        vizjson[:layers].map { |l| l[:type] }.should_not include 'namedmap'
      end

      it 'should have exactly three layers: tiled, CartoDB and torque' do
        vizjson[:layers].map { |l| l[:type] }.should eq %w(tiled CartoDB torque)
      end

      it 'should include attribution for all layers' do
        vizjson[:layers].each { |l| l[:options].should include :attribution }
      end

      it 'should not include named map options in any layers' do
        vizjson[:layers].each do |l|
          options = l[:options]
          options.should_not include :stat_tag
          options.should_not include :maps_api_template
          options.should_not include :sql_api_template
          options.should_not include :named_map
        end
      end
    end

    describe 'in namedmap vizjson' do
      let(:vizjson) do
        Carto::Api::VizJSON3Presenter.new(@visualization, viewer_user)
                                     .send(:calculate_vizjson, forced_privacy_version: :force_named)
      end

      include_examples 'common layer checks'

      it 'should not include sql nor cartocss fields in data layers' do
        data_layer_options = vizjson[:layers][1][:options]
        data_layer_options.should_not include :sql
        data_layer_options.should_not include :cartocss
        data_layer_options.should_not include :cartocss_version
      end
    end

    describe 'in anonymous vizjson' do
      let(:vizjson) do
        Carto::Api::VizJSON3Presenter.new(@visualization, viewer_user)
                                     .send(:calculate_vizjson, forced_privacy_version: :force_anonymous)
      end

      include_examples 'common layer checks'

      it 'should include sql and cartocss fields in data layers' do
        data_layer_options = vizjson[:layers][1][:options]
        data_layer_options.should include :sql
        data_layer_options.should include :cartocss
        data_layer_options.should include :cartocss_version
      end
    end
  end
end
