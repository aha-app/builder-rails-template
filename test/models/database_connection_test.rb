require "test_helper"

class DatabaseConnectionTest < ActiveSupport::TestCase
  test "SELECT 1 works" do
    value = ActiveRecord::Base.connection.select_value("SELECT 1")
    assert_equal 1, value.to_i, "Expected basic SELECT to return 1, got #{value.inspect}"
  end
end
