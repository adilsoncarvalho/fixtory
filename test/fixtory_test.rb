require 'test_helper'

describe 'Fixtories' do
  after do
    Fixtory.instance_variable_set(:@identity_map, {})
  end

  it 'allows access to specific rows from builder' do
    path = File.expand_path('test/fixtories/test_1.rb')
    builder = Fixtory::DSL.build_from(path)
    builder._insert

    assert_equal builder.owners.brian.age, 35
  end

  it 'instantiates model when retrieved' do
    path = File.expand_path('test/fixtories/test_1.rb')
    builder = Fixtory::DSL.build_from(path)
    builder._insert

    assert_instance_of Owner, builder.owners.brian
  end

  it 'allows relationships to be set' do
    path = File.expand_path('test/fixtories/test_1.rb')
    builder = Fixtory::DSL.build_from(path)
    builder._insert

    assert_equal builder.owners.brian, builder.dogs.boomer.owner
  end

  it 'allows relationships to be set from parent' do
    path = File.expand_path('test/fixtories/test_2.rb')
    builder = Fixtory::DSL.build_from(path)
    builder._insert

    assert_equal [builder.dogs.boomer], builder.owners.brian.dogs
  end

  it 'allows has one relationship' do
    path = File.expand_path('test/fixtories/test_3.rb')
    builder = Fixtory::DSL.build_from(path)
    builder._insert

    assert_equal builder.books.moby_dick, builder.owners.brian.book
  end

  it 'provides a "fixtory" method to access a group' do
    test_group = fixtory(:test_1)
    assert Fixtory::DSL::Builder === test_group
  end

  it '_inserts into the database' do
    count = Owner.count

    fixtory(:test_1)

    refute_equal Owner.count, count
  end

  it 'supports STI' do
    test_group = fixtory(:test_4)
    snoopy = test_group.beagles.snoopy
    marmaduke = test_group.great_danes.marmaduke

    assert_equal snoopy.type, 'Beagle'
    assert_equal marmaduke.type, 'GreatDane'
    [snoopy, marmaduke].each do |dog|
      assert_includes test_group.owners.brian.dogs, dog
    end
  end

  it 'caches data for future use rather than reading from disk twice' do
    build_from = Fixtory::DSL.method(:build_from)

    stub Fixtory::DSL, :build_from, build_from, Fixtory.path_for(:test_1) do
      fixtory(:test_1)
      fixtory(:test_1)
    end

    refute_called Fixtory::DSL, :build_from, 2
  end
end
