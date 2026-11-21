require 'minitest/autorun'

module SmileTools
  def self.regex_path_in_plugin(*_args)
    /smile_helpers_queries/
  end

  def self.trace_by_line(*_args)
  end
end

class Query
  class << self
    attr_accessor :available_hooks, :selected_hooks

    def column_label_and_order_hook(_query, column)
      available_hooks.fetch(column.name, [nil, nil])
    end

    def column_label_hook(_query, column)
      selected_hooks[column.name]
    end
  end
end

require_relative '../lib/helpers/smile_helpers_queries'

Column = Struct.new(:name)
QueryDouble = Struct.new(:available_inline_columns)

class NativeQueriesHelper
  def query_available_inline_columns_options(_query)
    [['Native beta', :beta], ['Decorated alpha', :alpha], ['Native gamma', :gamma], ['External', :external]]
  end

  def query_selected_inline_columns_options(_query)
    [['Decorated alpha', :alpha], ['Native beta', :beta]]
  end
end

NativeQueriesHelper.prepend(Smile::Helpers::QueriesOverride::Hooks)

class SmileHelpersQueriesCooperationTest < Minitest::Test
  def setup
    Query.available_hooks = {}
    Query.selected_hooks = {}
    @query = QueryDouble.new([Column.new(:alpha), Column.new(:beta), Column.new(:gamma)])
    @helper = NativeQueriesHelper.new
  end

  def test_preserves_labels_returned_by_super_without_smile_hooks
    assert_equal(
      [['Native beta', :beta], ['Decorated alpha', :alpha], ['Native gamma', :gamma]],
      @helper.query_available_inline_columns_options(@query).reject {|_label, name| name == :external}
    )
    assert_includes(
      @helper.query_available_inline_columns_options(@query),
      ['External', :external]
    )
    assert_equal(
      [['Decorated alpha', :alpha], ['Native beta', :beta]],
      @helper.query_selected_inline_columns_options(@query)
    )
  end

  def test_applies_smile_labels_and_order_after_super
    Query.available_hooks = {
      :alpha => [20, 'Smile alpha'],
      :beta => [10, 'Smile beta']
    }
    Query.selected_hooks = {:beta => 'Selected beta'}

    assert_equal(
      [['Native gamma', :gamma], ['External', :external], ['Smile beta', :beta], ['Smile alpha', :alpha]],
      @helper.query_available_inline_columns_options(@query)
    )
    assert_equal(
      [['Decorated alpha', :alpha], ['Selected beta', :beta]],
      @helper.query_selected_inline_columns_options(@query)
    )
  end

  def test_allows_a_later_plugin_to_remain_in_the_super_chain
    decorator = Module.new do
      def query_selected_inline_columns_options(query)
        super.collect {|label, name| ["Later #{label}", name]}
      end
    end
    helper_class = Class.new(NativeQueriesHelper)
    helper_class.prepend(decorator)

    assert_equal(
      [['Later Decorated alpha', :alpha], ['Later Native beta', :beta]],
      helper_class.new.query_selected_inline_columns_options(@query)
    )
  end
end
