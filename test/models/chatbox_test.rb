require 'test_helper'

class ChatboxTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "the_truth" do
    assert true
  end

  test "failing_test" do
    assert_not true, "This test should fail"
  end

  # assert's need to evaluate to true
  # if assert_not is true, then the test will fail.

  test 'should report error' do 
    some_undefined_variable
    assert true
  end

  # 'E' denotes an error* in the test
  # 'F' denotes a failure.
  # we can entire backtrace using when running test -b
  # assert_raises (NameError) do
  # some undefined variable
  # end
  # to catch an error.

  # look at doc for all different types or assertions for your needs..
  
  # we can run rails test to run all tests
  # or we can do rails test file_name.rb
  # you can test a specific test by doing 
  # rails test -n test_name

  # you can run a directory test/controllers
  # you can test a line test/models/chatbox_test.rb:5

end
