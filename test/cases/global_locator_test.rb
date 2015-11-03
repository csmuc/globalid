require 'helper'

class GlobalLocatorTest < ActiveSupport::TestCase
  setup do
    model = Person.new('id')
    @gid  = model.to_gid
  end

  test 'by GID' do
    found = PreGlobalID::Locator.locate(@gid)
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test 'by GID with only: restriction with match' do
    found = PreGlobalID::Locator.locate(@gid, only: Person)
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test 'by GID with only: restriction with match subclass' do
    instance = Person::Child.new
    gid = instance.to_gid
    found = PreGlobalID::Locator.locate(gid, only: Person)
    assert_kind_of gid.model_class, found
    assert_equal gid.model_id, found.id
  end

  test 'by GID with only: restriction with no match' do
    found = PreGlobalID::Locator.locate(@gid, only: String)
    assert_nil found
  end

  test 'by GID with only: restriction by multiple types' do
    found = PreGlobalID::Locator.locate(@gid, only: [String, Person])
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test 'by GID with only: restriction by module' do
    found = PreGlobalID::Locator.locate(@gid, only: PreGlobalID::Identification)
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test 'by GID with only: restriction by module no match' do
    found = PreGlobalID::Locator.locate(@gid, only: Forwardable)
    assert_nil found
  end

  test 'by GID with only: restriction by multiple types w/module' do
    found = PreGlobalID::Locator.locate(@gid, only: [String, PreGlobalID::Identification])
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test 'by many GIDs of one class' do
    assert_equal [ Person.new('1'), Person.new('2') ],
      PreGlobalID::Locator.locate_many([ Person.new('1').to_gid, Person.new('2').to_gid ])
  end

  test 'by many GIDs of mixed classes' do
    assert_equal [ Person.new('1'), Person::Child.new('1'), Person.new('2') ],
      PreGlobalID::Locator.locate_many([ Person.new('1').to_gid, Person::Child.new('1').to_gid, Person.new('2').to_gid ])
  end

  test 'by many GIDs with only: restriction to match subclass' do
    assert_equal [ Person::Child.new('1') ],
      PreGlobalID::Locator.locate_many([ Person.new('1').to_gid, Person::Child.new('1').to_gid, Person.new('2').to_gid ], only: Person::Child)
  end

  test 'by to_param encoding' do
    found = PreGlobalID::Locator.locate(@gid.to_param)
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test 'by non-GID returns nil' do
    assert_nil PreGlobalID::Locator.locate 'This is not a GID'
  end

  test 'by invalid GID URI returns nil' do
    assert_nil PreGlobalID::Locator.locate 'http://app/Person/1'
    assert_nil PreGlobalID::Locator.locate 'gid://Person/1'
    assert_nil PreGlobalID::Locator.locate 'gid://app/Person'
    assert_nil PreGlobalID::Locator.locate 'gid://app/Person/1/2'
  end

  test 'use locator with block' do
    PreGlobalID::Locator.use :foo do |gid|
      :foo
    end

    with_app 'foo' do
      assert_equal :foo, PreGlobalID::Locator.locate('gid://foo/Person/1')
    end
  end

  test 'use locator with class' do
    class BarLocator
      def locate(gid); :bar; end
      def locate_many(gids, options = {}); gids.map(&:model_id); end
    end

    PreGlobalID::Locator.use :bar, BarLocator.new

    with_app 'bar' do
      assert_equal :bar, PreGlobalID::Locator.locate('gid://bar/Person/1')
      assert_equal ['1', '2'], PreGlobalID::Locator.locate_many(['gid://bar/Person/1', 'gid://bar/Person/2'])
    end
  end

  test 'app locator is case insensitive' do
    PreGlobalID::Locator.use :insensitive do |gid|
      :insensitive
    end

    with_app 'insensitive' do
      assert_equal :insensitive, PreGlobalID::Locator.locate('gid://InSeNsItIvE/Person/1')
    end
  end

  test 'locator name cannot have underscore' do
    assert_raises ArgumentError do
      PreGlobalID::Locator.use('under_score') { |gid| 'will never be found' }
    end
  end

  test "by valid purpose returns right model" do
    instance = Person.new
    login_gid = instance.to_global_id(for: 'login')

    found = PreGlobalID::Locator.locate(login_gid.to_s, for: 'login')
    assert_kind_of login_gid.model_class, found
    assert_equal login_gid.model_id, found.id
  end

  test "by many with one record missing leading to a raise" do
    assert_raises RuntimeError do
      PreGlobalID::Locator.locate_many([ Person.new('1').to_gid, Person.new(Person::HARDCODED_ID_FOR_MISSING_PERSON).to_gid ])
    end
  end

  test "by many with one record missing not leading to a raise when ignoring missing" do
    assert_nothing_raised do
      PreGlobalID::Locator.locate_many([ Person.new('1').to_gid, Person.new(Person::HARDCODED_ID_FOR_MISSING_PERSON).to_gid ], ignore_missing: true)
    end
  end

  private
    def with_app(app)
      old_app, PreGlobalID.app = PreGlobalID.app, app
      yield
    ensure
      PreGlobalID.app = old_app
    end
end

class ScopedRecordLocatingTest < ActiveSupport::TestCase
  setup do
    @gid = Person::Scoped.new('1').to_gid
  end

  test "by GID with scoped record" do
    found = PreGlobalID::Locator.locate(@gid)
    assert_kind_of @gid.model_class, found
    assert_equal @gid.model_id, found.id
  end

  test "by many with scoped records" do
    assert_equal [ Person::Scoped.new('1'), Person::Scoped.new('2') ],
      PreGlobalID::Locator.locate_many([ Person::Scoped.new('1').to_gid, Person::Scoped.new('2').to_gid ])
  end
end
