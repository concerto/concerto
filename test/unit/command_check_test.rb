require 'test_helper'

# these are not reported in the simplecov report as covered
class CommandCheckTest < ActiveSupport::TestCase
  test 'which should find ruby' do
    assert which('ruby').present?
  end

  test 'command? should find ruby' do
    assert command?('ruby')
  end

  test 'command? should not find bogus file' do
    assert_not command?('completelybogusfile123')
  end

  test 'system should have mysql' do
    assert system_has_mysql? && mysql_location.present?
  end

  test 'system should have postgres' do
    assert system_has_postgres? && postgres_location.present?
  end
end
